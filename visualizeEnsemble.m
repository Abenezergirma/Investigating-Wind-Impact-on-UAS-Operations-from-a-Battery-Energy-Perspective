% Define ensemble wind data (simplified for illustration)
wind_speed_percentiles = [5.2, 8.0, 10.5];  % 25th, 50th (median), 75th percentiles in m/s
wind_direction_percentiles = [180, 220, 270];  % 25th, 50th (median), 75th percentiles in degrees

% Create an array to store ensemble members
ensemble_size = 10;
ensemble_members_speed = zeros(ensemble_size, 1);
ensemble_members_direction = zeros(ensemble_size, 1);

% Generate 10 different ensemble members
for i = 1:ensemble_size
    ensemble_members_speed(i) = rand() * (wind_speed_percentiles(3) - wind_speed_percentiles(1)) + wind_speed_percentiles(1);
    ensemble_members_direction(i) = rand() * (wind_direction_percentiles(3) - wind_direction_percentiles(1)) + wind_direction_percentiles(1);
end

% Plot wind speed histograms for each member
figure;
for i = 1:ensemble_size
    subplot(ensemble_size, 2, 2 * i - 1);
    histogram(ensemble_members_speed(i), 'BinEdges', [0, 4, 6, 8, 10, 12], 'Normalization', 'probability');
    xlabel('Wind Speed (m/s)');
    ylabel('Probability');
    title(['Ensemble Member ', num2str(i), ' Wind Speed']);
    
    subplot(ensemble_size, 2, 2 * i);
    histogram(ensemble_members_direction(i), 'BinEdges', [0, 90, 180, 270, 360], 'Normalization', 'probability');
    xlabel('Wind Direction (degrees from True North)');
    ylabel('Probability');
    title(['Ensemble Member ', num2str(i), ' Wind Direction']);
end

% Adjust subplot layout
sgtitle('Ensemble Wind Forecasts');
