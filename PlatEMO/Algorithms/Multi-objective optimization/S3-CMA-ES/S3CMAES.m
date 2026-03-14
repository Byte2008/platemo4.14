classdef S3CMAES < ALGORITHM
% <2020> <multi/many> <real/integer> <large/none>
% Scalable small subpopulations based covariance matrix adaptation
% evolution strategy

%------------------------------- Reference --------------------------------
% H. Chen, R. Cheng, J. Wen, H. Li, and J. Weng. Solving large-scale
% many-objective optimization problems by covariance matrix adaptation
% evolution strategy with scalable small subpopulations. Information
% Sciences, 2020, 509: 457-469.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

% This function is written by Huangke Chen

    methods
        function main(Algorithm,Problem)
            %% Detect the group of each distance variable，逐维改变该维，观测NDSort的最大前沿层数来衡量“对目标的控制能力”，选取前M−1维为PV，其余为DV。
            nPer      = 50;	% Sample size to divide the convergence- and diversity-related variables
            nPerGroup = 35;	% the group size for separative variables

            [PV, DV] = ControlVariableAnalysis(Problem,nPer);	% divide the convergence- and diversity-related variables        
            Groups   = GroupDV(Problem,DV,PV,nPerGroup);     	% divide the convergence-related variables based on correlation
            %构造popN个小子群体，每个子群体的PV一致（在PV空间中随机设定），DV初值相同。
            popN = 5;	% the number of sub-populations
            % V: random unit vectors in diversity space
            V = 0.05 + 0.9*rand(popN,length(PV));
            % extend to the diversity space
            V = repmat(Problem.lower(PV),popN,1)+V.*(repmat((Problem.upper(PV)-Problem.lower(PV)),popN,1));  

            % CMA-ES parameters
            popSize         = 6 + floor(3*log(nPerGroup));	% the population size for CMA-ES
            tempParaOnePopu = LoadCMAESparameters(Problem,Groups,popSize);
            CMAParaMPopu    = repmat(tempParaOnePopu,popN,1);

            BigPopulation = cell(1,popN);	% initialize the big population to contain all the population
            % the diversity-related variables of all the solutions in a sub-population are the same
            for i = 1 : popN
                tempDecs         = zeros(popSize,Problem.D);
                tempDecs(:, PV)  = repmat(V(i, :),popSize,1);
                DVPositionM      = Problem.lower(DV) + (Problem.upper(DV)-Problem.lower(DV)).*rand(1, length(DV));
                tempDecs(:, DV)  = repmat(DVPositionM,popSize,1);
                BigPopulation{i} = tempDecs;
            end

            %% Optimization
            Archive      = Problem.Evaluation(BigPopulation{1});
            lastBestValA = zeros(1,popN);	% Record the best val last iteration
            stopTag      = false(1,popN);
            unUpdateNum  = zeros(1,popN);
            unChangeThr  = 1e-10;
            firstTag     = true;

            ConvergedSolutionSet = [];	% Record the converged solutions
            while Algorithm.NotTerminated(Archive)

                Archive = ConvergedSolutionSet;
                popN    = length(BigPopulation);
                for p = 1 : popN	% evolute each small population
                    if stopTag(p)	% if the subpopulaton has converged, then no evolve it
                        continue;
                    end
                    %对每个子群体p、每个分组g，调用Operator对该分组维度进行一次CMA-ES更新，其他维度用bestmem填充后整体评估适应度；记录该分组的最优个体进入档案。
                    tempDecs = BigPopulation{p};	% obtain the p-th population
                    PVDecs   = tempDecs(:,PV);
                    bestmem  = tempDecs(1,:);   	% select the first individual as best member

                    tempDecs        = zeros(popSize,Problem.D);	% record the new population
                    tempDecs(:, PV) = PVDecs;                   % repmat(V(p, :), popSize, 1);

                    for g = 1 : length(Groups) % evolute each group of convergence-related variables for a sub-population
                        dim_index = Groups{g};
                        % employ the CMA-ES
                        [CMAParaMPopu(p,g),pop,BestVal,BestIndividual] = Operator(Problem,CMAParaMPopu(p,g),bestmem,dim_index);
                        tempDecs(:,dim_index) = pop;
                    end
                    Archive          = [Archive,BestIndividual];            
                    BigPopulation{p} = tempDecs;	% record the new position for this small population
                    %子群体收敛判定：若本轮最佳值与上轮差异低于阈值unChangeThr，则标记为停止并把最优个体加入“收敛解集合”。
                    if abs(lastBestValA(p)-BestVal) < unChangeThr	% check whether the sub population has converged
                        unUpdateNum(p)       = unUpdateNum(p) + 1;
                        stopTag(p)           = true;
                        ConvergedSolutionSet = [ConvergedSolutionSet,BestIndividual]; 
                    end
                    lastBestValA(p) = BestVal;
                end

                % generate new sub-populations for next stage，触发条件：所有子群体均停止，或FE超过maxFE的60%。
                Tag = Problem.FE > 0.6*Problem.maxFE && firstTag;
                if sum(stopTag) == length(stopTag) || Tag 
                    firstTag = false;	% The first stage has been over

                    % evolute the diversity-related variables，在档案的PV上执行差分变异（DE/rand/1，CR=0.2，F=0.5，执行200次），并进行边界处理，再评估并用环境选择更新档案。
                    for repPV = 1 : 200  % 200 denotes the repeat times for diversity-related variables
                        CR      = 0.2;
                        F       = 0.5;
                        ExiDecs = Archive.decs;
                        ExiPV   = ExiDecs(:, PV);
                        [N,D]   = size(ExiPV);
                        Parent1Dec   = ExiPV;
                        Parent2Dec   = ExiPV(randperm(N), :);
                        Parent3Dec   = ExiPV(randperm(N), :);
                        OffspringDec = Parent1Dec;
                        Site = rand(N,D) < CR;
                        OffspringDec(Site) = OffspringDec(Site) + F*(Parent2Dec(Site)-Parent3Dec(Site));

                        Lower = repmat(Problem.lower(PV),N,1);	% Lower boundary
                        Upper = repmat(Problem.upper(PV),N,1);	% Upper boundary
                        OffspringDec = max(min(OffspringDec,Upper),Lower);

                        newDecs       = ExiDecs;
                        newDecs(:,PV) = OffspringDec;
                        newPop        = Problem.Evaluation(newDecs);

                        % environmental selection
                        Archive = UpdateArchive(Problem.N,[newPop,Archive]);
                    end
                    % generate new sub-populations
                    [BigPopulation,CMAParaMPopu] = GenerateBigPopulation(PV,Groups,Archive);

                    popN         = length(BigPopulation);
                    lastBestValA = 1e+20*ones(1,popN);
                    stopTag      = false(1,popN);
                    unUpdateNum  = zeros(1,popN);            
                    ConvergedSolutionSet = [];
                end

                % Obtain the output solutions，当FE达到上限时，从每个子群体的首个个体汇总评估，再经环境选择得到最终档案作为输出。
                if Problem.FE >= Problem.maxFE
                    Decs = zeros(length(BigPopulation),Problem.D);
                    for bp = 1 : length(BigPopulation)
                        DecPop      = BigPopulation{bp};
                        Decs(bp, :) = DecPop(1,:);
                    end
                    finalPop = Problem.Evaluation(Decs);
                    Archive  = UpdateArchive(Problem.N,[finalPop,Archive]);
                end
            end
        end
    end
end