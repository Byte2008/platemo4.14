classdef CMAES < ALGORITHM
% <2001> <single> <real/integer> <large/none> <constrained/none>
% Covariance matrix adaptation evolution strategy
%法类型：单目标、连续/整数变量均可，采用协方差矩阵自适应进化策略（CMA-ES）实现全局搜索与二阶结构学习。
%------------------------------- Reference --------------------------------
% N. Hansen and A. Ostermeier. Completely derandomized selfadaptation in
% evolution strategies. Evolutionary Computation, 2001, 9(2): 159-195.
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
            %% Initialization
            %- 父代数量与权重- mu 为父代数 mu ，取种群规模的一半。
            %- 权重 w 采用对数型递减并归一化 w ，偏向前排精英。- 有效样本数 mu_eff mu_eff ，衡量权重分散度。
            %- 步长控制参数- cs（步长路径学习率）、ds（阻尼因子）与 ENN（标准正态向量范数期望）见 cs,ds,ENN 。
            %- 协方差更新参数- cc（协方差路径学习率）、c1（rank-1 权重）、cmu（rank-μ 权重上限）、hth（步长路径阈值）见 cc,c1,cmu,hth 。
            % Number of parents
            mu     = round(Problem.N/2);
            % Parent weights
            w      = log(mu+0.5) - log(1:mu);
            w      = w./sum(w);
            % Number of effective solutions
            mu_eff = 1/sum(w.^2);
            % Step size control parameters
            cs     = (mu_eff+2)/(Problem.D+mu_eff+5);
            ds     = 1 + cs + 2*max(sqrt((mu_eff-1)/(Problem.D+1))-1,0);
            ENN    = sqrt(Problem.D)*(1-1/(4*Problem.D)+1/(21*Problem.D^2));
            % Covariance update parameters
            cc     = (4+mu_eff/Problem.D)/(4+Problem.D+2*mu_eff/Problem.D);
            c1     = 2/((Problem.D+1.3)^2+mu_eff);
            cmu    = min(1-c1,2*(mu_eff-2+1/mu_eff)/((Problem.D+2)^2+2*mu_eff/2));
            hth    = (1.4+2/(Problem.D+1))*ENN;
            % Initialization
            Mdec  = unifrnd(Problem.lower,Problem.upper);  %均值 Mdec 在边界内均匀采样 Mdec 。
            ps    = zeros(1,Problem.D);                    %步长路径 ps、协方差路径 pc 置零，协方差 C=I ps,pc,C 。
            pc    = zeros(1,Problem.D);
            C     = eye(Problem.D);
            sigma = 0.1*(Problem.upper-Problem.lower);      %初始步长 sigma 取 10% 范围。
            Population = Problem.Initialization(1);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                % Sample solutions
                %采样与评估: 从 N(0, C) 采样步子 Pstep（对每个个体） 采样 ，构造候选解 Pdec = Mdec + sigma * Pstep 并评估 构造与评估 。
                for i = 1 : Problem.N
                    Pstep(i,:) = mvnrnd(zeros(1,Problem.D),C);
                end
                Pdec       = Mdec + sigma.*Pstep;
                Population = Problem.Evaluation(Pdec);
                % Update mean
                [~,rank] = sort(FitnessSingle(Population));
                Pstep    = Pstep(rank,:);
                Mstep    = w*Pstep(1:mu,:);
                Mdec     = Mdec + sigma.*Mstep;
                % Update parameters
                ps    = (1-cs)*ps + sqrt(cs*(2-cs)*mu_eff)*Mstep/chol(C)';
                sigma = sigma*exp(cs/ds*(norm(ps)/ENN-1))^0.3;
                hs    = norm(ps)/sqrt(1-(1-cs)^(2*(ceil(Problem.FE/Problem.N)+1))) < hth;
                delta = (1-hs)*cc*(2-cc);
                pc    = (1-cc)*pc + hs*sqrt(cc*(2-cc)*mu_eff)*Mstep;
                C     = (1-c1-cmu)*C + c1*(pc'*pc+delta*C);
                for i = 1 : mu
                    C = C + cmu*w(i)*Pstep(i,:)'*Pstep(i,:);
                end
                [V,E] = eig(C);
                if any(diag(E)<0)
                    C = V*max(E,0)/V;
                end
            end
        end
    end
end