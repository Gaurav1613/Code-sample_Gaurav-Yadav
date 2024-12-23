# Code-sample_Gaurav-Yadav
This repository contains the files required to perform voltage regulation in a power distribution circuit using Genetic Algorithm (GA). The optimization has been performed using MATLAB and OpenDSS, connected through COM interface. Following are included to run the program:

**Main file**

GAOptim_Main.m - This is the main file to be used to run GA optimization. 

**Supporting files**
1. getElementNamesAndCount.m - This element is used to obtain the total number of elements and the nodes to which they are connected.
2. GetNameMap.m - This function is used to map node name with their corresponding index in the OpenDSS file for the power distribution circuit.
3. getBounds.m - This functions sets the lower and upper limit of the decision variables for GA optimization.
4. fitnessFunc.m - This function serves as the fitness function for GA optimization.
5. getDSSParams.m - This function is used to obtain optimal value of the voltage and power parameters of the given OpenDSS file.
6. voltLimitViolationPenalty - This function is used to ensure node voltage remain within the ANSI bounds during GA optimization.
7. IEEE13Bus.dss - This is the OpenDSS file for a modified IEEE 13-bus distribution circuit.
8. IEEELineCodes.dss - This is the OpenDSS file defining the line parameters for the modified IEEE 13-bus distribution circuit.
9. IEEE13Node_BusXY.csv - This is the .csv file defining the location of buses in the modified IEEE 13-bus distribution circuit.
10. Norm_AnnualSolarIrrad_2021.mat - This is the MATLAB data file containing normalized annual solar irradiance data for year 2021.
11. hourlyLoadData_HI_Circuit_Year2021.txt - This is the text file containing the load profile for a local distribution utility for year 2021.

Further information on the above MATLAB functions can be found inside the corresponding .m files.

