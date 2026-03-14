classdef Block_HHO_Exploration < BLOCK
% HHO Exploration Phase

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
        %% Default settings of the block
        function obj = Block_HHO_Exploration()
            % No parameters to learn - using fixed values from paper
        end
        %% Main procedure of the block
        function Main(obj, Problem, Precursors, Ratio)
            % Gather input population
            Population = obj.Gather(Problem, Precursors, Ratio, 1, 1);
            PopDec = Population.decs;
            [N, D] = size(PopDec);
            
            % Get the best solution (Rabbit/prey) from predecessor
            % Assuming the first predecessor is the population block
            Rabbit_dec = Precursors(1).bestDec;
            PopMean = Precursors(1).meanDec;
            
            % Calculate escape energy coefficient
            %E1 = 2 * (1 - Problem.FE / Problem.maxFE);
            
            % Initialize offspring
            OffDec = zeros(N, D);
            
            for i = 1:N
                % Calculate escape energy for each hawk
                %E0 = 2 * rand() - 1;
                %Escaping_Energy = E1 * E0;          
                
                %if abs(Escaping_Energy) >= 1，不计算逃逸能力，默认都为适应值较差的个体。
                % Exploration phase - two strategies (q = 0.5 from paper)
                q = rand();
                rand_Hawk_index = randi(N);
                X_rand = PopDec(rand_Hawk_index, :);                    
                if q < 0.5
                    % Strategy 1: Position based on random hawk
                    OffDec(i,:) = X_rand - rand() * abs(X_rand - 2*rand()*PopDec(i,:));
                else
                    % Strategy 2: Position based on rabbit and population mean
                    OffDec(i,:) = (Rabbit_dec - PopMean) - rand() * ((Problem.upper - Problem.lower) * rand() + Problem.lower);
                end
                %else
                % If not in exploration phase, keep current position
                % OffDec(i,:) = PopDec(i,:);
                %end
            end            
            % Boundary check
            OffDec = max(min(OffDec, repmat(Problem.upper, N, 1)), repmat(Problem.lower, N, 1));            
            obj.output = OffDec;
        end
    end
end
