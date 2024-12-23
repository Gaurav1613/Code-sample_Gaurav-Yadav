%% Functionality - To obtain the node names and count for the circuit, and for various circuit elements.
%
%Inputs:
%  circuitName: openDSS file name, e.g., 'IEEE13_NineDG_SinglePhase.dss'
%
%Outputs:
%  nodeNameMap: Mapping which links node name with its corresponding node number.
%               Eg., nodeNameMap('Nodename') will give you the number for this node.
%  nodeNumMap: Mapping which links node number with its corresponding node name.
%               Eg., nodeNumMap(Nodenumber) will give you the name for this node.
%  numNodes: Total number of nodes in the circuit. It is a scalar value.
%  DGNodes: It is the name of the nodes corresponding to each DG. It is an input of cell type {'bus1.node1', 'bus1.node2', 'bus1.node3'}.
%  numDG: Total number of distributed generators (DGs) in the circuit. It is a scalar value.
%  capNodes: It is the name of the nodes corresponding to each capacitor bank (CB). It is an input of cell type {'bus1.node1', 'bus1.node2', 'bus1.node3'}.

function [nodeNameMap, nodeNumMap, numNodes, DGNodes, numDG, capNodes] = getElementNamesAndCount(circuitName)

DSSObj = actxserver('OpenDSSEngine.DSS');

if ~DSSObj.Start(0)
    disp('Error: Unable to start the OpenDSS Engine');
    return
end

DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSText.Command = ['Compile (', circuitName, ')']; % Compile the OpenDSS circuit
DSSActiveElement = DSSCircuit.ActiveCktElement;

nodeNames = DSSCircuit.AllNodeNames; % OpenDSS circuit interface to obtain node names.
numNodes = length(nodeNames);
DG = DSSCircuit.Generators; % Returns a Generators object interface
cap = DSSCircuit.Capacitors; %Returns a Capacitors object interface

%% Extract the node names to which the DGs are connected
DGNames = DG.AllNames;  % Name of all the DGs
DGNodes = cell(length(DGNames),1);
for ii=1:length(DGNames)
    DSSCircuit.SetActiveElement(['generator.',DGNames{ii}]); % Activate the generator element, i.e., DG.
    DGNodes(ii) = DSSActiveElement.BusNames; %Node names for the DGs.
end

numDG = length(DGNodes); % Total number of DGs in the OpenDSS circuit.

%% Extract the node names to which the capacitor banks are connected
capNames = cap.AllNames;  % Name of all the DGs
capNodes = cell(length(capNames),1);
for ii=1:length(capNames)
    DSSCircuit.SetActiveElement(['Capacitor.',capNames{ii}]); % Activate the generator element, i.e., DG.
    tmp = DSSActiveElement.BusNames;
    capNodes(ii) = tmp(1); %Node names for the DGs.
end

%% Mapping for the circuit nodes
[nodeNameMap, nodeNumMap] = GetNameMap(circuitName, nodeNames);

end