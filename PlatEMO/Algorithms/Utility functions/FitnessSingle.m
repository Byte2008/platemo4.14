function Fitness = FitnessSingle(Population)
%FitnessSingle - Fitness calculation for single-objective optimization.
%
%   Fit = FitnessSingle(P) calculates the fitness value of each solution in
%   P for single-objective optimization, where both the objective value and
%   constraint violation are considered.
%
%   Example:
%       Fitness = FitnessSingle(Population)

%------------------------------- Reference --------------------------------
% K. Deb. An efficient constraint handling method for genetic algorithms.
% Computer Methods in Applied Mechanics and Engineering, 2000, 186(2-4):
% 311-338.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    %max(0, Population.cons) ：将负的约束值（满足约束）置为0，只保留正的约束违反值
    %sum(..., 2) ：对每个个体的所有约束违反值求和，得到每个个体的总约束违反程度;结果 PopCon 是一个列向量，每个元素对应一个个体的总约束违反值
    PopCon   = sum(max(0,Population.cons),2);
    Feasible = PopCon <= 0;

    %对于可行个体 ( Feasible 为1)：适应度 = 目标函数值 ( Population.objs )； 对于不可行个体 ( ~Feasible 为1)：适应度 = 约束违反值 + 1e10（一个很大的数）
    %  这种设计确保：- 任何可行解都优于任何不可行解； 在可行解中，目标函数值较小的解更优 在不可行解中，约束违反程度较小的解更优
    Fitness  = Feasible.*Population.objs + ~Feasible.*(PopCon+1e10);
end