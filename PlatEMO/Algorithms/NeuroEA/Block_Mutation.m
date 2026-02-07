classdef Block_Mutation < BLOCK
% Unified mutation for real variables
% nSets --- 5 --- Number of parameter sets

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nSets;      % <hyperparameter> Number of weight sets
        Weight;     % <parameter> Weight sets
        Fit;        % <parameter> Expectation of using each weight set
        nDec = 1;   % Number of decision variables
    end
    methods
        %% Default settings of the block
        function obj = Block_Mutation(nSets)
            obj.nSets = nSets;	% Hyperparameter，参数集的数量如5
            obj.lower = repmat([0 1e-20],1,nSets);	% Lower bounds of parameters，表示标准正态分布标准差和轮渡盘选择概率参数下限。
            obj.upper = repmat([1 5],1,nSets);  	% Upper bounds of parameters
            % Randomly set the parameters
            obj.parameter = unifrnd(obj.lower,ones(1,2*nSets));    %结果为行向量。
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj)
            obj.Weight = reshape(obj.parameter,[],obj.nSets)';   %将 parameter 向量重塑为行数为 obj.nSets 的矩阵，每一行包括一个正态分布采样值和一个（0,1】间的概率。
             %- 除以 obj.nDec 是为了 归一化权重 ，确保随着决策变量数量的增加，每个变量的变异概率不会被过度稀释
             % - 这是一种自适应机制，使得变异操作能够根据问题的实际维度进行调整
             obj.Weight(:,end) = obj.Weight(:,end)./obj.nDec;    
           
            %%功能 ：在权重矩阵末尾添加一行补偿权重
            %  sum(obj.Weight(:,end)) ：计算当前权重矩阵最后一列的总和， max(0,1-sum(obj.Weight(:,end))) ：确保补偿值非负，且使所有权重之和不超过1
            %  结果：权重矩阵行数变为 obj.nSets+1 ，最后一行第一元素为0，第二元素为补偿值， 目的：保证权重分布的有效性和完整性
            obj.Weight = [obj.Weight;0,max(0,1-sum(obj.Weight(:,end)))];

            obj.Fit    = cumsum(obj.Weight(:,end));   %计算权重矩阵最后一列的累积和
            obj.Fit    = obj.Fit./max(obj.Fit);        %将累积和归一化到 [0,1] 范围
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            ParentDec = obj.Gather(Problem,Precursors,Ratio,2,1);
            if size(ParentDec,2) ~= obj.nDec
                obj.nDec = size(ParentDec,2);
                obj.ParameterAssign();
            end
            r          = ParaSampling(size(ParentDec),obj.Weight(:,1),obj.Fit);
            obj.output = ParentDec + repmat(Problem.upper-Problem.lower,size(ParentDec,1),1).*r;
        end
    end
end

function r = ParaSampling(xy,weight,fit)
% Parameter sampling

    r    = repmat(randn(xy(1),1),1,xy(2));
    type = arrayfun(@(S)find(rand<=fit,1),zeros(xy));
    for i = 1 : length(fit)
        index = type == i;
        r(index) = r(index)*weight(i,1);  %转换为均值为0，标准差为σ2的采样值。如果轮渡盘选择为为补偿值行，则乘以0；
    end
end