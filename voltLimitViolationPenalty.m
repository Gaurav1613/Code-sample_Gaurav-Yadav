%% Functionality - To calculate the penalty for violating the lower or upper node voltage limit. This penalty factor is added to the fitness function to ensure that the voltage stays within the bound. 
% 
% Inputs:
% nodeVoltMagpu: per unit voltage at all the nodes.
% nodeVoltBase: node Voltage base (V) for all nodes.
% lowerVoltLimit: Lower bound for the node voltages. It is 0.95 p.u. (on a base of 120 V) as per ANSI standards.
% upperVoltLimit: Upper bound for the node voltages. It is 1.05 p.u. (on a base of 120 V) as per ANSI standards.
% voltLimViolPenaltyFactor: Penalty factor for violating the lower or upper limit of the node voltage. It is a scalar value.
%
% Output:
% voltLimitPenalty: Penalty for violating the voltage limits. It is a scalar value.


function voltLimitPenalty = voltLimitViolationPenalty(nodeVoltMagpu, nodeVoltBase, lowerVoltLimit, upperVoltLimit, voltLimViolPenaltyFactor)

voltLimitPenalty = voltLimViolPenaltyFactor * (sum(max(0, ((nodeVoltMagpu - upperVoltLimit) .* nodeVoltBase))) + sum(max(0, ((lowerVoltLimit - nodeVoltMagpu) .* nodeVoltBase))));

end
