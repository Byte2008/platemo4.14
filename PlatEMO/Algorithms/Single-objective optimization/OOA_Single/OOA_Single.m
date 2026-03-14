classdef OOA_Single < ALGORITHM
% <2025> <single> <real/integer> <large/none> <constrained/none>
% Octopus Optimization Algorithm
% vr --- 3 --- Velocity range parameter

%------------------------------- Reference --------------------------------
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
            %% Initialize octopus structure parameters
            NScout = mod(Problem.N, 9); %Scout（侦察）数量
            NHead = floor((Problem.N - NScout) / 9);  %Hunters数量
            NTentacles = Problem.N - NHead - NScout;
            
            %% Generate initial population
            Population = Problem.Initialization();
            
            %% Initialize octopus structure
            [Octopus, Scouts] = InitializeOctopusStructure(Population, NHead, NTentacles, NScout);
            
            %% Find global best
            [~, bestIdx] = min(FitnessSingle(Population));
            GlobalBest = Population(bestIdx);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                t = Problem.FE / Problem.maxFE;
                ld = vr * (1 - t);
                
                %% Update tentacles
                for i = 1:NHead
                    ng = length(Octopus(i).Tgroup);
                    %更新所有触角，但不更新Head
                    for j = 1:ng
                        trans = (2 * ld) * rand() - ld;
                        
                        if abs(trans) < ll
                            % Exploitation phase - 使用全局最优和当前触角组中的最优
                            [~, bestIdx] = min(FitnessSingle(Octopus(i).Tgroup));
                            newDec = Octopus(i).Tgroup(j).dec + rand() * (GlobalBest.dec - Octopus(i).Tgroup(bestIdx).dec) .* Levy(Problem.D);
                        else
                            % Exploration phase - 使用Head和当前触角
                            newDec = Octopus(i).Head.dec + rand() * (Octopus(i).Head.dec - Octopus(i).Tgroup(j).dec) .* Levy(Problem.D);
                        end
                        
                        % 边界检查
                        newDec = max(min(newDec, Problem.upper), Problem.lower);
                        
                        % 评估并更新
                        NewIndividual = Problem.Evaluation(newDec);
                        Octopus(i).Tgroup(j) = NewIndividual;
                    end
                    
                    % 每个Head的触角更新后进行交换
                    Octopus = ExchangeHeadTentacle(Octopus, i);
                end
                
                %% Scout phase
                if NScout > 0
                    AllOctopus = [Octopus.Head];
                    [~, sortIdx] = sort(FitnessSingle(AllOctopus));
                    
                    ScoutDecs = [];
                    ScoutTargets = [];
                    for z = 1:NScout
                        if z == 1
                            %最好的。
                            flagIdx = sortIdx(1);
                        elseif z == 2 && length(sortIdx) > 1
                            %最差的。
                            flagIdx = sortIdx(end);
                        else
                            if length(sortIdx) > 2
                                flagIdx = sortIdx(randi([2, length(sortIdx)-1]));
                            else
                                flagIdx = sortIdx(1);
                            end
                        end
                        
                        flag = AllOctopus(flagIdx);
                        
                        % 根据公式(16)更新Scout位置
                        newDec = flag.dec + rand() * ld * ((Problem.upper + Problem.lower) - 2 * flag.dec);
                        
                        % 边界检查
                        newDec = max(min(newDec, Problem.upper), Problem.lower);
                        
                        ScoutDecs = [ScoutDecs; newDec];
                        ScoutTargets = [ScoutTargets; flagIdx];
                    end
                    
                    %% Evaluate all scouts at once
                    NewScouts = Problem.Evaluation(ScoutDecs);
                    
                    %% Update heads and regenerate tentacles if scouts are better
                    for z = 1:NScout
                        Scouts(z) = NewScouts(z);
                        flagIdx = ScoutTargets(z);
                        
                        % 如果Scout优于对应的Hunter head
                        if FitnessSingle(Scouts(z)) < FitnessSingle(Octopus(flagIdx).Head)
                            % 公式(17): 用Scout替换Hunter的head
                            Octopus(flagIdx).Head = Scouts(z);
                            
                            % 公式(18): 重新生成该Hunter的触角 - 按源代码公式
                            ng = length(Octopus(flagIdx).Tgroup);
                            if ng > 0
                                for i = 1:ng
                                    newTentacleDec = -ones(1, Problem.D) .* (Octopus(flagIdx).Head.dec - ll) + rand(1, Problem.D) .* (Octopus(flagIdx).Head.dec + ll);
                                    % 边界检查
                                    newTentacleDec = max(min(newTentacleDec, Problem.upper), Problem.lower);
                                    NewTentacle = Problem.Evaluation(newTentacleDec);
                                    Octopus(flagIdx).Tgroup(i) = NewTentacle;
                                end
                            end
                            
                            % 交换该Hunter的Head和最优触角
                            Octopus = ExchangeHeadTentacle(Octopus, flagIdx);
                        end
                    end
                end
                
                %% Update global best
                AllPop = [Octopus.Head];
                for i = 1:NHead
                    AllPop = [AllPop, Octopus(i).Tgroup];
                end
                AllPop = [AllPop, Scouts];
                
                [~, bestIdx] = min(FitnessSingle(AllPop));
                if FitnessSingle(AllPop(bestIdx)) < FitnessSingle(GlobalBest)
                    GlobalBest = AllPop(bestIdx);
                end
                
                Population = AllPop;
            end
        end
    end
end

function [Octopus, Scouts] = InitializeOctopusStructure(Population, NHead, NTentacles, NScout)
    % Initialize octopus structure
    Octopus = struct('Head', {}, 'Tgroup', {});
    
    % Shuffle Population order：打乱种群顺序。
    %Population = Population(randperm(length(Population)));
    
    % Assign heads
    for i = 1:NHead
        Octopus(i).Head = Population(i);
        Octopus(i).Tgroup = [];
    end
    
    % Assign tentacles to heads
    tentacleIdx = NHead + 1;
    k = 1;
    %将Population中NHead后NTentacles个个体作为触角，每个个体交叉分配到Head中。
    for j = 1:NTentacles
        headIdx = mod(j-1, NHead) + 1;
        Octopus(headIdx).Tgroup = [Octopus(headIdx).Tgroup, Population(tentacleIdx)];
        tentacleIdx = tentacleIdx + 1;
    end
    
    % Initialize scouts，侦察
    Scouts = Population(tentacleIdx:end);
end

function Octopus = ExchangeHeadTentacle(Octopus, headIdx)
    % Exchange head with best tentacle if tentacle is better
    % 如果headIdx是标量，只交换该Head；如果是向量，交换所有Head
    if isscalar(headIdx)
        indices = headIdx;
    else
        indices = 1:length(Octopus);
    end
    
    for i = indices
        if ~isempty(Octopus(i).Tgroup)
            [minFit, bestIdx] = min(FitnessSingle(Octopus(i).Tgroup));
            if minFit < FitnessSingle(Octopus(i).Head)
                temp = Octopus(i).Tgroup(bestIdx);
                Octopus(i).Tgroup(bestIdx) = Octopus(i).Head;
                Octopus(i).Head = temp;
            end
        end
    end
end

function L = Levy(d)
    % Levy flight
    beta = 1.5;
    sigma = (gamma(1+beta) * sin(pi*beta/2) / (gamma((1+beta)/2) * beta * 2^((beta-1)/2)))^(1/beta);
    u = randn(1, d) * sigma;
    v = randn(1, d);
    step = u ./ abs(v).^(1/beta);
    L = step;
end
