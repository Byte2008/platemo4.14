classdef Block_Tournament < BLOCK
% Tournament selection
% nParents --- 100 --- Number of parents generated
% upper    ---   2 --- Max number of k for k-tournament

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nParents;       % <hyperparameter> Number of generated parents 
        nTournament;    % <parameter> Number of candidate solutions for selecting a parent
    end
    methods
        %% Default settings of the block
        function obj = Block_Tournament(nParents,upper)
            obj.nParents = nParents;    % Hyperparameter,如200，表示输出解的数量。
            obj.lower    = 1;           % Lower bounds of parameters，锦标赛规模k的下限
            obj.upper    = upper;      	% Upper bounds of parameters，如10，锦标赛规模k的上限
            % Randomly set the parameters
            obj.parameter = unifrnd(obj.lower,obj.upper);
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj)
            obj.nTournament = round(obj.parameter(1));
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            %Precursors实参为Blocks(logical(Graph(:,i)))，为当前节点的前驱节点；Ratio实参为Graph(:,i)，为Graph矩阵中当前元素前驱节点的比例。
            Population = obj.Gather(Problem,Precursors,Ratio,1,1);
            if obj.nTournament == 1
                obj.output = Population(randi(end,1,obj.nParents));
            elseif Problem.M == 1   % For single-objective optimization
                obj.output = Population(TournamentSelection(obj.nTournament,obj.nParents,FitnessSingle(Population)));
            else                    % For multi- and many-objective optimization
                [FrontNo,Dis] = CalFitness(Population);
                %- FrontNo 决定个体的收敛性（前沿编号越小，收敛性越好）。 Dis 决定个体的多样性（值越大，多样性越好）。 通过两者结合，算法能在选择过程中平衡收敛性和多样性，提高多目标优化的性能。
                obj.output    = Population(TournamentSelection(obj.nTournament,obj.nParents,FrontNo,Dis));
            end
        end
    end
end

%用于计算多目标优化中个体的 拥挤度距离 （Crowding Distance），Dis 表示种群中每个个体的拥挤度距离（Crowding Distance） 。
%值越大 ：表示该个体周围的其他个体越少，分布越稀疏，在选择中更有优势（有助于保持种群多样性）。
function [FrontNo,Dis] = CalFitness(Population)
    Dis = zeros(length(Population),1);
    %有约束情况，排序整个种群，返回每个个体的前沿编号，以及最大前沿编号
    [FrontNo,maxF] = NDSort(Population.objs,Population.cons,inf);
    for front = 1 : maxF
        %遍历每个前沿，提取当前前沿个体的目标值。
        PopObj = Population(FrontNo==front).objs;
        %低维目标（<4个目标） ：使用 pdist2 计算所有个体之间的欧氏距离矩阵，将对角线元素设为无穷大（忽略个体到自身的距离）
        if size(PopObj,2) < 4
            %D = pdist2(X,Y)，D(i,j) 对应于 X 中的观测值 i 与 Y 中的观测值 j 之间的两两距离。
            Distance = pdist2(PopObj,PopObj);
            %eye(size(PopObj,1))创建一个对角矩阵，对角线为1，其他元素为0.
            Distance(logical(eye(size(PopObj,1)))) = inf;
        else
            %-使用改进的距离计算方法，统欧氏距离的局限性 ：在高维空间中，欧氏距离可能会因维度诅咒而变得不敏感（所有点对的距离趋于相似），无法有效区分个体的分布密度。
            %基于“最大参考点”的距离 ：通过 max(PopObj, PopObj(i,:)) 构建参考点， 突出了个体 i 与其他个体在目标值上的差异 （特别是较大的目标值维度），
            % 从而在高维空间中更准确地衡量个体间的“拥挤程度”。
            Distance = inf(size(PopObj,1));
            for i = 1 : size(PopObj,1)
                SPopObj = max(PopObj,repmat(PopObj(i,:),size(PopObj,1),1));  %max的参数为两个矩阵是，按照对应位置（i,j)依次计算每个位置的最大值。
                for j = [1:i-1,i+1:size(PopObj,1)]
                    %norm计算欧式距离，如：v = [1 -2 3];n = norm(v);a = [0 3];b = [-2 1];d = norm(b-a)
                    Distance(i,j) = norm(PopObj(i,:)-SPopObj(j,:));
                end
            end
        end
        %对每行进行升序排序 ，找出最近的邻居。
        Distance = sort(Distance,2);
        %计算拥挤度距离：取最近的1-2个邻居的距离，使用距离的倒数和作为拥挤度指标。 距离越小，拥挤度越大（说明该个体周围越拥挤）
        Dis(FrontNo==front) = sum(1./Distance(:,1:min(end,2)),2);
    end
end