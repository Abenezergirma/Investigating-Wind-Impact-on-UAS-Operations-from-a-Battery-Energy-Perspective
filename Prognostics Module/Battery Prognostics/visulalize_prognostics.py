import pickle 
import numpy as np
import matplotlib.pyplot as plt
import collections
import pandas as pd
from scipy import stats
from scipy.stats import norm
from prog_algs.metrics import prob_success
from sklearn.preprocessing import normalize 
from pathlib import Path
import sys 
plt.rcParams['text.usetex'] = True
# sys.path.append('/home/abenezertaye/Desktop/Research/Codes/NASA/Battery Prognostics/Battery Prognostics/Plots and Results/')    
class VisualizePrognostics:
    def __init__(self, pickle_path) -> None:
        self.prog_results = self.load_pickle_file(pickle_path)
        self.prog_times = self.prog_results.times
        self.voltage_python = self.get_prog_voltage()
        self.soc_python = self.get_SOC()
        self.num_traces = None  
        self.sample_time = None 
        self.current_input = None 
        self.voltage_matlab = None 
        self.SOC_matlab = None 
    
    def load_pickle_file(self, pickle_path):
        with open (pickle_path, 'rb') as pickle_file:
            mc_results = pickle.load(pickle_file)
        return mc_results
    
    def get_prog_voltage(self):
        # Note follow the same procedure if you want to get temprature in the future
        voltage = []
        for sim in range(0, len(self.prog_results.outputs)):
            voltage.append([])
            for time in range(0, len(self.prog_results.outputs[sim])):
                voltage[sim].append(self.prog_results[sim][time]['v']) #<-- store voltage into an array
        return voltage
    
    def get_SOC(self):
        soc = []
        for i in range(0, len(self.prog_results.event_states)):
            soc.append([])
            for t in range(0, len(self.prog_times)-2):
                soc[i].append(self.prog_results.event_states[i][t]['EOD'])
        SOC = np.array(soc)
        return SOC
    
    def plot_soc_trajectories(self):
        time_stamp = int(len(self.current_input)*self.sample_time)
        for trace in range(0,self.num_traces):
            plt.plot(self.SOC[trace, 0:time_stamp], linewidth=1, color='black')
        plt.xlabel('time')
        plt.ylabel('SOC')
        plt.grid(True)
        plt.title('Battery SOC Curve')
        plt.show
          
            
        
        

