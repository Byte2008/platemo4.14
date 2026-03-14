classdef QIO < ALGORITHM
% <2023> <single> <real> <large/none> <constrained/none>
% Quadratic Interpolation Optimization

%------------------------------- Reference --------------------------------
% W. Zhao, L. Wang, Z. Zhang, S. Mirjalili, N. Khodadadi, Q. Ge, Quadratic
% Interpolation Optimization (QIO): A new optimization algorithm based on
% generalized quadratic interpolation and its applications to real-world
% engineering problems, Computer Methods in Applied Mechanics and
% Engineering, 2023, 422: 116446.
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
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                PopDec = Population.decs;
                PopFit = FitnessSingle(Population);
                [BestF,bestIdx] = min(PopFit);
                BestX = PopDec(bestIdx,:);
                
                NewDec = zeros(Problem.N,Problem.D);
                
                for i = 1:Problem.N
                    if rand > 0.5
                        % Exploration phase
                        K = [1:i-1 i+1:Problem.N];
                        RandInd = randperm(Problem.N-1,3);
                        K1 = K(RandInd(1));
                        K2 = K(RandInd(2));
                        K3 = K(RandInd(3));
                        
                        f1 = PopFit(i);
                        f2 = PopFit(K1);
                        f3 = PopFit(K2);
                        
                        for j = 1:Problem.D
                            x1 = PopDec(i,j);
                            x2 = PopDec(K1,j);
                            x3 = PopDec(K2,j);
                            % Eq.(25)
                            NewDec(i,j) = GQI(x1,x2,x3,f1,f2,f3,Problem.lower(j),Problem.upper(j));
                        end
                        
                        a = cos(pi/2*Problem.FE/Problem.maxFE);
                        b = 0.7*a + 0.15*a*(cos(5*pi*Problem.FE/Problem.maxFE)+1);
                        % Eq.(27)
                        w1 = 3*b*randn;
                        % Exploration, Eq.(26)
                        NewDec(i,:) = NewDec(i,:) + w1.*(PopDec(K3,:)-NewDec(i,:)) + ...
                            round(0.5*(0.05+rand))*(log(rand/(rand)));
                    else
                        % Exploitation phase
                        K = [1:i-1 i+1:Problem.N];
                        RandInd = randperm(Problem.N-1,2);
                        K1 = K(RandInd(1));
                        K2 = K(RandInd(2));
                        
                        f1 = PopFit(K1);
                        f2 = PopFit(K2);
                        f3 = BestF;
                        
                        for j = 1:Problem.D
                            x1 = PopDec(K1,j);
                            x2 = PopDec(K2,j);
                            x3 = BestX(j);
                            % Eq.(31)
                            NewDec(i,j) = GQI(x1,x2,x3,f1,f2,f3,Problem.lower(j),Problem.upper(j));
                        end
                        
                        % Eq.(32)
                        w2 = 3*(1-Problem.FE/Problem.maxFE)*randn;
                        rD = randi(Problem.D);
                        % Exploitation, Eq.(30)
                        NewDec(i,:) = NewDec(i,:) + w2*(BestX-round(1+rand)*...
                            (Problem.upper(rD)-Problem.lower(rD))/(Problem.upper(rD)-Problem.lower(rD))*PopDec(i,rD));
                    end
                    
                    % Boundary control
                    NewDec(i,:) = max(min(NewDec(i,:),Problem.upper),Problem.lower);
                end
                
                % Evaluate offspring
                Offspring = Problem.Evaluation(NewDec);
                
                % Selection
                replace = FitnessSingle(Offspring) < PopFit;
                Population(replace) = Offspring(replace);
            end
        end
    end
end
