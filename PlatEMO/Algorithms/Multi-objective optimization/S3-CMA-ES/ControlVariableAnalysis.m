function [PV,DV] = ControlVariableAnalysis(Problem,NCA)
% Control variable analysis

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

% This function is written by Huangke Chen
    %逐维改变该维，观测NDSort的最大前沿层数来衡量“对目标的控制能力”，选取前M−1维为PV，其余为DV。思路：若仅改变某一维就能在目标空间产生较多层的非支配分层（MaxFNo大），说明该维强烈影响朝前沿的收敛；相反则更像是“定位/多样性”变量。最终选前M−1维为PV，其余为DV。
    Fno = zeros(1,Problem.D);
    for i = 1 : Problem.D
        x          = 0.2*ones(1,Problem.D).*(Problem.upper-Problem.lower) + Problem.lower;
        S          = repmat(x,NCA,1);
        inter      = (0.95-0.05)/(NCA-1);
        tempA      = 0.05:inter:0.96;
        S(:, i)    = tempA'*(Problem.upper(i)-Problem.lower(i)) + Problem.lower(i);
        S          = Problem.Evaluation(S);
        [~,MaxFNo] = NDSort(S.objs,inf);
        Fno(i)     = MaxFNo;      
    end
    [~,I] = sort(Fno);
    PV    = sort(I(1:Problem.M-1));
    DV    = sort(I(Problem.M:end));
end