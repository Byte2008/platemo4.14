classdef CSO_OOA < ALGORITHM
% <2025> <single> <real/integer> <large/none> <constrained/none>
% Competitive Swarm Optimizer with Adaptive Strategy Pool
% vr --- 3 --- Velocity range parameter
% ll --- 0.8 --- Threshold parameter

%------------------------------- Reference --------------------------------
% R. Cheng and Y. Jin. A competitive swarm optimizer for large scale
% optimization. IEEE Transactions on Cybernetics, 2014, 45(2): 191-204.
% M. Dehghani, Z. Montazeri, E. Trojovská, and P. Trojovský, Octopus
% Optimization Algorithm: A novel bio-inspired metaheuristic algorithm for
% solving optimization problems, Biomimetics, 2025, 10(1): 33.
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
            vr = Algorithm.ParameterSet(3);
            ll = Algorithm.ParameterSet(0.8);
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Find global best
            [~, bestIdx] = min(FitnessSingle(Population));
            GlobalBest = Population(bestIdx);
            
            %% Initialize strategy pools and their success rates
            % Exploration strategies: OOA, GWO, HHO, DE
            ExploreStrategies = {'OOA', 'GWO', 'HHO', 'DE'};
            ExploreSuccessRate = ones(1, length(ExploreStrategies)) / length(ExploreStrategies);
            
            % Exploitation strategies: OOA, GWO, HHO
            ExploitStrategies = {'OOA', 'GWO', 'HHO'};
            ExploitSuccessRate = ones(1, length(ExploitStrategies)) / length(ExploitStrategies);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                t = Problem.FE / Problem.maxFE;
                ld = vr * (1 - t);
                
                % Determine the losers and winners
                rank    = randperm(Problem.N);
                loser   = rank(1:end/2);
                winner  = rank(end/2+1:end);
                replace = FitnessSingle(Population(loser)) < FitnessSingle(Population(winner));
                temp            = loser(replace);
                loser(replace)  = winner(replace);
                winner(replace) = temp;
                
                % Get loser and winner decisions
                LoserDec  = Population(loser).decs;
                WinnerDec = Population(winner).decs;
                
                % Store old fitness for strategy evaluation
                OldLoserFit = FitnessSingle(Population(loser));
                OldWinnerFit = FitnessSingle(Population(winner));
                
                % Prepare matrices for computation
                GlobalBestMat = repmat(GlobalBest.dec, Problem.N/2, 1);
                WinnerMeanMat = repmat(mean(WinnerDec, 1), Problem.N/2, 1);
                PopMeanMat = repmat(mean(Population.decs, 1), Problem.N/2, 1);
                
                % Generate one random value per individual
                trans = (2 * ld) * rand(Problem.N/2, 1) - ld;
                
                % Exploitation phase (abs(trans) < ll): learn from global best or winner center
                exploit_mask = abs(trans) < ll;
                
                % Exploration phase (abs(trans) >= ll): learn from winner with Levy flight
                explore_mask = ~exploit_mask;
                
                % Initialize new decisions
                NewLoserDec = LoserDec;
                NewWinnerDec = WinnerDec;
                
                %% Update Losers with Exploration Strategies
                if any(explore_mask)
                    explore_idx = find(explore_mask);
                    for i = explore_idx'
                        % Select exploration strategy based on success rate
                        strategyIdx = SelectStrategy(ExploreSuccessRate);
                        strategy = ExploreStrategies{strategyIdx};
                        
                        % Apply selected exploration strategy
                        NewLoserDec(i, :) = ApplyExploreStrategy(strategy, LoserDec(i, :), ...
                            WinnerDec(i, :), GlobalBest.dec, PopMeanMat(i, :), ...
                            Problem.upper, Problem.lower, Problem.D, ld);
                    end
                end
                
                %% Update Winners with Exploitation Strategies
                for i = 1:Problem.N/2
                    % Select exploitation strategy based on success rate
                    strategyIdx = SelectStrategy(ExploitSuccessRate);
                    strategy = ExploitStrategies{strategyIdx};
                    
                    % Apply selected exploitation strategy
                    NewWinnerDec(i, :) = ApplyExploitStrategy(strategy, WinnerDec(i, :), ...
                        GlobalBest.dec, WinnerMeanMat(i, :), PopMeanMat(i, :), ...
                        Problem.upper, Problem.lower, Problem.D, t);
                end
                
                % Boundary check
                NewLoserDec = max(min(NewLoserDec, repmat(Problem.upper, Problem.N/2, 1)), ...
                                  repmat(Problem.lower, Problem.N/2, 1));
                NewWinnerDec = max(min(NewWinnerDec, repmat(Problem.upper, Problem.N/2, 1)), ...
                                   repmat(Problem.lower, Problem.N/2, 1));
                
                % Evaluate and update losers
                NewLoserPop = Problem.Evaluation(NewLoserDec);
                NewLoserFit = FitnessSingle(NewLoserPop);
                
                % Update strategy success rates for losers
                for i = 1:length(explore_mask)
                    if explore_mask(i)
                        strategyIdx = SelectStrategy(ExploreSuccessRate);
                        if NewLoserFit(i) < OldLoserFit(i)
                            ExploreSuccessRate(strategyIdx) = ExploreSuccessRate(strategyIdx) * 1.1;
                        else
                            ExploreSuccessRate(strategyIdx) = ExploreSuccessRate(strategyIdx) * 0.9;
                        end
                    end
                end
                ExploreSuccessRate = ExploreSuccessRate / sum(ExploreSuccessRate);
                
                Population(loser) = NewLoserPop;
                
                % Evaluate and update winners
                NewWinnerPop = Problem.Evaluation(NewWinnerDec);
                NewWinnerFit = FitnessSingle(NewWinnerPop);
                
                % Update strategy success rates for winners
                for i = 1:Problem.N/2
                    strategyIdx = SelectStrategy(ExploitSuccessRate);
                    if NewWinnerFit(i) < OldWinnerFit(i)
                        ExploitSuccessRate(strategyIdx) = ExploitSuccessRate(strategyIdx) * 1.1;
                    else
                        ExploitSuccessRate(strategyIdx) = ExploitSuccessRate(strategyIdx) * 0.9;
                    end
                end
                ExploitSuccessRate = ExploitSuccessRate / sum(ExploitSuccessRate);
                
                Population(winner) = NewWinnerPop;
                
                % Update global best
                [~, bestIdx] = min(FitnessSingle(Population));
                if FitnessSingle(Population(bestIdx)) < FitnessSingle(GlobalBest)
                    GlobalBest = Population(bestIdx);
                end
            end
        end
    end
