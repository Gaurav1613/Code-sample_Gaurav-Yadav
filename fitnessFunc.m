%% Functionality - To calculate the fitness value of the fitness function. This fitness function is used for Genetic Algorithm (GA) optimization.
% 
%Inputs:
%  x: Column vector of unknown variables involved in GA optimization, of order nvars x 1, where nvar is the number of unknown variables.
%     x = [Tap3phaseTransformer1, Tap3phaseTransformer2, TapTransformer3, TapTransformer4, TapTransformer5, m_CB1, m_CB2, m_CB3, m_CB4] 
%  hour: Power flow will run for this hour, e.g., hour = 5 means the power flow will run for the fifth hour.
%  circuitName: openDSS file name, e.g., 'IEEE13FirstLayerCircuit.dss'.
%  lowerVoltLimit: Lower bound for the node voltages. It is 114V, i.e., 0.95 p.u. (for a base voltage of 120 V) as per ANSI standards.
%  upperVoltLimit: Upper bound for the node voltages. It is 126V, i.e., 1.05 p.u. (for a base voltage of 120 V) as per ANSI standards.
%  voltLimViolPenaltyFactor: Penalty factor for violating the lower or upper ANSI voltage limit for the node voltage. It is a scalar value.
%
%Output:
%  F: Value of the fitness function, i.e., the objective function. It is a scalar value.


function F = fitnessFunc(x, hour, circuitName, lowerVoltLimit, upperVoltLimit, voltLimViolPenaltyFactor)

DSSObj = actxserver('OpenDSSEngine.DSS');

if ~DSSObj.Start(0)
    disp('Unable to start the OpenDSS Engine');
    return
end

DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSObj.Allowforms = false;
DSSText.Command = ['Compile (', circuitName, ')'];
DSSText.Command = 'set mode=daily';
DSSText.Command = 'Set number=1  stepsize=1h';
DSSText.Command = 'set controlmode=Time';
DSSText.Command = 'set maxcontroliter=1000';

Cap = DSSCircuit.Capacitors; %Returns a Capacitors object interface
Lines = DSSCircuit.Lines; %Returns a Lines object interface
regCtrl = DSSCircuit.RegControls; %Returns a RegControl object interface
DSSActiveElement = DSSCircuit.ActiveCktElement; %To provide access to the properties of the active circuit element after solving the circuit.
nodeNames = DSSCircuit.AllNodeNames;
numNode = length(nodeNames);

DSSText.Command = ['Set hour=',  num2str(hour-1), '  sec=0']; %opendss hour is zero-based

%% Assign the tap number of the transformers
numRegCtrl = regCtrl.Count; % Total number of regulator control elements.
selRegCtrl = regCtrl.First; % Select the first regulator control element.
while selRegCtrl > 0
    for k = 1 : numRegCtrl
        regCtrl.Winding = 2;
        regCtrl.TapNumber = x(k); % Get the tap number that the controlled transformer winding is currently on.
        selRegCtrl = regCtrl.Next; % Select the next regulator control element. Returns 0 if none.
    end
end

%% Assign the number of available switching units for capacitors.
numCap = Cap.Count; % Total number of capacitors.
selCap = Cap.First; % Select the first capacitor.
while selCap > 0
    for k =  1 : numCap
        Cap.NumSteps = x(numRegCtrl + k); % Assign the total number of switching units (integer value)
        selCap = Cap.Next; % Select the next capacitor. Returns 0 if none.
    end
end

%% Solve the circuit
DSSText.Command = 'Solve';

%% Get node voltages
nodeVolt = DSSCircuit.AllBusVolts; %row vector of real values, (1)+1i*(2) is for first node, etc.
tmp = transpose(reshape(nodeVolt, 2, numNode));
nodeVoltCplx = tmp(:,1) + 1i*tmp(:,2);
%change voltage to per unit value here
puVolt = DSSCircuit.AllBusVmagPu;
nodeVoltMagpu = transpose(puVolt);

%calculate base voltage here
nodeVoltBase = abs(nodeVoltCplx)./nodeVoltMagpu;

%% Get input bus power
lineNames = Lines.AllNames;
substationLineName = lineNames{1};
DSSCircuit.SetActiveElement(['line.' substationLineName]);
tmp = DSSActiveElement.Powers; %[paf,qaf,pbf,qbf,pcf,qcf,pat,qat,pbt,qbt,pct,qct] f:from bus, t:to bus
tmpPQ = [];
for a = 1:2:length(tmp)
    tmpPQ = [tmpPQ; [tmp(a), tmp(a+1)]];
end

totalInputPQ = [sum(tmpPQ(1:3,1)), sum(tmpPQ(1:3,2))];
totalInputP = totalInputPQ(1);

%% Calculate voltage limit violation penalties
voltLimitPenalty = voltLimitViolationPenalty(nodeVoltMagpu, nodeVoltBase, lowerVoltLimit, upperVoltLimit, voltLimViolPenaltyFactor);

%% Calculate the fitness function
F = totalInputP + voltLimitPenalty;

end
