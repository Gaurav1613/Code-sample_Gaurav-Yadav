%% Functionality: Get the node map, which can be used to obtain the index given a node name and vice-versa.
%
%Inputs:
%  circuitName: openDSS file name, e.g., 'IEEE13FirstLayerCircuit.dss'.
%  nodeNames: a cell array of strings containing node names, {'name1', 'name2', 'name3'}
%
%Outputs:
%  nodeNameMap: a map type. nodeNameMap('name2') gives the node number for 'name2' node.
%  nodeNumMap: a map type. nodeNumMap('2') gives the node name for node number 2.

function [nodeNameMap, nodeNumMap] = GetNameMap(circuitName, nodeNames)

DSSObj = actxserver('OpenDSSEngine.DSS');

if ~DSSObj.Start(0)
    disp('Error: Unable to start the OpenDSS Engine');
    return
end

DSSText = DSSObj.Text;
DSSText.Command = ['Compile (', circuitName, ')'];

numNode = length(nodeNames);
keySet = nodeNames;
valueSet = 1 : numNode;
nodeNameMap = containers.Map(keySet, valueSet);
nodeNumMap = containers.Map(valueSet, keySet);

end