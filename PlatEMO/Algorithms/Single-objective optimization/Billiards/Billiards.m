classdef Billiards < ALGORITHM
% <2026> <single> <real> <large/none> <constrained/none>
% Billiards Optimization Algorithm
% beta --- 1.5 --- Levy flight parameter

%------------------------------- Reference --------------------------------
% Billiards-inspired optimization algorithm combining particle movement
% with boundary reflection, GQI interpolation, and HHO-based exploration/exploitation
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
            Velocity = unifrnd(-1, 1, Problem.N, Problem.D);
            
            %% Initialize billiard particles (20% of population)
            nBilliard = ceil(0.2 * Problem.N);
            
            % Store three positions for billiard particles: prev2, prev1, current
            BilliardPos = zeros(nBilliard, Problem.D, 3);
            for i = 1:nBilliard
                BilliardPos(i,:,1) = Population(i).dec;
                BilliardPos(i,:,2) = Population(i).dec;
                BilliardPos(i,:,3) = Population(i).dec;
            end
            BilliardFit = zeros(nBilliard, 3);
            for i = 1:nBilliard
                BilliardFit(i,:) = FitnessSingle(Population(i));
            end
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                PopDec = Population.decs;
                PopFit = FitnessSingle(Population);
                NewDec = zeros(Problem.N, Problem.D);
                NewVel = Velocity;
                
                %% 1. Billiard particles (20%) - Movement with boundary reflection and GQI
                for i = 1:nBilliard
                    % Random step size (PSO/CSO style)
                    w = 0.9 - 0.5 * Problem.FE / Problem.maxFE;
                    stepSize = w * rand();
                    
                    % Update position with velocity
                    NewDec(i,:) = PopDec(i,:) + stepSize * Velocity(i,:);
                    
                    % Boundary reflection (billiard physics)
                    for j = 1:Problem.D
                        if NewDec(i,j) < Problem.lower(j)
                            NewDec(i,j) = Problem.lower(j) + (Problem.lower(j) - NewDec(i,j));
                            NewVel(i,j) = -Velocity(i,j);
                            if NewDec(i,j) > Problem.upper(j)
                                NewDec(i,j) = Problem.lower(j);
                            end
                        elseif NewDec(i,j) > Problem.upper(j)
                            NewDec(i,j) = Problem.upper(j) - (NewDec(i,j) - Problem.upper(j));
                            NewVel(i,j) = -Velocity(i,j);
                            if NewDec(i,j) < Problem.lower(j)
                                NewDec(i,j) = Problem.upper(j);
                            end
                        end
                    end
                    
                    % Evaluate new position
                    TempPop = Problem.Evaluation(NewDec(i,:));
                    NewFit = FitnessSingle(TempPop);
                    
                    % Update position history
                    BilliardPos(i,:,1) = BilliardPos(i,:,2);
                    BilliardPos(i,:,2) = BilliardPos(i,:,3);
                    BilliardPos(i,:,3) = NewDec(i,:);
                    BilliardFit(i,1) = BilliardFit(i,2);
                    BilliardFit(i,2) = BilliardFit(i,3);
                    BilliardFit(i,3) = NewFit;
                    
                    % Apply GQI using three historical positions
                    NewDec(i,:) = GQI(BilliardPos(i,:,1), BilliardPos(i,:,2), BilliardPos(i,:,3), ...
                                      BilliardFit(i,1), BilliardFit(i,2), BilliardFit(i,3), ...
                                      Problem.lower, Problem.upper);
                end
                
                %% 2. Other particles (80%) - HHO exploration/exploitation with probability
                % Find best position from billiard particles
                [~, bestBilliardIdx] = min(BilliardFit(:,3));
                BestBilliardPos = BilliardPos(bestBilliardIdx,:,3);
                
                % Calculate escape energy coefficient
                E1 = 2 * (1 - Problem.FE / Problem.maxFE);
                
                for i = nBilliard+1:Problem.N
                    % Calculate escape energy
                    E0 = 2 * rand() - 1;
                    Escaping_Energy = E1 * E0;
                    
                    if abs(Escaping_Energy) >= 1
                        %% Exploration phase - use best billiard position as Rabbit
                        q = rand();
                        rand_Hawk_index = randi(Problem.N);
                        X_rand = PopDec(rand_Hawk_index, :);
                        
                        if q < 0.5
                            % Strategy 1
                            NewDec(i,:) = X_rand - rand() * abs(X_rand - 2*rand()*PopDec(i,:));
                        else
                            % Strategy 2 - use best billiard position
                            NewDec(i,:) = (BestBilliardPos - mean(PopDec)) - rand() * ((Problem.upper - Problem.lower) * rand() + Problem.lower);
                        end
                        
                    else
                        %% Exploitation phase - use best billiard position as Rabbit
                        Sp = rand();
                        
                        if Sp >= 0.5 && abs(Escaping_Energy) < 0.5
                            %% Hard besiege
                            NewDec(i,:) = BestBilliardPos - Escaping_Energy * abs(BestBilliardPos - PopDec(i,:));
                            
                        elseif Sp >= 0.5 && abs(Escaping_Energy) >= 0.5
                            %% Soft besiege
                            Jump_strength = 2 * (1 - rand());
                            NewDec(i,:) = (BestBilliardPos - PopDec(i,:)) - Escaping_Energy * abs(Jump_strength * BestBilliardPos - PopDec(i,:));
                            
                        elseif Sp < 0.5 && abs(Escaping_Energy) >= 0.5
                            %% Soft besiege with progressive rapid dives
                            Jump_strength = 2 * (1 - rand());
                            X1 = BestBilliardPos - Escaping_Energy * abs(Jump_strength * BestBilliardPos - PopDec(i,:));
                            X1 = max(min(X1, Problem.upper), Problem.lower);
                            Temp1 = Problem.Evaluation(X1);
                            
                            if FitnessSingle(Temp1) < PopFit(i)
                                NewDec(i,:) = X1;
                            else
                                X2 = BestBilliardPos - Escaping_Energy * abs(Jump_strength * BestBilliardPos - PopDec(i,:)) + ...
                                     rand(1,Problem.D) .* LevyFlight(Problem.D, beta);
                                X2 = max(min(X2, Problem.upper), Problem.lower);
                                Temp2 = Problem.Evaluation(X2);
                                
                                if FitnessSingle(Temp2) < PopFit(i)
                                    NewDec(i,:) = X2;
                                else
                                    NewDec(i,:) = PopDec(i,:);
                                end
                            end
                            
                        else
                            %% Hard besiege with progressive rapid dives
                            Jump_strength = 2 * (1 - rand());
                            X1 = BestBilliardPos - Escaping_Energy * abs(Jump_strength * BestBilliardPos - mean(PopDec));
                            X1 = max(min(X1, Problem.upper), Problem.lower);
                            Temp1 = Problem.Evaluation(X1);
                            
                            if FitnessSingle(Temp1) < PopFit(i)
                                NewDec(i,:) = X1;
                            else
                                X2 = BestBilliardPos - Escaping_Energy * abs(Jump_strength * BestBilliardPos - mean(PopDec)) + ...
                                     rand(1,Problem.D) .* LevyFlight(Problem.D, beta);
                                X2 = max(min(X2, Problem.upper), Problem.lower);
                                Temp2 = Problem.Evaluation(X2);
                                
                                if FitnessSingle(Temp2) < PopFit(i)
                                    NewDec(i,:) = X2;
                                else
                                    NewDec(i,:) = PopDec(i,:);
                                end
                            end
                        end
                    end
                end
                
                %% Boundary control for all particles
                NewDec = max(min(NewDec, Problem.upper), Problem.lower);
                
                %% Evaluate offspring
                Offspring = Problem.Evaluation(NewDec);
                
                %% Selection
                replace = FitnessSingle(Offspring) < PopFit;
                Population(replace) = Offspring(replace);
                
                %% Update velocity for billiard particles
                Velocity(1:nBilliard,:) = NewVel(1:nBilliard,:);
                
                %% Update velocity for other particles
                for i = nBilliard+1:Problem.N
                    if replace(i)
                        Velocity(i,:) = 0.5 * Velocity(i,:) + rand(1,Problem.D) .* (NewDec(i,:) - PopDec(i,:));
                    end
                end
            end
        end
    end
end

function levy = LevyFlight(d, beta)
% Generate Levy flight random walk for enhanced exploration
    sigma = (gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    u = randn(1,d) * sigma;
    v = randn(1,d);
    step = u ./ abs(v).^(1/beta);
    levy = step;
end
