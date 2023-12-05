clear, clc;

% Fault scenarios (leave alone for nominal)
% To have complete motor failure of motor i, set i of this list to 0. 
% To have partial motor failure, set to the scaling factor.
% Ex: 0.75 is 25% failure.
motormult=[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0];

% To have saturation, set the motormult to 0.
% This will be added to the 
% Pick between 0 and 5500
saturationrpm=[0,0,0,0,0,0,0,0];

trajtype = 'nasa'; % loads in the 'NASA' trajectory. Use 'square' or 'triangle' if needed
turbenabled=1; % Whether you want turbulence from the Dryden model

% Wind speeds (m/s) (positive or negative)
windtype = 3; % 0-3
if windtype==0
    smallestwind=0;
    largestwind=0;
elseif windtype==1
    smallestwind=0;
    largestwind=5;
elseif windtype==2
    smallestwind=5;
    largestwind=10;
elseif windtype==3
    smallestwind=10;
    largestwind=15;
else
    error('Wind type not implemented!');
end

windx=smallestwind + (largestwind-smallestwind)*rand;
windy=smallestwind + (largestwind-smallestwind)*rand;
windz=0;
windx=0; 
windy=0;
windz=0;

% uncomment when wanting to include wind data in simulation
windx = load('xwind.csv');
windy = load('ywind.csv'); 
wind_time=0:5:(length(windx)-1)*5;

factor = 1.2;
simin_windx = timeseries(factor*windx, wind_time);
simin_windy = timeseries(factor*windy, wind_time);

% simin_windx = timeseries(windx,wind_time);
% simin_windy = timeseries(windy,wind_time);

% I recommend keeping this 3-5 m/s for now. That is all we have evaluated
% the model for
missionspeed = 5;

% disp(['Wind X: ', num2str(windx), ' Y: ', num2str(windy), ' m/s.'])

% load UAV parameters, map and trajectories
octomodel=load('params/TarotT18.mat').octomodel;
Motor=load('params/KDE4213XF-360_performancedata.mat').Motor;
battery=load('params/battery_Tattu.mat').battery;
windspecs=load('params/TarotT18_windspecs.mat').windspecs;
battery.sampleTime = 0.1;

if strcmp(trajtype, 'nasa')
    load missionplanner/waypoints1.mat ; 
    load missionplanner/waypointsorign1.mat ; 
    xyzENU = lla2enu(waypoints,waypointsorign,'flat');
    xyzref=xyzENU(2:end,:);
    xyzic=xyzENU(1,:);
    xyzic(3)=waypointsorign(3);
elseif strcmp(trajtype, 'square')
    load missionplanner/zeroorigin.mat ;
    load missionplanner/squareref.mat ; 
elseif strcmp(trajtype, 'triangle')
    load missionplanner/zeroorigin.mat ;
    load missionplanner/triangleref.mat ;
else
    error('Trajectory type not implemented');
end

% trajectory settings/ mission plan / initial conditions

% mission velocity cruise speed, desired and max
maxleashvelocity=missionspeed; % in m/s  SHOULD NOT BE LARGER THAN 7 M/S FOR NOW

save('missionplanner/xyzic.mat','xyzic');
save('missionplanner/xyzref.mat','xyzref');

%define initial conditions for the vehicle
IC= load('params/initialcond/IC_HoverAt30mOcto.mat').IC;
IC.X=xyzic(1);
IC.Y=xyzic(2);
IC.Z=xyzic(3);

% time required to complete the whole mission, currently using this for
% every waypoint, should refine for each waypoint
waypoints=xyzref(:,1:2);
totaldistancei = calculatedistance(waypoints);
timeinterval = calculatetime(totaldistancei,maxleashvelocity);
stoptimetotal=timeinterval(2)+0.25*timeinterval(2);

% time travel between waypoints
waypoints=xyzref;
nWayPoints = length(waypoints);

% Calculate the distance between waypoints
% currently unused, could be used to estimate max time to complete each
% waypoint trajectory
distance = zeros(1,nWayPoints);
for i = 2:nWayPoints
    distance(i) = norm(waypoints(i,1:3) - waypoints(i-1,1:3));
end

% trapezoidal velocity trajectory generator parameters
maxVelocity=missionspeed; % m/s
numsamples=100;

% simulate flight from waypoint to waypoint

% variables initialization
postraj=[];
alttraj=[];
veltraj=[];
atttraj=[];
rpmtraj=[];
refpostraj=[];
batvartraj=[];
trajerror=[]; % track trajectory error

prevwaypt=xyzic(1,1:2);

