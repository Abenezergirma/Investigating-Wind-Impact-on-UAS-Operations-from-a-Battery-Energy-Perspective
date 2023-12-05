""" This script performs a state estimation and prediction for TarotT18 battery. The battery model is electrochemical based  

"""
# Import packages
import pickle
import argparse
import time
import numpy as np
from numpy import diag
import matplotlib
import matplotlib.pyplot as plt
import sys 
matplotlib.use("Qt5Agg")
# Set default options
# ====================
matplotlib.rcParams["figure.figsize"] = [10.0, 14.0]
matplotlib.rcParams["axes.labelsize"] = "small"
matplotlib.rcParams["xtick.labelsize"] = "x-small"
matplotlib.rcParams["ytick.labelsize"] = "x-small"
# ====================

# Import necessary packages -- battery model, UKF estimator, and predictor
from prog_algs.state_estimators import UnscentedKalmanFilter
from prog_algs.uncertain_data import MultivariateNormalDist
from prog_algs import predictors
from prog_algs.metrics import prob_success
from battery_electrochem_TarotT18 import BatteryElectroChemEOD as Battery

# Step 1: Setup model and future loading
# future loading

# simulate the aircraft and collect the current requirement of the mission
def current_requirement(collect_current):
    # if collect_current == True:
    # simul.simulate_aircraft()
    sample_time = 0.1
    # Iapp = np.loadtxt("Iapp_long_traj") #longer trajectory - without wind
    # Iapp = np.loadtxt("Iapp_withoutwind") #shorter trajectory - without wind
    # Iapp = np.loadtxt("./Plots and Results/current_inputs/Iapp_long_trajectory") # Actual trajectory - Flight 1
    Iapp = np.loadtxt("current_matlab_high_wind_3_.txt")
    
    time = np.arange(0, len(Iapp) * sample_time, sample_time)
    time = np.round(time, 3)
    loading = dict(zip(time, Iapp))
    return loading


# function to save the simulation object as pickle
def save_object(obj, filename):
    with open(filename, "wb") as outp:  # Overwrites any existing file.
        pickle.dump(obj, outp, pickle.HIGHEST_PROTOCOL)


def tarrot_loading(t, x={}):

    sample_time = 0.1

    if t < (len(loading) * sample_time):

        # i = loading[round(t, 3)]
        Iapp = np.loadtxt("current_matlab_high_wind_3_.txt")
        k = int(t*10)
        i = Iapp[k]
        


    else:
        i = 500
    return {"i": i}


def initialize_battery():

    # Add Process and Measurement noises
    R_vars = {"t": 12.2, "v": 15.46}
    batt = Battery(measurement_noise=R_vars)
    initial_state = batt.parameters["x0"]

    batt.parameters["VEOD"] = args.VEOD  # put the user defined VEOD here

    print(batt.parameters["VEOD"])

    print("initial state", initial_state)

    INITIAL_UNCERT = 30#0.05  # Uncertainty in initial state (%)
    # Construct covariance matrix (making sure each value is positive)
    cov = diag(
        [max(abs(INITIAL_UNCERT * value), 1e-3) for value in initial_state.values()]
    )
    initial_state = MultivariateNormalDist(
        initial_state.keys(), initial_state.values(), cov
    )
    return batt, initial_state


# Step 2: Demonstrating state estimator
# Step 2a: Setup
def run_estimator(batt, initial_state):

    print("\nPerforming State Estimation Step")
    filt = UnscentedKalmanFilter(batt, initial_state)

    # Step 2b: Print & Plot Prior State
    print("\nPrior State:", filt.x.mean)
    print("\tSOC: ", batt.event_state(filt.x.mean)["EOD"])
    # fig = filt.x.plot_scatter(label="prior")

    # Step 2c: Perform state estimation step
    example_measurements = {"t": 292.2, "v": 25}
    t = 0.1
    print("Current of batt = ", tarrot_loading(t))
    filt.estimate(t, tarrot_loading(t), example_measurements)

    # Step 2d: Print and Plot Resulting Posterior State
    print("\nPosterior State:", filt.x.mean)
    print("\tSOC: ", batt.event_state(filt.x.mean)["EOD"])
    # filt.x.plot_scatter(
    #     fig=fig, label="posterior"
    # )  # Add posterior state to figure from prior state

    # Note: in a prognostic application the above state estimation step would be repeated each time
    #  there is new data. Here we're doing one step to demonstrate how the state estimator is used
    return filt


# filt = run_estimator()


