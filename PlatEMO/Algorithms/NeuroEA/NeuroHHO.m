classdef NeuroHHO < ALGORITHM
% <2026> <single> <real/integer> <large/none> <constrained/none>
% Harris Hawks Optimization algorithm based on NeuroEA framework

%------------------------------- Reference --------------------------------
% A. A. Heidari, S. Mirjalili, H. Faris, I. Aljarah, M. Mafarja, and H. Chen,
% Harris hawks optimization: Algorithm and applications, Future Generation 
% Computer Systems, vol. 97, pp. 849-872, 2019.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    methods
        function main(Algorithm, Problem)
            %% Parameter setting
            % Define blocks for HHO algorithm
            % Block 1: Population - Initialize and maintain population
            % Block 2: HHO - Complete HHO operator (exploration + exploitation + selection)
            Blocks = [Block_Population(),...
                      Block_HHO(1.5)];
            
            % Define the graph structure (adjacency matrix)
            % Population -> HHO -> Population (simple feedback loop)
            Graph = [0  1
                     1  0];
            
            [Blocks, Graph] = Algorithm.ParameterSet(Blocks, Graph);
            
            %% Generate random population
            isPop = arrayfun(@(s)isa(s,'Block_Population'), Blocks(:)');
            Blocks(isPop).Initialization(Problem.Initialization());

            %% Optimization
            while Algorithm.NotTerminated(Blocks(1).output)
                activated = false(1, length(Blocks));
                
                while ~all(activated(isPop))
                    for i = find(~activated)
                        if all(activated(logical(Graph(:,i))) | isPop(logical(Graph(:,i))))
                            Blocks(i).Main(Problem, Blocks(logical(Graph(:,i))), Graph(:,i));
                            activated(i) = true;
                        end
                    end
                end
            end
        end
    end
end
