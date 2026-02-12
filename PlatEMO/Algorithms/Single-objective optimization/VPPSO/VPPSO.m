classdef VPPSO < ALGORITHM
% <2024> <single> <real/integer> <large/none> <constrained/none>
% Variable Probability Particle Swarm Optimization
% c1   --- 1.5 --- Cognitive coefficient
% c2   --- 1.2 --- Social coefficient
% rate --- 0.5 --- Ratio of first swarm to total population

%------------------------------- Reference --------------------------------
% Variable Probability Particle Swarm Optimization Algorithm
% Original implementation from: 淘个代码
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
            [c1,c2,rate] = Algorithm.ParameterSet(1.5,1.2,0.5);
            
            %% Calculate swarm sizes
            N = round(Problem.N * rate);  % Size of first swarm
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Initialize personal best
            Pbest = Population(1:N);
            
            %% Initialize global best
            [~,best] = min(FitnessSingle(Population));
            Gbest = Population(best);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                %% Calculate dynamic inertia weight (Equ. 12)
                ww = exp(-(2.5*Problem.FE/Problem.maxFE)^2.5);
                
                %% Update first swarm (particles with velocity)
                Population(1:N) = UpdateFirstSwarm(Problem,Population(1:N),Pbest,Gbest,c1,c2,ww);
                
                %% Update personal best for first swarm
                replace = FitnessSingle(Pbest) > FitnessSingle(Population(1:N));
                Pbest(replace) = Population(replace);
                
                %% Update second swarm (particles without velocity)
                if Problem.N > N
                    Population(N+1:end) = UpdateSecondSwarm(Problem,Gbest,ww,Problem.N-N);
                end
                
                %% Update global best
                [~,best] = min(FitnessSingle(Population));
                Gbest = Population(best);
            end
        end
    end
end

%% Update first swarm (particles with velocity)
%%Population(1:N) = UpdateFirstSwarm(Problem,Population(1:N),Pbest,Gbest,c1,c2,ww);
function Offspring = UpdateFirstSwarm(Problem,Particle,Pbest,Gbest,c1,c2,ww)
%UpdateFirstSwarm - Update the first swarm with velocity-based PSO
%
%   This function implements the velocity update mechanism for the first
%   swarm using variable probability strategy (Equ. 13)

    ParticleDec = Particle.decs;
    PbestDec    = Pbest.decs;
    GbestDec    = repmat(Gbest.dec,size(ParticleDec,1),1);
    [N,D]       = size(ParticleDec);
    
    %% Get current velocity
    ParticleVel = Particle.adds(zeros(N,D));
    
    %% Calculate velocity bounds
    V_max = (Problem.upper - Problem.lower) .* 0.25;
    V_min = -V_max;
    
    %% Update velocity with variable probability (Equ. 13)
    OffVel = ParticleVel;
    for i = 1:N
        if rand < 0.3
            % Variable probability velocity update
            OffVel(i,:) = abs(ParticleVel(i,:)).^(rand*ww) + ...
                          rand*c1*(PbestDec(i,:)-ParticleDec(i,:)) + ...
                          rand*c2*(GbestDec(i,:)-ParticleDec(i,:));
        end
    end
    
    %% Velocity clamping
    OffVel = max(min(OffVel,repmat(V_max,N,1)),repmat(V_min,N,1));
    
    %% Update position
    OffDec = ParticleDec + OffVel;
    
    %% Boundary check
    OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
    
    %% Evaluate offspring
    Offspring = Problem.Evaluation(OffDec,OffVel);
end

%Population(N+1:end) = UpdateSecondSwarm(Problem,Gbest,ww,Problem.N-N);
function Offspring = UpdateSecondSwarm(Problem,Gbest,ww,N)
%UpdateSecondSwarm - Update the second swarm without velocity
%
%   This function implements the position update mechanism for the second
%   swarm based on global best (Equ. 15)

    GbestDec = Gbest.dec;
    D = Problem.D;
    
    %% Generate new positions around global best (Equ. 15)
    OffDec = zeros(N,D);
    for i = 1:N
        for j = 1:D
            CC = ww * rand * abs(GbestDec(j))^ww;
            if rand < 0.5
                OffDec(i,j) = GbestDec(j) + CC;
            else
                OffDec(i,j) = GbestDec(j) - CC;
            end
        end
    end
    
    %% Boundary check
    OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
    
    %% Evaluate offspring (no velocity for second swarm)
    Offspring = Problem.Evaluation(OffDec);
end
