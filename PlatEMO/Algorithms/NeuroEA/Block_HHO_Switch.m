classdef Block_HHO_Switch < BLOCK
% HHO Switch - Sort population by fitness (ascending order)
% This block sorts the population from best to worst fitness

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
        %% Main procedure of the block
        function Main(obj, Problem, Precursors, Ratio)
            % Gather input population from predecessors
            Population = obj.Gather(Problem, Precursors, Ratio, 1, 1);
            
            % Sort population by fitness in ascending order (best to worst)
            [~, rank] = sort(FitnessSingle(Population));
            obj.output = Population(rank);
            
            % Get best fitness, best decision vector and mean decision vector from predecessor
            % Assuming the first predecessor is Block_Population
            if ~isempty(Precursors)
                obj.bestFitness = Precursors(1).bestFitness;
                obj.bestDec = Precursors(1).bestDec;
                obj.meanDec = Precursors(1).meanDec;
            end
        end
    end
end
