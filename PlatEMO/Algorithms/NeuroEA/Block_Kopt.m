classdef Block_Kopt < BLOCK
% k-opt
% k --- 4 --- Max number of k for k-opt

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        k;      % <hyperparameter> Max number of k for k-opt
        Fit;	% <parameter> Probability of using k-opt
    end
    methods
        %% Default settings of the block
        function obj = Block_Kopt(k)
            obj.k     = k;
            obj.lower = zeros(1,obj.k) + 1e-20;
            obj.upper = ones(1,obj.k);
            % Randomly set the parameters，设置[1 k]之间的概率分布
            obj.parameter = unifrnd(obj.lower,obj.upper);
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj,~,~)
            obj.Fit = cumsum(obj.parameter);
            obj.Fit = obj.Fit./max(obj.Fit);
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            ParentDec = obj.Gather(Problem,Precursors,Ratio,2,1);
            %type: 为每个个体随机选择一个操作类型（k 值）。
            type = arrayfun(@(S)find(rand<=obj.Fit,1),1:size(ParentDec,1));
            %仅对 type > 1 的个体执行操作（ type=1 意味着保持原样不进行变异）
            for i = find(type>1)
                %s: 生成一个长度为 type(i) 的切点向量 s ，s中每个元素表示断开边的点。
                s = randi([1 Problem.D-(type(i)-1)*2],1,type(i));
                for j = 2 : type(i)
                    %在决策变量长度 Problem.D 范围内，随机选择 type(i) 个位置作为切点。
                    %约束 ： s(j-1)+2 确保相邻切点之间至少间隔 2 个元素，保证每个切出的片段至少包含 1 个元素且不为空，避免无效操作。
                    s(j) = randi([s(j-1)+2,Problem.D-(type(i)-j)*2]);
                end
                newPerm = 1 : s(1);  % 保留第一段（起点到第一个切点）
                %随机打乱中间片段的顺序
                for j = randperm(type(i)-1) 
                    % 取出第 j 个中间片段：从 s(j)+1 到 s(j+1)
                    if type(i)==2 || rand>0.5
                        % 如果是 2-opt (type==2) 或者 50% 概率：翻转该片段 (Inversion)
                        newPerm = [newPerm,flip(s(j)+1:s(j+1))];
                    else
                        % 否则直接拼接该片段
                        newPerm = [newPerm,s(j)+1:s(j+1)];
                    end
                end
                newPerm = [newPerm,s(end)+1:Problem.D]; % 拼接最后一段（最后一个切点到终点）
                ParentDec(i,:) = ParentDec(i,newPerm);
            end
            obj.output = ParentDec;
        end
    end
end