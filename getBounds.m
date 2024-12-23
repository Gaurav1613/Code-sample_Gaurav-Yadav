%% Functionality - To set the lower and upper limit for the unknown variables, i.e., decision variables participating in GA optimization.
%
%Inputs:
%  caseFolder: folder name where circuit resides, 'c:\download\'; must have '\'.
%  circuitName: openDSS file name, e.g., 'IEEE13FirstLayerCircuit.dss'.
%  numTaps: Total number of taps available for a tranformer. It is a scalar value.
%  numDG: Total number of DGs present in the circuit. It is a scalar value. 
%  DGSKVA: Apparent power for each DG, DGSKVA(k) for kth DG. E.g., [1350; 1050; 1150,....., lastDG], in KVA.
%  DGKW: DGKW(k) is the injected real power (kW) to kth DG.
%  pLim: The scalar factor by which the reactive power set point obtained in first-layer is limited before being transferred to the second-layer.
%
%Outputs:
%  lb: Lower limit for the unknown variables. It is a row vector.
%                 lb = [tapXfmr1_min, tapXfmr2_min, tapXfmr3_min, tapXfmr4_min, tapXfmr5_min, unitCB1_min, unitCB2_min,
%                       unitCB3_min, unitCB4_min, QDG1_min, QDG2_min, QDG3_min, QDG4_min, QDG5_min, QDG6_min, QDG7_min, QDG8_min, QDG9_min]
%                 Here, tapXfmr1_min, tapXfmr2_min, tapXfmr3_min, tapXfmr4_min and tapXfmr5_min are
%                 the minimum possible tap number for the respective transformer, e.g., -16.
%                 unitCB1_min, unitCB2_min,unitCB3_min and unitCB4_min are the minimum available
%                 units in the respective capacitor bank, e.g., 0.
%                 QDG1_min, QDG2_min, QDG3_min, QDG4_min, QDG5_min, QDG6_min, QDG7_min, QDG8_min and
%                 QDG9_min are the minimum available reactive power (kVAR) of the respective DG which is -sqrt(S^2 - P^2) where, P is the
%                 active power (kW) dependent on the irradiance, i.e., P = Pmulti*Pmax, where, Pmulti is the second-based
%                 irradiance multiplier. S is the rated kVA power. Pmax is the rated active power (kW).
%  ub: Upper limit for the unknown variables. It is a row vector.
%                 ub = [tapXfmr1_max, tapXfmr2_max, tapXfmr3_max, tapXfmr4_max, tapXfmr5_max, unitCB1_max, unitCB2_max,
%                       unitCB3_max, unitCB4_max, QDG1_max, QDG2_max, QDG3_max, QDG4_max, QDG5_max, QDG6_max, QDG7_max, QDG8_max, QDG9_max]
%                 Here, tapXfmr1_max, tapXfmr2_max, tapXfmr3_max, tapXfmr4_max and tapXfmr5_max are
%                 the maximum possible tap number for the respective transformer, e.g., 16.
%                 unitCB1_max, unitCB2_max,unitCB3_max and unitCB4_max are the maximum available
%                 units in the respective capacitor bank, e.g., 4.
%                 QDG1_max, QDG2_max, QDG3_max, QDG4_max, QDG5_max, QDG6_max, QDG7_max, QDG8_max and QDG9_max
%                 are the maximum available reactive power (kvar) of the respective DG which is sqrt(S^2 - P^2) where, P is the
%                 active power (kW) dependent on the irradiance, i.e., P = Pmulti*Pmax, where, Pmulti is the second-based
%                 irradiance multiplier. S is the rated kVA power. Pmax is the rated active power (kW).

function [lb, ub] = getBounds(circuitName, numTaps, numDG, DGSKVA, DGKW, pLim)

DSSObj = actxserver('OpenDSSEngine.DSS');

if ~DSSObj.Start(0)
    disp('Unable to start the OpenDSS Engine');
    return
end

DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSText.Command = ['Compile (', circuitName, ')']; % Compile the OpenDSS file

Cap = DSSCircuit.Capacitors; %Returns a Capacitors object interface
Xfmr = DSSCircuit.Transformers; %Returns a Transformers object interface

%% Set the bounds for transformer taps
numXfmr = Xfmr.Count; % Total number of transformers.
minTapNum = ones(1, numXfmr);
maxTapNum = ones(1, numXfmr);
selXfmr = Xfmr.First;
while selXfmr > 0
    for k = 1 : numXfmr
        Xfmr.NumTaps = numTaps; 
        minTapNum(k) = -0.5 * Xfmr.NumTaps; % Get the minimum tap number.
        maxTapNum(k) = 0.5 * Xfmr.NumTaps; % Get the maximum tap number.
        selXfmr = Xfmr.Next;
    end
end

%% Set the bounds for capacitor bank units
numCap = Cap.Count;
maxSwitchedOnUnits = ones(1, numCap);
selCap = Cap.First;
while selCap > 0
    for k = 1 : numCap
        maxSwitchedOnUnits(k) = Cap.NumSteps; % Get the number of units available to be switched on in a CB. 
        selCap = Cap.Next;
    end
end

%% Lower and upper bounds for the control settings
lb = [minTapNum zeros(1, numCap)]; % lower bound
ub = [maxTapNum maxSwitchedOnUnits]; % upper bound

end