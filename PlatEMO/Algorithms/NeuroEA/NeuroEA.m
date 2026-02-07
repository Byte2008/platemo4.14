classdef NeuroEA < ALGORITHM
% Evolutionary algorithm with neural architecture

%------------------------------- Reference --------------------------------
% Y. Tian, X. Qi, S. Yang, C. He, K. C. Tan, Y. Jin, and X. Zhang. A
% universal framework for automatically generating single- and
% multi-objective evolutionary algorithms. IEEE Transactions on
% Evolutionary Computation, 2025.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

%  Blocks = [Block_Population, Block_Tournament(200,10),Block_Crossover(2,5),Block_Mutation(5),Block_Selection(100)];
%  Graph=[0 1 0 0 1;0 0 1 0 0;0 0 0 1 0 ;0 0 0 0 1;1 0 0 0 0];
%  platemo('algorithm',{@NeuroEA,Blocks,Graph},'problem',@SOP_F1);


    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            Blocks = [Block_Population, Block_Tournament(200,10),Block_Crossover(2,5),Block_Mutation(5),Block_Selection(100)];
            Graph=[0 1 0 0 1;0 0 1 0 0;0 0 0 1 0 ;0 0 0 0 1;1 0 0 0 0];
            [Blocks,Graph] = Algorithm.ParameterSet(Blocks,Graph);
            
            %% Generate random population,isPop为逻辑数组，如[1 0 0 0 0]
            isPop = arrayfun(@(s)isa(s,'Block_Population'),Blocks(:)');
            Blocks(isPop).Initialization(Problem.Initialization());

            %%NotTerminated把Blocks(1).output作为当前执行的结果，计算程序执行时间，保存中间结果，调用指定输出函数等，如果算法应该终止则返回true.
            while Algorithm.NotTerminated(Blocks(1).output)
                activated = false(1,length(Blocks));

                %如果 A 为向量，当所有元素为非零时，all(A) 返回逻辑 1 (true)，当一个或多个元素为零时，返回逻辑 0 (false)。如果 A 为非空矩阵，all(A) 将 A 的各列视为向量，返回包含逻辑 1 和 0 的行向量。
                %外层循环条件 ： while
                %~all(activated(isPop))当所有种群块都未被激活时，继续循环;一旦所有种群块都被激活，内层循环结束.(只要有一个种群块未激活，all(activated(isPop))为0，~all(activated(isPop))为1.
                while ~all(activated(isPop))

                    %for i = find(~activated)- 遍历所有未被激活的块，find(~activated)返回所有未激活块的索引
                    for i = find(~activated)
                        
                        %logical(Graph(:,i)) 获取块 i 的所有前驱块索引;判断所有前驱块要么已激活，要么是种群块
                        if all(activated(logical(Graph(:,i)))|isPop(logical(Graph(:,i))))
                            Blocks(i).Main(Problem,Blocks(logical(Graph(:,i))),Graph(:,i));
                            activated(i) = true;
                        end
                    end
                end
            end
        end
    end
end