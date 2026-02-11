classdef Block_Selection < BLOCK
% Environmental selection
% nSolutions --- 100 --- Number of retained solutions

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nSolutions;     % <hyperparameter> Number of retained solutions
    end
    methods
        %% Default settings of the block
        function obj = Block_Selection(nSolutions)
            obj.nSolutions = nSolutions;    % Number of retained solutions，如100
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            %从前驱节点收集输出，并对解进行评估。
            Population = obj.Gather(Problem,Precursors,Ratio,1,1);
            if Problem.M == 1	% For single-objective optimization
                [~,rank]   = sort(FitnessSingle(Population));
                obj.output = Population(rank(1:min(end,obj.nSolutions)));
            else                % For multi- and many-objective optimization
                %%有约束，对obj.nSolutions个个体进行排序，返回每个个体的前沿编号，以及最大前沿编号
                [FrontNo,MaxFNo] = NDSort(Population.objs,Population.cons,obj.nSolutions);
                %FrontNo中不是最大前沿的元素索引。
                Next = find(FrontNo<MaxFNo);
                %FrontNo中最大前沿的元素索引。
                Last = find(FrontNo==MaxFNo);
                Del  = Truncation(Population(Last).objs,Population([Last,Next]).objs,length([Last,Next])-obj.nSolutions);
                obj.output = Population([Next,Last(~Del)]);
            end
        end
    end
end

%PopObjLast：种群中所有最大前沿中元素的目标函数值；PopObjAll种群中所有排序元素的目标函数值；k:已经排序元素与需要保留元素的差。
function Del = Truncation(PopObjLast,PopObjAll,K)
    if size(PopObjLast,2) < 4
        %D = pdist2(X,Y)，D(i,j) 对应于 X 中的观测值 i 与 Y 中的观测值 j 之间的两两距离。
        Distance = pdist2(PopObjLast,PopObjAll);
        Distance(logical(eye(size(PopObjLast,1)))) = inf;
    else
         %-使用改进的距离计算方法，统欧氏距离的局限性 ：在高维空间中，欧氏距离可能会因维度诅咒而变得不敏感（所有点对的距离趋于相似），无法有效区分个体的分布密度。
         %基于“最大参考点”的距离 ：通过 max(PopObj, PopObj(i,:)) 构建参考点， 突出了个体 i 与其他个体在目标值上的差异 （特别是较大的目标值维度），
         % 从而在高维空间中更准确地衡量个体间的“拥挤程度”。
        Distance = inf(size(PopObjLast,1),size(PopObjAll,1));
        %遍历最大前沿中每一个元素。
        for i = 1 : size(PopObjLast,1)
            % SPopObj每一行存储PopObjAll中每一个行与最大前沿中第i个元素每一个目标函数值的最大值。
            SPopObj = max(PopObjAll,repmat(PopObjLast(i,:),size(PopObjAll,1),1));
            for j = [1:i-1,i+1:size(PopObjAll,1)]
                %norm计算欧式距离，如：v = [1 -2 3];n = norm(v);a = [0 3];b = [-2 1];d = norm(b-a)
                %Distance(i,：)存储的是最大前沿中第i个元素与SPopObj所有元素的欧式距离。每一行前面存储的是与最大前沿中元素的距离，后面的是与非最大前沿中元素的距离。
                Distance(i,j) = norm(PopObjLast(i,:)-SPopObj(j,:));
            end
        end
    end
    % - 初始化 Del 为全false向量，表示哪些个体需要被删除
    % - 进入循环，当删除的个体数量小于K时：
    % - 找出尚未被删除的个体索引 Remain
    % - 计算并排序每个剩余个体与其他相关个体的距离
    % - 对排序后的距离矩阵按行排序，得到 Rank
    % - 将拥挤度最高的个体（ Rank(1) ）标记为需要删除
    Del = false(1,size(PopObjLast,1));
    %如果K为负，说明所有的元素都需要保留，不执行循环。
    while sum(Del) < K
        %找到值为0/false的元素索引：未被标记为删除的最大前沿个体的索引
        Remain   = find(~Del);
        %size(PopObjLast,1)+1:end ：所有非最大前沿个体对应的列（因为 PopObjAll 包含最大前沿和非最大前沿个体）
        %Distance(Remain,[Remain,size(PopObjLast,1)+1:end])找出未删除的最大前沿个体与未删除的最大前沿个体以及其他前沿中个体的距离。
        %sort(..., 2) ：对每一行进行排序（按距离从小到大）
        Temp     = sort(Distance(Remain,[Remain,size(PopObjLast,1)+1:end]),2);
        [~,Rank] = sortrows(Temp);
        %选择距离最小的个体（拥挤度最高）进行删除
        Del(Remain(Rank(1))) = true;
    end
    % 该代码实现了一种基于拥挤距离的选择策略：
    % - 对于每个剩余的最大前沿个体，计算其与其他个体的距离
    % - 对这些距离进行排序，得到每个个体的距离分布
    % - 通过 sortrows(Temp) 选择距离最小的个体（拥挤度最高）进行删除
    % - 这样可以保持种群的多样性，避免算法收敛到局部最优
end