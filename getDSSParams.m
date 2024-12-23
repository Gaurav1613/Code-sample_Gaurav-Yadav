%Functionality: To obtain active power, reactive power, voltage magnitude, voltage angle for distributed generator (DG) and capacitor bank (CB) node,
%               and per unit voltage, magnitude voltage and voltage angle at all the nodes.
%
%Inputs:
%  caseFolder: folder name where circuit resides, 'c:\download\'; must have '\'.
%  circuitName: openDSS file name, e.g., 'IEEE13_NineDG_SinglePhase.dss'.
%  curSimuSecond: The current second for which simulation is being performed, e.g., curSimuSecond = 5 means the power flow will run for the fifth second.
%  hour: Power flow will run for this hour, e.g., hour = 5 means the power flow will run for the fifth hour.
%  x: The optimal value of the decision variables. It is a row vector of order nvar x 1, where nvar is the number of unknown variables.
%                   x = [tapXfmr1, tapXfmr2, tapXfmr3, tapXfmr4, tapXfmr5, unitCB1, unitCB2,
%                        unitCB3, unitCB4, QDG1, QDG2, QDG3, QDG4, QDG5, QDG6, QDG7, QDG8, QDG9]
%                   Here, tapXfmr1, tapXfmr2, tapXfmr3, tapXfmr4 and tapXfmr5 are the integer tap numbers of the transformers.
%                   unitCB1, unitCB2, unitCB3 and unitCB4 are the integer value representing total number of switched-on units
%                   of capacitor banks. QDG1, QDG2, QDG3, QDG4, QDG5, QDG6, QDG7, QDG8, QDG9 are the reactive power (kVAR) set
%                   points of the respective DGs.
%  pLim: The scalar factor by which the reactive power set point obtained in first-layer is limited before
%        being transferred to the second-layer.
%  DGKW: DGKW(k) is the injected real power (kW) by kth DG.
%  numDG: Total number of DGs present in the circuit. It is a scalar value.
%  DGNodes: It is the name of the DG Nodes corresponding to each DG. It is an input of cell type {'bus1.node1', 'bus1.node2', 'bus1.node3'}.
%  capNodes: It is the name of the capacitor bank node corresponding to each capacitor bank.
%            Each capacitor bank is a single-phase capacitor bank. It is of cell type {'bus1.node1', 'bus1.node2', 'bus1.node3'}.
%  nodeNameMap: Mapping which links node name with its corresponding node number. Eg., nodeNameMap('Nodename') will give you the number for this node.
%  
%Note: DG has been accessed through index here in OpenDSS.
% 
%
%Outputs:
%  DGP: Active (kW) injected by the DG.
%  DGQ: Reactive power (kVAR) injected by the DG.
%  DGVoltMag: Voltage magnitude (V) of DGs. This is a column vector where (k) is the voltage of kth DG.
%  DGVoltpu: per unit voltage of the DGs. This is a column vector where (k) is the voltage of kth DG.
%  DGVoltBase: Base voltage (V) of kth DG.
%  DGVoltAng: Voltage angle (in radians) of the DGs in the circuit. It is a row vector,
%             e.g., [k1, k2, k3] where k1, k2 and k3 are voltage angle for DG1, DG2 and DG3 respectively.
%  capVoltMag: Voltage magnitude (V) of the capacitor banks. This is a column vector where (k) is the voltage for a kth CB.
%  capVoltpu: per unit voltage of capacitor banks in the circuit. This is a column vector where (k) is the voltage
%                of kth Capacitor Bank which is calculated as per unit.
%  nodeVoltCplx: Complex value of the node voltages (V). (n) for nth node.
%  nodeVoltCplxpu: per unit voltage for all the nodes in the circuit.
%  nodeVoltMag: node voltage magnitude (V) for all nodes.
%  nodeVoltpu: per unit voltage at all the nodes.
%  nodeVoltAng: node voltage angle (radians) for all nodes.
%  nodeVoltBase: node Voltage base (V) for all nodes.
%  QCap: Injected reactive power (KVAR) by capacitor banks. QCap(k) is the injected reactive power of kth capacitor bank.
%  totalInputPQ: Total input active power and reactive power to the circuit.
%                [P, Q] is the total active power (kW) and total reactive power (kVAR).
%  totalLoadPQ: Total active power and reactive power of the loads in the circuit.
%               [P, Q] is the total active power (kW) and total reactive power (kVAR).
%  totalLossPQ: Total active power and reactive power loss in the circuit.
%               [P, Q] is the is the total active power (kW) loss and total reactive power loss (kVAR).
%  PQMismatch: Checks for discrepancy in the obtained total active and reactive power quantites [P Q].
%              A value of [0 0] means there is no mismatch between the power quantites and the power values are correct.
%
%Notes: - COM interface is used to obtain power and voltage parameters.
%       - All variables are physical units except the variables with pu at the end.
%       - All voltages with Mag means magnitude, with Cplx means complex value.
%