for waypts=1:length(xyzref)
    currentwaypt=xyzref(waypts,1:2);
    % read next waypoint
    xref=xyzref(waypts,1);
    yref=xyzref(waypts,2);
    zref=xyzref(waypts,3);

    % define trapezoidal velocity profile
    tempwayp=[IC.X,IC.Y;xyzref(waypts,1:2)]';
    [endTimes,peakVels] = ProfileForMaxVel(tempwayp,maxVelocity);
    [q, qd, qdd, tvec, pp] = trapveltraj(tempwayp, numsamples,EndTime=endTimes);
    velprofileX=qd(1,:)';
    velprofileY=qd(2,:)';
    scurvetimes=tvec';
    
    % simulate until reaching next waypoint
    try
        out=sim('dynamicsquat_2022a');
    catch exception
        disp('Simulation failure');
        disp(exception);
    end

    % obtain simulation data
    pos=state.Data(:,1:2);
    alt=state.Data(:,3);
    vel=state.Data(:,4:6);
    att=state.Data(:,7:9);
    rpm=motorsrpm.Data(:,1:8);
    refpos=refposition.Data(:,1:2);
    batvar=battery_data.Data(:,1:3);
    trajer=zeros(size(refpos, 1), 1);

    % Calculate trajectory tracking error at each timestep
    for i = 1:size(pos, 1)
        point_vector = pos(i, :) - prevwaypt;
        vector = currentwaypt - prevwaypt;
        cross_product = cross([vector, 0], [point_vector, 0]);
        trajer(i) = abs(cross_product(3)) / norm(vector);
    end

    prevwaypt=currentwaypt;

    % save variables
     postraj=[postraj;pos];
     alttraj=[alttraj;alt];
     veltraj=[veltraj;vel];
     atttraj=[atttraj;att];
     rpmtraj=[rpmtraj;rpm];
     refpostraj=[refpostraj;refpos];
     batvartraj=[batvartraj;batvar];
     trajerror=[trajerror;trajer];

    %reset initial conditions to start from last simulation step
    [IC,battery] = resetinitial(IC,battery,state.Data,battery_variables.Data);
end

%% visualization of results- can be commented for continuous simulation purposes

%create time vector
time=0:octomodel.sampletime:(length(postraj)-1)*octomodel.sampletime;
timeb=0:battery.sampleTime:(length(batvartraj)-1)*battery.sampleTime;

% Display time to complete
disp(['Time to complete: ', num2str(time(end))])

% obtain current results
totali=batvartraj(:,1);
voltage=batvartraj(:,2);
SOC=batvartraj(:,3);

% speeds
% figure16 = figure;
% hold on;
% plot(time,veltraj); 
% title('linear velocity')


% trajectory error
%     figure12 = figure;
%     hold on;
%     xerror=refpostraj(:,1)-postraj(:,1);
%     yerror=refpostraj(:,2)-postraj(:,2);
%     
%     plot(time,xerror);
%     plot(time,yerror);
%     title('X,Y error')

% motor angular velocity data
% figure13 = figure;
% plot(time,rpmtraj);  
% title('Motor rpm data')

% attitude
% figure17= figure;
% hold on;
% plot(time,atttraj); %roll,pitch,yaw
% title('roll, pitch, yaw')

% total current data


figure14 = figure;
hold on;
plot(timeb,totali); 
writematrix(totali,'current_matlab_high_wind_2.txt');
title('current consumption');   

% Get X and Y data
lineObj = findobj(gca, 'Type', 'Line'); % Find the Line object
xCurr = get(lineObj, 'XData');
yCurr = get(lineObj, 'YData');

