classdef OOA < ALGORITHM
% <2025> <multi> <real> <large/none> <none>
% Octopus Optimization Algorithm for Multi-objective Optimization

%------------------------------- Reference --------------------------------
% Octopus Optimization Algorithm (OOA), 2025
% Adapted for multi-objective optimization using non-dominated sorting
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
            %% Initialize parameters
            vr = 3;
            NScout = mod(Problem.N, 9);
            NHead = floor((Problem.N - NScout) / 9);
            NTentacles = Problem.N - NHead - NScout;
            
            %% Generate initial population
            Population = Problem.Initialization();
            [Population, FrontNo, CrowdDis] = EnvironmentalSelection(Population, Problem.N);
            
            %% Initialize octopus structure
            [Octopus, Scouts] = InitializeOctopusStructure(Population, NHead, NTentacles, NScout);
            
            %% Select global best from first front
            GlobalBest = SelectGlobalBest(Population, FrontNo);
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                t = Problem.FE / Problem.maxFE;
                ld = vr * (1 - t);
                
                %% Update tentacles
                NewPop = [];
                for i = 1:NHead
                    ng = length(Octopus(i).Tgroup);
                    for j = 1:ng
                        trans = (2 * ld) * rand() - ld;
                        
                        if abs(trans) > 1
                            % Exploration phase
                            K = [1:j-1, j+1:ng];
                            if ~isempty(K)
                                r2 = K(randi(numel(K)));
                                newDec = Octopus(i).Tgroup(j).dec + rand() * (GlobalBest.dec - Octopus(i).Tgroup(r2).dec) .* Levy(Problem.D);
                            else
                                newDec = Octopus(i).Tgroup(j).dec + rand() * (GlobalBest.dec - Octopus(i).Tgroup(j).dec) .* Levy(Problem.D);
                            end
                        else
                            % Exploitation phase
                            newDec = GlobalBest.dec + rand() * (GlobalBest.dec - Octopus(i).Tgroup(j).dec) .* Levy(Problem.D);
                        end
                        
                        NewPop = [NewPop, Problem.Evaluation(newDec)];
                    end
                end
                
                %% Update octopus structure with new tentacles
                idx = 1;
                for i = 1:NHead
                    ng = length(Octopus(i).Tgroup);
                    for j = 1:ng
                        Octopus(i).Tgroup(j) = NewPop(idx);
                        idx = idx + 1;
                    end
                end
                
                %% Exchange between head and best tentacle
                Octopus = ExchangeHeadTentacle(Octopus, NHead);
                
                %% Scout phase
                AllOctopus = [Octopus.Head];
                [~, octopusFrontNo, ~] = EnvironmentalSelection(AllOctopus, length(AllOctopus));
                
                for z = 1:NScout
                    % Select flag based on front number
                    if z == 1
                        % Best: from first front
                        idx = find(octopusFrontNo == 1);
                        flagIdx = idx(randi(length(idx)));
                    elseif z == 2
                        % Worst: from last front
                        idx = find(octopusFrontNo == max(octopusFrontNo));
                        flagIdx = idx(randi(length(idx)));
                    else
                        % Random
                        flagIdx = randi(length(AllOctopus));
                    end
                    
                    flag = AllOctopus(flagIdx);
                    CS = (Problem.upper + Problem.lower) / 2;
                    MP = (Problem.upper + Problem.lower) - flag.dec;
                    
                    if all(MP > CS)
                        newDec = CS + rand(1, Problem.D) .* (MP - CS);
                    else
                        newDec = MP + rand(1, Problem.D) .* (CS - MP);
                    end
                    
                    Scouts(z) = Problem.Evaluation(newDec);
                    
                    % Replace if dominates
                    if Dominates(Scouts(z), flag)
                        Octopus(flagIdx).Head = Scouts(z);
                    end
                end
                
                %% Combine all solutions
                AllPop = [Octopus.Head];
                for i = 1:NHead
                    AllPop = [AllPop, Octopus(i).Tgroup];
                end
                AllPop = [AllPop, Scouts];
                
                %% Environmental selection
                [Population, FrontNo, CrowdDis] = EnvironmentalSelection(AllPop, Problem.N);
                
                %% Update global best
                GlobalBest = SelectGlobalBest(Population, FrontNo);
                
                %% Reconstruct octopus structure
                [Octopus, Scouts] = InitializeOctopusStructure(Population, NHead, NTentacles, NScout);
            end
        end
    end
end

function [Octopus, Scouts] = InitializeOctopusStructure(Population, NHead, NTentacles, NScout)
    % Initialize octopus structure
    Octopus = struct('Head', {}, 'Tgroup', {});
    
    % Assign heads
    for i = 1:NHead
        Octopus(i).Head = Population(i);
        Octopus(i).Tgroup = [];
    end
    
    % Assign tentacles to heads
    tentacleIdx = NHead + 1;
    for j = 1:NTentacles
        headIdx = mod(j-1, NHead) + 1;
        Octopus(headIdx).Tgroup = [Octopus(headIdx).Tgroup, Population(tentacleIdx)];
        tentacleIdx = tentacleIdx + 1;
    end
    
    % Initialize scouts
    if NScout > 0
        Scouts = Population(tentacleIdx:min(tentacleIdx+NScout-1, length(Population)));
    else
        Scouts = [];
    end
end

function Octopus = ExchangeHeadTentacle(Octopus, NHead)
    % Exchange head with best tentacle based on dominance
    for i = 1:NHead
        if ~isempty(Octopus(i).Tgroup)
            for j = 1:length(Octopus(i).Tgroup)
                if Dominates(Octopus(i).Tgroup(j), Octopus(i).Head)
                    temp = Octopus(i).Tgroup(j);
                    Octopus(i).Tgroup(j) = Octopus(i).Head;
                    Octopus(i).Head = temp;
                    break;
                end
            end
        end
    end
end

function GlobalBest = SelectGlobalBest(Population, FrontNo)
    % Select a random solution from the first front
    firstFront = find(FrontNo == 1);
    GlobalBest = Population(firstFront(randi(length(firstFront))));
end

function flag = Dominates(A, B)
    % Check if A dominates B
    flag = all(A.obj <= B.obj) && any(A.obj < B.obj);
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
