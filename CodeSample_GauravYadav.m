% The objective of this code is to perform voltage regulation using Genetic Algorithm (GA) by obtaining optimal tap number for transformers and optimal 
% switching status of the units of capacitor banks (CBs). The optimization is repeated after a chosen time interval for the considered total
% simulation time.
%
% GA Outputs:
%  x: Optimal value for the uknown variables. It is a row vector of order (1 x nVar).
%  fval: Optimal value of the fitness function.
%  exitflag: An integer code denoting the reason for termination of the iterations.
%  output: It is a structure providing information about the optimization process. It has predefined fields as shown below:
%          a) probelmtype - Problem type, i.e., unconstrained, boundconstraints, linearconstraints, nonlinearconstr, integerconstraints.
%          b) rngstate - State of the MATLAB random number generator, just before the algorithm started.
%          c) generations - Number of generations computed.
%          d) funccount - Number of evaluations of the fitness function.
%          e) message — Reason the algorithm terminated.
%          f) maxconstraint — Maximum constraint violation, if any.
%          g) hybridflag — Exit flag from the hybrid function.
%  population: It is a matrix of order (popsize x nVar) where popsize is the population size and nVar is the number of unknown variables.
%  scores: Value of the fitness function for each individual. It is a column vector of size (popsize x 1). 

clear;

circuitName = 'IEEE13Bus.dss'; % OpenDSS file for the power distribution circuit

numHours = 1; % Total number of hours to simulate
numSecInOneHourToSimu = 100; % Total number of seconds in one hour to simulate: 1 to 3600.
optInt = 51; % Time interval after which GA optimization is repeated.

% Function to obtain mapping for node name and numbers, number of DGs, number of capacitor banks (CBs)
[nodeNameMap, nodeNumMap, numNodes, DGNodes, numDG, capNodes] = getElementNamesAndCount(circuitName);

DGSizeRatio = 1/10; % This ratio is used to scale apparent power (DGSKVA) and Maximum active power (DGPMax) of the DGs.
DGSKVA = transpose(repelem(400, numDG)* DGSizeRatio); % Apparent power (kVA) of the DGs.
DGPMax = transpose(repelem(300, numDG)* DGSizeRatio); % Maximum injected active power (kW) of the DGs.
QCapMax = [200 200 200 50 50 50]; % Rated reactive power (kVAR) of the CBs.

numTaps = 32; % Total number of taps available in a transformer.

Pmulti = load('Norm_AnnualSolarIrrad_2021.mat'); % .mat file containing second-based irradiance data.
solarIrrad = Pmulti.NormAnnualSolarIrrad2021; % Second-based annual irradiance data scaled between 0  and 1 for Oahu, Hawaii, KY for March 2010.
                                              % The data has been obtained from NREL (https://midcdmz.nrel.gov/apps/sitehome.pl?site=OAHUGRID).
                                              % The data has been collected in Hawaii Standard Time (HST) from 00:00 to 23:59, i.e., 24 hours or
                                              % 86400 seconds.
pLim = 0.8; % Limit for the inverter reactive power
nVar = 9; % Total number of decision variables
lowerVoltLimit = 0.95; % Lower voltage limit for the node voltage as per the American National Standards Institute (ANSI) standards.
upperVoltLimit = 1.05; % Upper voltage limit for the node voltage as per the American National Standards Institute (ANSI) standards.
voltLimViolPenaltyFactor = 100; % Penalty factor for violation of ANSI voltage limits.
intcon = 1:9; % The decision variables which are integer in nature.

nodeVoltpuAllSec = zeros(numNodes, numHours*numSecInOneHourToSimu); % Node voltage for all the nodes for the total simulation time. 

for hour = 1 : numHours
    for sec = 1 : numSecInOneHourToSimu
        curSimuSecond = (hour - 1) * 3600 + sec; % Current simulation second.
        DGKW = solarIrrad(curSimuSecond) * DGPMax; % DGKW is the injected real power (kW) to the DGs.
        disp(['In Progress: hour/second: ', num2str(hour), '/', num2str(sec)]);
        if sec == 1 || mod(sec, optInt) == 0 % Repeat optimization after the time interval provided by 'optInt'. 
            % Function to obtain lower and upper limit of the decision variables.
            [lb, ub] = getBounds(circuitName, numTaps, numDG, DGSKVA, DGKW, pLim);
            % Function to select maximum generation, population size and function tolerance for GA.
            opt = optimoptions('ga', 'Display', 'iter', 'MaxGeneration', 100*nVar, 'PopulationSize', 40, 'FunctionTolerance', 1e-3);
            % Fitness function for GA.
            fitnessFunction = @(x) fitnessFunc(x, hour, circuitName, lowerVoltLimit, upperVoltLimit, voltLimViolPenaltyFactor);
            % Function to run optimization using GA.
            [x, fval, exitflag, output, population, scores] = ga(fitnessFunction, nVar, [], [], [], [], lb, ub, [], intcon, opt);
        end
        % Function to obtain voltage and power parameters through OpenDSS for the nodes in the power distribution circuit. 
        [DGP, DGQ, DGVoltMag, DGVoltMagpu, DGVoltBase, DGVoltAng, capVoltMag, capVoltMagpu, nodeVoltCplx, nodeVoltCplxpu, nodeVoltMag, nodeVoltMagpu,...
            nodeVoltAng, nodeVoltBase, QCap, totalInputPQ, totalLoadPQ, totalLossPQ, PQMismatch] = getDSSParams(circuitName, curSimuSecond, hour, x,...
            numDG, DGNodes, capNodes, nodeNameMap);
    end
end
