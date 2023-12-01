# Battery-Summer-Project
Batteries are becoming increasingly prevalent in unmanned aerial vehicles. Hence, one of the major challenges that need to be addressed to successfully integrate unmanned aerial vehicles into the national airspace is the assessment of flight mission risks associated with the available battery energy. The overall objective of your summer project is to contribute to the development of a framework to quantify uncertainty in mission success due to available battery energy.
This repository contains all your works related to your summer project. 

# Introduction 
Our aim in the battery energy-related mission success/failure prediction process is to predict the occurrence of the battery's EoD, which is defined as the time at which the SoC of the battery falls below a pre-defined threshold value. SoC of a battery is typically defined as 1 when the battery is fully charged and 0 when the battery is discharged to a predetermined voltage threshold. Such a task is known as prognostics, and we adopted model-based prognostics architecture from [1]. 

The battery model utilized in this study is an electro-chemical-based model of Lithium-ion batteries, as described in [1], which are a popular choice for powering unmanned aerial vehicles. In this model, the battery's current draw ($I$) serves as the input, while the battery temperature ($tb$) and the voltage drop caused by solid-phase ohmic resistance ($V_o$) represent its outputs ($y(k)$).

# Prognostics Architecture 
The prognostics architecture comprises two major steps: estimation and prediction. the joint state-parameter estimate $p(x(k), \theta(k)|y(k_0:k))$ is computed using the system dynamics and observation history up to time $k$ represented as $y(k_0:k)$. On the other hand, in the prediction step, the probability distribution $p(k_E(k_P)|y(k_0:k_P))$ at prediction time $k_p$ is computed using the joint state-parameter estimate and hypothesized future inputs of the system. The estimation algorithm used in this paper is the Uncented Kalman Filter, along with the battery model. The UKF uses sigma points which are deterministic points that are used to represent the joint state-parameter distribution $p(x(k), \theta(k),|y(k_0:k))$. The predictor algorithm used in this paper is the Monte Carlo predictor, which randomly samples from the battery's current state distribution, and each sample is simulated to the EoD.  By collecting a set of EoD points from several Monte Carlo simulations, the probability distribution can be built, and the probability of mission success at a given time can be computed using the following equation:


   $$ P_{success}(time) = \frac{\sum_{i=1}(EOD(i) > time)}{n}$$

$n$ represents the number of Monte Carlo simulations in the prediction step.

# EoD Prediction Procedure

