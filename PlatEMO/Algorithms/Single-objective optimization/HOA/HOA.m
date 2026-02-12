classdef new_HOA < ALGORITHM
% <2021> <single> <real/integer> <large/none> <constrained/none>
% Hiking Optimization Algorithm
% theta_max --- 50 --- Maximum elevation angle
% SF_max    --- 2  --- Maximum sweep factor

%------------------------------- Reference --------------------------------
% D. Bozorg-Haddad, M. Solgi, and H. A. Loáiciga, Meta-heuristic and 
% evolutionary algorithms for engineering optimization. John Wiley & Sons, 2017.
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
            [theta_max, SF_max] = Algorithm.ParameterSet(50, 2);
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                %% Find the leader (best hiker)
                [~,best] = min(FitnessSingle(Population));
                Xbest = Population(best).dec;
                
                %% Update population
                PopDec = Population.decs;
                [N,D] = size(PopDec);
                OffDec = zeros(N,D);
                
                for j = 1:N
                    %% Current hiker position
                    Xini = PopDec(j,:);
                    
                    %% Generate elevation angle (0 to theta_max degrees)
                    theta = randi([0 theta_max], 1, 1);
                    
                    %% Compute slope
                    s = tan(deg2rad(theta));
                    
                    %% Generate sweep factor (1 or 2 randomly, or up to SF_max)
                    SF = randi([1 SF_max], 1, 1);
                    
                    %% Compute walking velocity based on Tobler's Hiking Function
                    Vel = 6 * exp(-3.5 * abs(s + 0.05));
                    
                    %% Determine new velocity of hiker
                    newVel = Vel + rand(1,D) .* (Xbest - SF .* Xini);
                    
                    %% Update position of hiker
                    OffDec(j,:) = PopDec(j,:) + newVel;
                end
                
                %% Boundary check
                OffDec = max(min(OffDec, repmat(Problem.upper, N, 1)), repmat(Problem.lower, N, 1));
                
                %% Evaluate offspring
                Offspring = Problem.Evaluation(OffDec);
                
                %% Apply greedy selection strategy
                replace = FitnessSingle(Offspring) < FitnessSingle(Population);
                Population(replace) = Offspring(replace);
            end
        end
    end
end