% Save data to file
data = [xCurr; yCurr];
filename = 'current_data.csv';
% Update filepath with directory to repo
filepath = 'C:\Users\Tharun\GWU\Battery Summer Project\Battery-Summer-Project\Week 1\current_inputs\';
fullpath = fullfile(filepath, filename);
writematrix(data', fullpath, 'Delimiter', ',');


% % Voltage and State of charge change with time
% figure15 = figure;
% plot(timeb,voltage); 
% title('voltage')
% 
% % figure151 = figure;
% plot(timeb,SOC*100); 
% title('SOC')

% Voltage and State of charge change with time
figure15 = figure;
plot(timeb,voltage); 
title('voltage')
hold on
plot(timeb,SOC*100); 
title('SOC')

% Get X and Y data for both lines
lineObjs = findobj(gca, 'Type', 'Line'); % Find the Line objects
xData = cell(2,1);
yData = cell(2,1);
for i = 1:numel(lineObjs)
    xData{i} = get(lineObjs(i), 'XData');
    yData{i} = get(lineObjs(i), 'YData');
end

% Save data to file
data = [xData{1}; yData{1}; yData{2}];
filename = 'voltage_and_SOC_data.csv';
% Update filepath with directory to repo
filepath = 'C:\Users\Tharun\GWU\Battery Summer Project\Battery-Summer-Project\Week 1\current_inputs\';
fullpath = fullfile(filepath, filename);
writematrix(data', fullpath, 'Delimiter', ',');

% Display voltage data
disp(xData{1});

% Calculating metrics
% TODO: Add oscillation

completed = missionCompleted(postraj, currentwaypt);
disp(['Mission completed: ', num2str(completed)])

if ~completed
    ttf=time(end);
else
    ttf=nan;
end
disp(['Time to failure: ', num2str(ttf)]);
last_idx=size(postraj,1);
if ~isnan(ttf)
    last_idx=int32(ttf*100);
end

[mean_err,sum_err,max_err,median_err,std_err] = trajTrackingStats(trajerror, last_idx);
disp('Mean traj. tracking error:');
disp(mean_err);

disp('Sum tte');
disp(sum_err);

disp('Max tte');
disp(max_err);

disp('Median tte');
disp(median_err);

disp('Std tte');
disp(std_err);

% 2 D trajectory visualization
figure1 = figure;
hold on;
plot(refpostraj(:,1),refpostraj(:,2),'x');
plot(postraj(last_idx,1), postraj(last_idx,2), 'o');
plot(postraj(1:last_idx,1),postraj(1:last_idx,2));
title('trajectory');

% Exporting data points for trajectory WIP
% % 2D trajectory visualization
% figure1 = figure;
% hold on;
% scatter(refpostraj(:,1), refpostraj(:,2), 'x');
% scatter(postraj(last_idx,1), postraj(last_idx,2), 'o');
% xScatter = {postraj(1:last_idx,1)', NaN};
% yScatter = {postraj(1:last_idx,2)', NaN};
% xLine = [refpostraj(:,1)', NaN];
% yLine = [refpostraj(:,2)', NaN];
% data = [xScatter{:}; yScatter{:}; xLine; yLine];
% filename = 'trajectory_data.csv';
% % Update filepath with directory to repo
% filepath = 'C:\Users\Tharun\GWU\Battery Summer Project\Battery-Summer-Project\Week 1\current_inputs\';
% fullpath = fullfile(filepath, filename);
% writematrix(data', fullpath, 'Delimiter', ',');


% altitude
figure19 = figure;
hold on;
plot(time(1:last_idx), alttraj(1:last_idx));
title('Altitude')

% overall trajectory tracking error
figure14 = figure;
hold on;
plot(time(1:last_idx), trajerror(1:last_idx))
title('Trajectory Tracking Error')

toc = timeOutsideCorridor(trajerror, last_idx);
disp(['Total time outside corridor: ', num2str(toc)]);

num_crossings = numCrossCorridor(trajerror, last_idx);
% Display the number of crossings
disp(['Crossed corridor ', num2str(num_crossings), ' times.']);

jitter = calculateDisplacementVariance(postraj, last_idx);
disp(['Jitteriness: ', num2str(jitter)]);

if completed
    ttc = time(end);
else
    ttc = nan;
end 

function [mean_err,sum_err,max_err,median_err,std_err] = trajTrackingStats(err, last_idx)
    mean_err = mean(err(1:last_idx));
    sum_err = sum(err(1:last_idx));
    max_err = max(err(1:last_idx));
    median_err = median(err(1:last_idx));
    std_err = std(err(1:last_idx));
end

function completed = missionCompleted(postraj, finalwaypt)
    dist = norm(postraj(end, :) - finalwaypt);
    if dist <= 2.01
        completed = 1;
    else
        completed = 0;
    end
end

function toc = timeOutsideCorridor(trajerror, last_idx)
    err = trajerror(1:last_idx);
    outside_corridor = find(err > 2);
    toc = length(outside_corridor) * 0.01;
end

function crossings = numCrossCorridor(trajerror, last_idx)
    crossings = 0;
    
    for i = 1:length(trajerror(1:last_idx))-1
        if (trajerror(i) < 2 && trajerror(i+1) >= 2)
            crossings = crossings + 1;
        end
    end
end

% Need to revisit this
function jitteriness = calculateDisplacementVariance(postraj, last_idx)
    dx = diff(postraj(1:last_idx, 1));
    dy = diff(postraj(1:last_idx, 2));

    jitteriness=var([dx; dy]);
end