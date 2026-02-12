classdef Block_Vppso < BLOCK
% VPPSO first swarm for real variables
% nSets --- 5 --- Number of parameter sets for velocity update probability

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nSets;              % <hyperparameter> Number of parameter sets
        VelUpdateProb;      % <parameter> Velocity update probability sets
        Fit;                % <parameter> Probability of using each parameter set
        Pbest;              % Personal best positions
        Pbest_fitness;      % Personal best fitness values
        Velocity;           % Particle velocities
        c1 = 1.5;           % Cognitive coefficient
        c2 = 1.2;           % Social coefficient
    end
    methods
        %% Default settings of the block
        function obj = Block_Vppso(nSets)
            obj.nSets = nSets;                          % Hyperparameter
            obj.lower = repmat([0 1e-20],1,nSets);      % Lower bounds: [velocity_update_prob, selection_prob]
            obj.upper = repmat([1 1],1,nSets);          % Upper bounds
            % Randomly set the parameters
            obj.parameter = unifrnd(obj.lower,obj.upper);
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj)
            obj.VelUpdateProb = reshape(obj.parameter,[],obj.nSets)';  % Reshape to [nSets x 2]
            obj.Fit = cumsum(obj.VelUpdateProb(:,2));                   % Cumulative sum for roulette selection
            obj.Fit = obj.Fit./max(obj.Fit);                            % Normalize to [0,1]
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            % Gather population from predecessors
            Population = obj.Gather(Problem,Precursors,Ratio,1,1);
            PopDec = Population.decs;
            N = size(PopDec,1);
            dim = size(PopDec,2);
            
            % Calculate max_iteration based on maxFE and population size
            max_iteration = floor(Problem.maxFE / N);
            
            % Initialize velocity bounds
            V_max = ones(1,dim).*(Problem.upper-Problem.lower).*0.25;
            V_min = -V_max;
            
            % Initialize personal best if not exists
            if isempty(obj.Pbest) || size(obj.Pbest,1) ~= N
                obj.Pbest = PopDec;
                obj.Pbest_fitness = Population.objs;
                obj.Velocity = zeros(N,dim);
            end
            
            % Find global best
            [~,best_idx] = min(obj.Pbest_fitness);
            gbest = obj.Pbest(best_idx,:);
            
            % Perform iterations
            for t = 1:max_iteration
                ww = exp(-(2.5*t/max_iteration)^2.5);  % Inertia weight (Equ. 12)
                
                % Sample velocity update probability for each particle
                vel_prob = ParaSampling([N,1],obj.VelUpdateProb(:,1),obj.Fit);
                
                for i = 1:N
                    if rand < vel_prob(i)
                        % Update velocity (Equ. 13)
                        obj.Velocity(i,:) = abs(obj.Velocity(i,:)).^(rand*ww) + ...
                                           rand*obj.c1*(obj.Pbest(i,:)-PopDec(i,:)) + ...
                                           rand*obj.c2*(gbest-PopDec(i,:));
                    end
                    
                    % Velocity clamping
                    obj.Velocity(i,:) = min(V_max,max(V_min,obj.Velocity(i,:)));
                    
                    % Update position
                    PopDec(i,:) = PopDec(i,:) + obj.Velocity(i,:);
                    
                    % Boundary check
                    PopDec(i,:) = min(Problem.upper,max(Problem.lower,PopDec(i,:)));
                end
                
                % Evaluate new positions
                Population = Problem.Evaluation(PopDec);
                
                % Update personal best
                for i = 1:N
                    if Population(i).obj < obj.Pbest_fitness(i)
                        obj.Pbest(i,:) = PopDec(i,:);
                        obj.Pbest_fitness(i) = Population(i).obj;
                    end
                end
                
                % Update global best
                [~,best_idx] = min(obj.Pbest_fitness);
                gbest = obj.Pbest(best_idx,:);
            end
        