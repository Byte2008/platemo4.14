classdef Block_Exchange < BLOCK
% Exchange of parents
% nParents --- 2 --- Number of parents generating one offspring

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nParents;   % <hyperparameter> Number of parents for generating an offspring
        Fitness;    % <parameter> Probability of selecting each parent
    end
    methods
        %% Default settings of the block
        function obj = Block_Exchange(nParents)
            obj.nParents = nParents;	% Hyperparameter，每nParents个父类对象产生一个子类对象。
            obj.lower    = zeros(1,nParents) + 1e-20;   % Lower bounds of parameters ，参数为选择某一个父类对象的概率。
            obj.upper    = ones(1,nParents);            % Upper bounds of parameters
            % Randomly set the parameters
            obj.parameter = unifrnd(obj.lower,obj.upper);
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj)
            obj.Fitness = cumsum(obj.parameter);
            obj.Fitness = obj.Fitness./max(obj.Fitness);
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            %收集前驱节点的输出（决策向量），输出个数是nParents的整数倍。
            ParentDec  = obj.Gather(Problem,Precursors,Ratio,2,obj.nParents);
            %找出每一个子对象每一维来自的父对象索引。
            selected   = arrayfun(@(S)find(rand<=obj.Fitness,1),zeros(size(ParentDec,1)/obj.nParents,size(ParentDec,2)));
            %将初步生成的父代选择索引（1-nParents范围内）转换为 ParentDec 矩阵中的实际线性索引
            selected   = selected + repmat((0:size(selected,1)-1)'*obj.nParents,1,size(ParentDec,2));
            %矩阵以列为主序存储，所以(0:size(selected,2)-1)*size(ParentDec,1)代码每一列相对前一列的偏移量。再加上行号，
            % 可以获取selected[i，j]第j列对应的父元素第j列存储序号
            selected   = selected + repmat((0:size(selected,2)-1)*size(ParentDec,1),size(selected,1),1);
            obj.output = ParentDec(selected);
        end
    end
end