function [DGP, DGQ, DGVoltMag, DGVoltpu, DGVoltBase, DGVoltAng, capVoltMag, capVoltpu, nodeVoltCplx, nodeVoltCplxpu, nodeVoltMag, nodeVoltpu,...
    nodeVoltAng, nodeVoltBase, QCap, totalInputPQ, totalLoadPQ, totalLossPQ, PQMismatch] = getDSSParams(circuitName, curSimuSecond, hour, x,...
    numDG, DGNodes, capNodes, nodeNameMap, nodeVoltpuAllSec)

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
DSSText.Command = ['Set hour=',  num2str(hour-1), '  sec=0']; %opendss hour is zero-based
DSSText.Command = 'set controlmode=Time'; % Set the simulation mode.
DSSText.Command = 'set maxcontroliter=1000';
Cap = DSSCircuit.Capacitors; %Returns a Capacitors object interface
regCtrl = DSSCircuit.RegControls;
DSSActiveElement = DSSCircuit.ActiveCktElement; %To provide access to the properties of the active circuit element after solving the circuit.
DGPQ = []; % Active and Reactive power of DGs
nodeNames = DSSCircuit.AllNodeNames;
numNode = length(nodeNames);
totalLoadPQ = []; % Total load power

%% Assign the tap number of the transformers
numRegCtrl = regCtrl.Count; % Total number of regulator control elements. In OpenDSS, all the load tap changing transformers are regulated
% using regulator control element. If you define a three-phase regulator control element as three phase it counts as one controller and same is the
% case for a single-phase regulator element
selRegCtrl = regCtrl.First; % Select the first regulator control element.
while selRegCtrl > 0
    for k = 1 : numRegCtrl
        regCtrl.Winding = 2;
        regCtrl.TapNumber = x(k); % Get the tap number that the controlled transformer winding is currently on.
        selRegCtrl = regCtrl.Next; % Select the next regulator control element. Returns 0 if none.
    end
end

%% Assign the number of available switching units for capacitors.
selCap = Cap.First; % Select the first capacitor.
numCap = Cap.Count;
while selCap > 0
    for k =  1 : Cap.Count
        Cap.NumSteps = x(numRegCtrl + k); % Assign the total number of switching units (integer value)
        selCap = Cap.Next; % Select the next capacitor. Returns 0 if none.
    end
end

%% Run power flow
DSSText.Command = 'Solve';

%% Extract DG powers
for c = 1 : numDG
    dgStr = ['generator.DG', num2str(c)];
    DSSCircuit.SetActiveElement(dgStr); % Select DG1 as the active ckt element
    %Extract DG powers.
    DGPowers = DSSActiveElement.Powers;
    DGP(c, curSimuSecond) = -DGPowers(1);
    DGQ(c, curSimuSecond) = -DGPowers(2);
end

%% Extract Capacitor reactive power
% The capacitor reactive power can also be extracted using the methodology
% used to extract DG powers.
QCap = zeros(numCap,1); % Reactive power of capacitors
selCap = Cap.First; % Select the first capacitor bank
if numCap ~= 0
    while selCap > 0
        CapPowers = DSSActiveElement.Powers;
        Ckvar = CapPowers(:,2);
        QCap(selCap,:) = -Ckvar;
        selCap = Cap.Next;
    end
end

%% Extract substation power, i.e., input power or source bus power.
lineNames = DSSCircuit.Lines.AllNames;
substationLineName = lineNames{1};

DSSCircuit.SetActiveElement(['line.' substationLineName]);

