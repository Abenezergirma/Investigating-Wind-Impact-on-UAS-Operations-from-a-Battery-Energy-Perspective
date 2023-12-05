Usage
=====

.. _installation:

Installation
------------

1. Clone the repository to your local machine using the follwing command:

.. code-block::

    git clone https://github.com/Abenezergirma/Investigating-Wind-Impact-on-UAS-Operations-from-a-Battery-Energy-Perspective.git


2. Ensure you have the required softwares installed with their dependancies (MATLAB, Simulink, Python  etc.).
3. Set up the project environment following the guidelines in the project documentation.


   

Project Structure
-----------------

- **Aircraft Model**: Contains all the MATLAB code and essential files for running the simulation.
- **Wind Files**: The desired wind conditions are defined in ``xwind.csv`` and ``ywind.csv``, located in ``matlab/MATLAB UAV model v3.2/wind_files``. Replace these files as needed for different wind conditions.

Utilities for Support and Plotting
----------------------------------

- **Prognostics Module**: contains supporting Python scripts and a Jupyter notebook for plotting results.

Data Management
---------------

- All simulation-generated files are temporarily stored in the ``data`` folder and then moved to ``data/past_results`` once the simulation finishes.


   

Implementation Guideline
-----------------

The master script, ``main.py``, is the entry point for running the entire codebase.


Running the Codebase
---------------------

1. **Initiate Simulation**: Start the process by running ``main.py``.

2. **Matlab Simulation**:
   
   - Simulates current requirements for a predefined flight path under specific wind conditions.
   - Outputs include:
     - ``current_sim.txt`` in the ``data`` folder, containing the simulation current results.
     - ``batt_sim.csv`` in the ``data`` folder, detailing the simulation time step, voltage, current, and state of charge.

3. **Battery Prognostics**:

   - After MATLAB simulation, the script ``Battery Prognostics/batterypronostics.py`` runs, utilizing ``current_sim.txt`` for state estimation and prediction for the TarotT18 Battery.
   - This script performs multiple simulations (default 500) and outputs ``mc_result.pkl`` in the ``data`` folder.

4. **Result Visualization**:

   - Finally, the Jupyter notebook ``Battery Prognostics/Plots and Results/Plots.ipynb`` is used to plot SOC curves, SOC predictions, voltage simulations, and current inputs.