def run_predictor(batt, filt):

    # Step 3: Demonstrating Predictor
    print("\n\nPerforming Prediction Step")

    if args.predictor == "MC":
        # Step 3a: Setup Predictor
        mc = predictors.MonteCarlo(batt)
        # Step 3b: Perform a prediction
        NUM_SAMPLES = args.N
        STEP_SIZE = 0.2
        mc_results = mc.predict(
            filt.x, tarrot_loading, n_samples=NUM_SAMPLES, dt=STEP_SIZE,save_freq=1, events=['EOD']
        )

    elif args.predictor == "UT":
        STEP_SIZE = 0.2
        mc = predictors.UnscentedTransform(batt)
        mc_results = mc.predict(filt.x, tarrot_loading, dt=STEP_SIZE, save_freq=1, events=['EOD'])

    else:
        raise Exception("Unknown predictor algorithm")

    return mc_results


def analyze_results(mc_results):

    # Step 3c: Analyze the results

    # Note: The results of a sample-based prediction can be accessed by sample, e.g.,
    # states_sample_1 = mc_results.states[1]
    # now states_sample_1[n] corresponds to times[n] for the first sample

    # You can also access a state distribution at a specific time using the .snapshot function
    # states_time_1 = mc_results.states.snapshot(1)
    # now you have all the samples corresponding to times[1]

    # You can also access the final state (of type UncertainData), like so:
    final_state = mc_results.time_of_event.final_state

    time_EOD = mc_results.time_of_event.mean

    print("Final state @EOD: ", final_state["EOD"].mean)

    # You can also use the metrics package to generate some useful metrics on the result of a prediction
    print("\nEOD Prediction Metrics")

    print(
        "\tPortion between {} and {}: ".format(
            time_EOD["EOD"] * 0.95, time_EOD["EOD"] * 1.05
        ),
        mc_results.time_of_event.percentage_in_bounds(
            [time_EOD["EOD"] * 0.95, time_EOD["EOD"] * 1.05]
        ),
    )
    print(
        "\tAssuming ground truth {}: ".format(time_EOD["EOD"]),
        mc_results.time_of_event.metrics(ground_truth=time_EOD["EOD"]),
    )
    print(
        "\tP(Success) if mission ends at {}: ".format(time_EOD["EOD"]),
        prob_success(mc_results.time_of_event, time_EOD["EOD"]),
    )

    # Plot state transition
    """ 
    # Here we will plot the states at t0, 25% to ToE, 50% to ToE, 75% to ToE, and ToE
    fig = mc_results.states.snapshot(0).plot_scatter(
        label="t={} s".format(int(mc_results.times[0]))
    )  # 0
    quarter_index = int(len(mc_results.times) / 4)
    mc_results.states.snapshot(quarter_index).plot_scatter(
        fig=fig, label="t={} s".format(int(mc_results.times[quarter_index]))
    )  # 25%
    mc_results.states.snapshot(quarter_index * 2).plot_scatter(
        fig=fig, label="t={} s".format(int(mc_results.times[quarter_index * 2]))
    )  # 50%
    mc_results.states.snapshot(quarter_index * 3).plot_scatter(
        fig=fig, label="t={} s".format(int(mc_results.times[quarter_index * 3]))
    )  # 75%
    mc_results.states.snapshot(-1).plot_scatter(
        fig=fig, label="t={} s".format(int(mc_results.times[-1]))
    )  # 100%


    # Step 4: Show all plots
    plt.subplots_adjust(
        left=0.1, bottom=0.1, right=0.9, top=0.9, wspace=1.1, hspace=0.4
    )
     """
    mc_results.time_of_event.plot_hist()
    plt.show()
  


parser = argparse.ArgumentParser(
    description="Battery end-of-discharge prediction",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
)

# Generate configurations for the experiment
parser.add_argument("--VEOD", type=float, default=18, help="VEOD threshold value")

parser.add_argument(
    "--predictor", type=str, default="MC", help="Predictor algorithm (MC or UT)"
)

parser.add_argument("--N", type=int, default=5, help="Number of MC simulations")

parser.add_argument(
    "--collect_current",
    action="store_true",
    help="Run the vehicle model and collect the current requirement",
)

args = parser.parse_args()

loading = current_requirement(args.collect_current)

def main():
    
    batt, initial_state = initialize_battery()
    start = time.perf_counter()

    filt = run_estimator(batt, initial_state)

    mc_results = run_predictor(batt, filt)

    end = time.perf_counter()

    print("\tRuntime: {:4.2f}s".format(end - start))

    save_object(mc_results, "mc_results.pkl")

    analyze_results(mc_results)

    print("ToE", mc_results.time_of_event.mean)


if __name__ == "__main__":
    main()
