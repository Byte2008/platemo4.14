classdef Block_QIO_Exploration < BLOCK
% QIO Exploration phase
% w1_scale --- 1.0 --- Scale factor for exploration weight w1

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
        function obj = Block_QIO_Exploration()
            % No parameters - using fixed values from paper
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            % Gather parent population
            Population = obj.Gather(Problem,Precursors,Ratio,1,1);
            PopDec = Population.decs;
            PopFit = FitnessSingle(Population);
            
            N = size(PopDec,1);
            D = Problem.D;
            NewDec = zeros(N,D);
            
            % Exploration phase for each individual
            for i = 1:N
                % Select three random individuals (excluding current one)
                K = [1:i-1 i+1:N];
                RandInd = randperm(N-1,3);
                K1 = K(RandInd(1));
                K2 = K(RandInd(2));
                K3 = K(RandInd(3));
                
                f1 = PopFit(i);
                f2 = PopFit(K1);
                f3 = PopFit(K2);
                
                % Apply GQI for each dimension
                for j = 1:D
                    x1 = PopDec(i,j);
                    x2 = PopDec(K1,j);
                    x3 = PopDec(K2,j);
                    % Eq.(25) - Generalized Quadratic Interpolation
                    NewDec(i,j) = GQI(x1,x2,x3,f1,f2,f3,Problem.lower(j),Problem.upper(j));
                end
                
                % Calculate time-dependent parameters
                t = Problem.FE / Problem.maxFE;
                a = cos(pi/2 * t);
                b = 0.7*a + 0.15*a*(cos(5*pi*t)+1);
                
                % Eq.(27) - Exploration weight
                w1 = 3*b*randn;
                
                % Eq.(26) - Exploration update
                NewDec(i,:) = NewDec(i,:) + w1.*(PopDec(K3,:)-NewDec(i,:)) + ...
                    round(0.5*(0.05+rand))*(log(rand/(rand)));
            end
            
            % Boundary control
            NewDec = max(min(NewDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
            
            obj.output = NewDec;
        end
    end
end