end

%% Exploration Strategy Functions
function NewDec = ApplyExploreStrategy(strategy, CurrentDec, WinnerDec, GlobalBest, PopMean, upper, lower, D, ld)
    switch strategy
        case 'OOA'
            % OOA exploration: learn from winner with Levy flight
            NewDec = CurrentDec + rand() * (WinnerDec - CurrentDec) .* Levy(1, D);
            
        case 'GWO'
            % GWO exploration: random position with weighted difference
            a = 2 * ld;
            r1 = 2 * rand(1, D);
            r2 = 2 * rand(1, D);
            A = 2 * a .* r1 - a;
            C = 2 * r2;
            D_wolf = abs(C .* WinnerDec - CurrentDec);
            NewDec = WinnerDec - A .* D_wolf;
            
        case 'HHO'
            % HHO exploration: random hawk strategy
            if rand() < 0.5
                % Strategy 1: random position
                X_rand = lower + rand(1, D) .* (upper - lower);
                NewDec = X_rand - rand(1, D) .* abs(X_rand - 2 * rand(1, D) .* CurrentDec);
            else
                % Strategy 2: population-based
                NewDec = (GlobalBest - PopMean) - rand(1, D) .* ((upper - lower) .* rand(1, D) + lower);
            end
            
        case 'DE'
            % DE exploration: differential mutation
            r1 = lower + rand(1, D) .* (upper - lower);
            r2 = lower + rand(1, D) .* (upper - lower);
            F = 0.5;
            NewDec = r1 + F .* (r2 - CurrentDec);
            
        otherwise
            NewDec = CurrentDec;
    end
end

%% Exploitation Strategy Functions
function NewDec = ApplyExploitStrategy(strategy, CurrentDec, GlobalBest, WinnerMean, PopMean, upper, lower, D, t)
    switch strategy
        case 'OOA'
            % OOA exploitation: move towards global best or winner center
            if rand() < 0.5
                target = GlobalBest;
            else
                target = WinnerMean;
            end
            NewDec = CurrentDec + rand() * (target - CurrentDec) .* Levy(1, D);
            
        case 'GWO'
            % GWO exploitation: converge towards best solutions
            a = 2 * (1 - t);
            r1 = 2 * rand(1, D);
            r2 = 2 * rand(1, D);
            A = 2 * a .* r1 - a;
            C = 2 * r2;
            
            % Combine global best and winner mean
            D_alpha = abs(C .* GlobalBest - CurrentDec);
            D_beta = abs(C .* WinnerMean - CurrentDec);
            X1 = GlobalBest - A .* D_alpha;
            X2 = WinnerMean - A .* D_beta;
            NewDec = (X1 + X2) / 2;
            
        case 'HHO'
            % HHO exploitation: hard besiege towards global best
            E = 2 * (1 - t);
            E0 = 2 * rand() - 1;
            Escaping_Energy = E * E0;
            
            if abs(Escaping_Energy) < 0.5
                % Hard besiege
                NewDec = GlobalBest - Escaping_Energy * abs(GlobalBest - CurrentDec);
            else
                % Soft besiege
                Jump_strength = 2 * (1 - rand());
                NewDec = (GlobalBest - CurrentDec) - Escaping_Energy * abs(Jump_strength * GlobalBest - CurrentDec);
            end
            
        otherwise
            NewDec = CurrentDec;
    end
end

%% Strategy Selection Function
function strategyIdx = SelectStrategy(successRate)
    % Roulette wheel selection based on success rates
    cumulativeRate = cumsum(successRate);
    r = rand();
    strategyIdx = find(cumulativeRate >= r, 1, 'first');
    if isempty(strategyIdx)
        strategyIdx = length(successRate);
    end
end

%% Levy Flight Function
function L = Levy(n, d)
    % Levy flight for n individuals with d dimensions
    beta = 1.5;
    sigma = (gamma(1+beta) * sin(pi*beta/2) / (gamma((1+beta)/2) * beta * 2^((beta-1)/2)))^(1/beta);
    u = randn(n, d) * sigma;
    v = randn(n, d);
    step = u ./ abs(v).^(1/beta);
    L = step;
end
