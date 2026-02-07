function index = TournamentSelection(K,N,varargin)

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    if K > 1
        %将输入的每个评估指标重塑为列向量，确保数据格式一致，调用形式为：P =
        %TournamentSelection(K,N,fitness1,fitness2,...)
        %此时varargin为同一个个体的多个适应度值。
        varargin = cellfun(@(S)reshape(S,[],1),varargin,'UniformOutput',false);
        %基于第一列中的元素按升序对矩阵行进行排序。当第一列包含重复的元素时，sortrows会根据下一列中的值进行排序，。。。
        %rank存储的是原来的元素排序后的索引。如rank =[6 4 10 2 8 5 1 7 9 3]表示排第一的是原来的索引为6的元素     
        [~,rank] = sortrows([varargin{:}]);
        %对索引再次排序，得到每个个体的排名（rank值越小表示个体越好）,如rank =[7 4 10  2  6  1  8  5  9 3]，得到未排序的元素排序后的位置。
        [~,rank] = sort(rank);
        %- 随机生成K×N个索引，作为每轮锦标赛的候选者，其中K是每轮锦标赛的候选人数，N是锦标赛轮数
        Parents  = randi(length(varargin{1}),K,N);
        %在每轮锦标赛中选择排名最好（rank值最小）的个体：rank(Parents) ：将 Parents 矩阵中的每个元素作为索引，从 rank 数组中获取对应的值，形成一个新的K×N矩阵
        %min(...,[],1) ：沿着矩阵的第1维度（列方向）取最小值，即每列取一个最小值;如 Parents  =randi(10,3,6);
        % rank(Parents)：[10  4  1 6 9 2;5 10  6  3  8  4;4 1 5 1 10 10]
        % [~,best] ：返回每一列最小值的位置索引（行索引），忽略最小值本身
        [~,best] = min(rank(Parents),[],1);
        index    = Parents(best+(0:N-1)*K);
    else
        index = randi(length(varargin{1}),1,N);
    end
end