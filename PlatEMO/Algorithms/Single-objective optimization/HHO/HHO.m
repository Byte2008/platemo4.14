classdef HHO < ALGORITHM
% <2019> <single> <real/integer> <large/none> <constrained/none>
% Harris Hawks Optimization
% beta --- 1.5 --- Levy flight parameter

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
        function main(Algorithm,Problem)
            %% Parameter setting
            beta = Algorithm.ParameterSet(1.5);
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Find the best rabbit (prey)
            [~,best] = min(FitnessSingle(Population));
            Rabbit = Population(best);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                %% Calculate escape energy coefficient
                E1 = 2 * (1 - Problem.FE / Problem.maxFE);
                
                %% Update population
                PopDec = Population.decs;
                [N,D] = size(PopDec);
                OffDec = zeros(N,D);
                
                for i = 1:N
                    %% Calculate escape energy
                    E0 = 2 * rand() - 1;
                    Escaping_Energy = E1 * E0;
                    
                    if abs(Escaping_Energy) >= 1
                        %% Exploration phase - two strategies
                        q = rand();
                        rand_Hawk_index = randi(N);
                        X_rand = PopDec(rand_Hawk_index, :);
                        
                        if q < 0.5
                            % Strategy 1
                            OffDec(i,:) = X_rand - rand() * abs(X_rand - 2*rand()*PopDec(i,:));
                        else
                            % Strategy 2
                            OffDec(i,:) = (Rabbit.dec - mean(PopDec)) - rand() * ((Problem.upper - Problem.lower) * rand() + Problem.lower);
                        end
                        
                    else
                        %% Exploitation phase - four strategies
                        Sp = rand();
                        
                        if Sp >= 0.5 && abs(Escaping_Energy) < 0.5
                            %% Hard besiege
                            OffDec(i,:) = Rabbit.dec - Escaping_Energy * abs(Rabbit.dec - PopDec(i,:));
                            
                        elseif Sp >= 0.5 && abs(Escaping_Energy) >= 0.5
                            %% Soft besiege
                            Jump_strength = 2 * (1 - rand());
                            OffDec(i,:) = (Rabbit.dec - PopDec(i,:)) - Escaping_Energy * abs(Jump_strength * Rabbit.dec - PopDec(i,:));
                            
                        elseif Sp < 0.5 && abs(Escaping_Energy) >= 0.5
                            %% Soft besiege with progressive rapid dives
                            Jump_strength = 2 * (1 - rand());
                            X1 = Rabbit.dec - Escaping_Energy * abs(Jump_strength * Rabbit.dec - PopDec(i,:));
                            
                            % Boundary check for X1
                            X1 = max(min(X1, Problem.upper), Problem.lower);
                            
                            % Evaluate X1
                            Temp1 = Problem.Evaluation(X1);
                            
                            if FitnessSingle(Temp1) < FitnessSingle(Population(i))
                                OffDec(i,:) = X1;
                            else
                                X2 = Rabbit.dec - Escaping_Energy * abs(Jump_strength * Rabbit.dec - PopDec(i,:)) + ...
                                     rand(1,D) .* LevyFlight(D, beta);
                                % Boundary check for X2
                                X2 = max(min(X2, Problem.upper), Problem.lower);
                                
                                % Evaluate X2
                                Temp2 = Problem.Evaluation(X2);
                                
                                if FitnessSingle(Temp2) < FitnessSingle(Population(i))
                                    OffDec(i,:) = X2;
                                else
                                    OffDec(i,:) = PopDec(i,:);
                                end
                            end
                            
                        else
                            %% Hard besiege with progressive rapid dives
                            Jump_strength = 2 * (1 - rand());
                            X1 = Rabbit.dec - Escaping_Energy * abs(Jump_strength * Rabbit.dec - mean(PopDec));
                            
                            % Boundary check for X1
                            X1 = max(min(X1, Problem.upper), Problem.lower);
                            
                            % Evaluate X1
                            Temp1 = Problem.Evaluation(X1);
                            
                            if FitnessSingle(Temp1) < FitnessSingle(Population(i))
                                OffDec(i,:) = X1;
                            else
                                X2 = Rabbit.dec - Escaping_Energy * abs(Jump_strength * Rabbit.dec - mean(PopDec)) + ...
                                     rand(1,D) .* LevyFlight(D, beta);
                                % Boundary check for X2
                                X2 = max(min(X2, Problem.upper), Problem.lower);
                                
                                % Evaluate X2
                                Temp2 = Problem.Evaluation(X2);
                                
                                if FitnessSingle(Temp2) < FitnessSingle(Population(i))
                                    OffDec(i,:) = X2;
                                else
                                    OffDec(i,:) = PopDec(i,:);
                                end
                            end
                        end
                    end
                end
                
                %% Boundary check
                OffDec = max(min(OffDec, repmat(Problem.upper, N, 1)), repmat(Problem.lower, N, 1));
                
                %% Evaluate offspring
                Offspring = Problem.Evaluation(OffDec);
                
                %% Update population
                replace = FitnessSingle(Offspring) < FitnessSingle(Population);
                Population(replace) = Offspring(replace);
                
                %% Update the best rabbit
                [~,best] = min(FitnessSingle(Population));
                Rabbit = Population(best);
            end
        end
    end
end

function levy = LevyFlight(d, beta)
%LevyFlight - Generate Levy flight random walk
%
%   This function generates Levy flight steps for enhanced exploration

    sigma = (gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    u = randn(1,d) * sigma;
    v = randn(1,d);
    step = u ./ abs(v).^(1/beta);
    levy = step;
end