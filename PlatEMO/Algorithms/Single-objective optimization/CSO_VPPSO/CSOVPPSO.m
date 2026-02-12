classdef CSOVPPSO < ALGORITHM
% <2026> <single> <real/integer> <large/none> <constrained/none>
% CSO-VPPSO Hybrid Algorithm
% phi --- 0.1 --- Social factor from CSO
% c1  --- 1.5 --- Cognitive coefficient from VPPSO
% c2  --- 1.2 --- Social coefficient from VPPSO

%------------------------------- Reference --------------------------------
% Hybrid algorithm combining CSO competition mechanism for losers, 
% VPPSO update strategy for winners, and elitist selection
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
            [phi,c1,c2] = Algorithm.ParameterSet(0.1,1.5,1.2);
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Initialize personal best for winners (using VPPSO mechanism)
            Pbest = Population;
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                %% Step 1: CSO Competition Mechanism - Determine losers and winners
                rank    = randperm(Problem.N);
                loser   = rank(1:end/2);
                winner  = rank(end/2+1:end);
                replace = FitnessSingle(Population(loser)) < FitnessSingle(Population(winner));
                temp            = loser(replace);
                loser(replace)  = winner(replace);
                winner(replace) = temp;
                
                %% Step 2: Update losers using CSO mechanism
                OffspringLosers = UpdateLosersCSO(Problem,Population(loser),Population(winner),Population,phi);
                
                %% Step 3: Update winners using VPPSO mechanism
                % Calculate dynamic inertia weight
                ww = exp(-(2.5*Problem.FE/Problem.maxFE)^2.5);
                
                % Update personal best for winners
                replace_pbest = FitnessSingle(Pbest(winner)) > FitnessSingle(Population(winner));
                Pbest(winner(replace_pbest)) = Population(winner(replace_pbest));
                
                % Find global best (Rabbit)
                [~,best_idx] = min(FitnessSingle(Population));
                Gbest = Population(best_idx);
                
                % Update winners using VPPSO mechanism
                OffspringWinners = UpdateWinnersVPPSO(Problem,Population(winner),Pbest(winner),Gbest,c1,c2,ww);
                
                %% Step 4: Selection - Choose best individuals from current and new population
                % Combine current population with offspring
                CombinedPopulation = [Population, OffspringLosers, OffspringWinners];
                FitnessCombined = FitnessSingle(CombinedPopulation);
                
                % Select best N individuals
                [~, BestIndices] = sort(FitnessCombined);
                Population = CombinedPopulation(BestIndices(1:Problem.N));
                
                %% Update personal best based on selected population
                replace_pbest = FitnessSingle(Pbest) > FitnessSingle(Population);
                Pbest(replace_pbest) = Population(replace_pbest);
            end
        end
    end
end

function Offspring = UpdateLosersCSO(Problem,Losers,Winners,Population,phi)
%UpdateLosersCSO - Update losers using CSO mechanism
%
%   This function implements the CSO velocity update mechanism for losers
%   learning from winners

    LoserDec = Losers.decs;
    WinnerDec = Winners.decs;
    [N,D] = size(LoserDec);
    
    %% Get current velocity
    LoserVel = Losers.adds(zeros(N,D));
    
    %% CSO velocity update formula
    R1 = rand(N,D);
    R2 = rand(N,D);
    R3 = rand(N,D);
    
    % Update velocity: v = r1*v + r2*(winner-loser) + phi*r3*(mean-loser)
    LoserVel = R1.*LoserVel + R2.*(WinnerDec-LoserDec) + ...
               phi.*R3.*(repmat(mean(Population.decs,1),N,1)-LoserDec);
    
    %% Update position
    OffDec = LoserDec + LoserVel;
    
    %% Boundary check
    OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
    
    %% Evaluate offspring
    Offspring = Problem.Evaluation(OffDec,LoserVel);
end

function Offspring = UpdateWinnersVPPSO(Problem,Winners,Pbest,Gbest,c1,c2,ww)
%UpdateWinnersVPPSO - Update winners using VPPSO mechanism
%
%   This function implements the VPPSO velocity update mechanism for winners
%   with Gbest as Rabbit (global best)

    WinnerDec = Winners.decs;
    PbestDec = Pbest.decs;
    GbestDec = repmat(Gbest.dec,size(WinnerDec,1),1);
    [N,D] = size(WinnerDec);
    
    %% Get current velocity
    WinnerVel = Winners.adds(zeros(N,D));
    
    %% Calculate velocity bounds
    V_max = (Problem.upper - Problem.lower) .* 0.25;
    V_min = -V_max;
    
    %% Update velocity with variable probability (VPPSO mechanism)
    OffVel = WinnerVel;
    for i = 1:N
        if rand < 0.3
            % Variable probability velocity update
            OffVel(i,:) = abs(WinnerVel(i,:)).^(rand*ww) + ...
                          rand*c1*(PbestDec(i,:)-WinnerDec(i,:)) + ...
                          rand*c2*(GbestDec(i,:)-WinnerDec(i,:));
        end
    end
    
    %% Velocity clamping
    OffVel = max(min(OffVel,repmat(V_max,N,1)),repmat(V_min,N,1));
    
    %% Update position
    OffDec = WinnerDec + OffVel;
    
    %% Boundary check
    OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
    
    %% Evaluate offspring
    Offspring = Problem.Evaluation(OffDec,OffVel);
end