tmp = DSSActiveElement.Powers; %[paf,qaf,pbf,qbf,pcf,qcf,pat,qat,pbt,qbt,pct,qct] f:from bus, t:to bus
tmpPQ = [];
for a = 1:2:length(tmp)
    tmpPQ = [tmpPQ; [tmp(a), tmp(a+1)]];
end

totalInputPQ = [sum(tmpPQ(1:3,1)), sum(tmpPQ(1:3,2));];

%% Extract load power
loadNames = DSSCircuit.Loads.AllNames; %cell array
loadPSum = 0;
loadQSum = 0;

for ii=1:length(loadNames)
    DSSCircuit.SetActiveElement(['load.',loadNames{ii}]);
    % Extract powers
    loadPowers = DSSActiveElement.Powers;
    loadpowSize = size(loadPowers);
    % organizes the array in complex pairs
    loadPNode = 0;
    loadQNode = 0;

    for a = 1 : 2 : loadpowSize(2)
        tmpP = loadPowers(a);
        tmpQ = loadPowers(a + 1);

        loadPNode = loadPNode + tmpP;
        loadQNode = loadQNode + tmpQ;
    end

    for a = 1:2:loadpowSize(2)
        loadPSum = loadPSum + loadPowers(a);
        loadQSum = loadQSum + loadPowers(a + 1);
    end

    totalLoadPQ = [loadPSum, loadQSum]; % Total active power (kW) and total reactive power (kVAR) of all the loads.

end %load loop

%% Get power losses in the circuit
totalLossPQ = totalInputPQ + sum(DGPQ) + [0 sum(QCap)] - totalLoadPQ;

%% Check for any mismatch in P and Q.
PQMismatch = totalInputPQ + sum(DGPQ) + [0 sum(QCap)] - totalLossPQ - totalLoadPQ;

%% Get node voltages
nodeVolt = DSSCircuit.AllBusVolts; %row vector of real values, (1)+1i*(2) is for first node, etc.
tmp = transpose(reshape(nodeVolt, 2, numNode));
nodeVoltCplx = tmp(:,1) + 1i*tmp(:,2);
%change voltage to per unit value here
puVolt = DSSCircuit.AllBusVmagPu;
nodeVoltpu = transpose(puVolt);
nodeVoltpuAllSec(:, curSimuSecond) = nodeVoltpu;

nodeVoltCplxpu = nodeVoltpu .* (nodeVoltCplx./abs(nodeVoltCplx));
nodeVoltMag = abs(nodeVoltCplx);
nodeVoltAng = angle(nodeVoltCplx);

%calculate base voltage here
nodeVoltBase = abs(nodeVoltCplx)./nodeVoltpu;

%*********Get voltage magnitude, base voltage, voltage angle and per unit voltage at DG nodes***********
DGVoltMag = ones(numDG,1);
DGVoltpu = ones(numDG,1);
DGVoltBase = ones(numDG,1);
DGVoltAng = ones(numDG,1);

for c = 1 : numDG
    currDGNode = DGNodes{c};
    voltMag = nodeVoltMag(nodeNameMap(currDGNode));
    voltAng = nodeVoltAng(nodeNameMap(currDGNode));
    voltBase = nodeVoltBase(nodeNameMap(currDGNode));
    Vpu = voltMag/voltBase;

    DGVoltMag(c) = voltMag;
    DGVoltpu(c) = Vpu;
    DGVoltBase(c) = voltBase;
    DGVoltAng(c) = voltAng;
end

%*********Get voltage magnitude, base voltage, voltage angle and per unit voltage at Capacitor bank nodes***********
capVoltMag = ones(numCap,1);
capVoltpu = ones(numCap,1);
capVoltBase = ones(numCap,1);
capVoltAng = ones(numCap,1);

for c = 1 : Cap.Count
    currCapNode = capNodes{c};
    voltMag = nodeVoltMag(nodeNameMap(currCapNode));
    voltAng = nodeVoltAng(nodeNameMap(currCapNode));
    voltBase = nodeVoltBase(nodeNameMap(currCapNode));
    Vpu = voltMag/voltBase;

    capVoltMag(c) = voltMag;
    capVoltBase(c) = voltBase;
    capVoltpu(c) = Vpu;
    capVoltAng(c) = voltAng;
end

end



