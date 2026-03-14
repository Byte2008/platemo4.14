classdef NeuroEA_trained2 < NeuroEA % < ALGORITHM

    methods
        function obj = NeuroEA_trained2(varargin)
            obj    = obj@NeuroEA(varargin{:});
            Blocks = [Block_Population(),...
                      Block_Tournament(100,10),...
                      Block_Tournament(100,10),...
                      Block_Tournament(100,10),...
                      Block_Exchange(3),...
                      Block_Exchange(3),...
                      Block_Exchange(3),...
                      Block_Exchange(3),...
                      Block_Crossover(2,5),...
                      Block_Mutation(5),...
                      Block_Selection(100)];
            Graph = [0           1           1           1           0           0           0           0           0           0           0
                     0           0           0           0        0.25           0        0.25        0.25           0           0           0
                     0           0           0           0        0.25        0.25        0.25        0.25           0           0           0
                     0           0           0           0        0.25        0.25        0.25        0.25           0           0           0
                     0           0           0           0           0           0           0           0           1           0           0
                     0        0.25           0           0           0           0           0           0           1           0           0
                     0           0           0           0           0           0           0           0           1           0           0
                     0           0           0           0           0           0           0           0           1           0           0
                     0           0           0           0           0           0           0           0           0           1           0
                     0           0           0           0           0           0           0           0           0           0           1
                     1           0           0           0           0           0           0           0           0           0           0];

            load('NeuroEA_trained2.mat','Blocks','Graph');

            obj.parameter = {Blocks,Graph};
        end
    end
end
