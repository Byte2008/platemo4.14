%% VPPSO算法测试脚本
% 用于验证改造后的VPPSO算法在PlatEMO平台上的正确性

%% 测试1：基本功能测试
fprintf('========================================\n');
fprintf('测试1：基本功能测试\n');
fprintf('========================================\n');

% 创建算法和问题对象
Algorithm = VPPSO();
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);

% 运行算法
Algorithm.Solve(Problem);

% 获取结果
BestSolution = Algorithm.result{end}(1);
fprintf('问题: SOP_F1 (Sphere函数)\n');
fprintf('维度: %d\n', Problem.D);
fprintf('种群大小: %d\n', Problem.N);
fprintf('最大评估次数: %d\n', Problem.maxFE);
fprintf('最优适应度: %.6e\n', BestSolution.obj);
fprintf('运行时间: %.2f秒\n\n', Algorithm.metric.runtime);

%% 测试2：参数自定义测试
fprintf('========================================\n');
fprintf('测试2：参数自定义测试\n');
fprintf('========================================\n');

% 使用自定义参数
Algorithm2 = VPPSO('parameter',{2.0,1.5,0.6});
Problem2 = SOP_F1('N',50,'maxFE',10000,'D',30);

Algorithm2.Solve(Problem2);
BestSolution2 = Algorithm2.result{end}(1);

fprintf('自定义参数: c1=2.0, c2=1.5, rate=0.6\n');
fprintf('最优适应度: %.6e\n', BestSolution2.obj);
fprintf('运行时间: %.2f秒\n\n', Algorithm2.metric.runtime);

%% 测试3：不同问题测试
fprintf('========================================\n');
fprintf('测试3：不同问题测试\n');
fprintf('========================================\n');

problems = {@SOP_F1, @SOP_F2, @SOP_F5, @SOP_F6};
problemNames = {'SOP_F1 (Sphere)', 'SOP_F2 (Ellipsoid)', ...
                'SOP_F5 (Rastrigin)', 'SOP_F6 (Ackley)'};

results = zeros(length(problems), 1);

for i = 1:length(problems)
    Alg = VPPSO('outputFcn',@(~,~)[],'save',1);
    Pro = problems{i}('N',50,'maxFE',10000,'D',30);
    Alg.Solve(Pro);
    results(i) = Alg.result{end}(1).obj;
    fprintf('%s: %.6e\n', problemNames{i}, results(i));
end

fprintf('\n');

%% 测试4：收敛曲线测试
fprintf('========================================\n');
fprintf('测试4：收敛曲线测试\n');
fprintf('========================================\n');

Algorithm4 = VPPSO('save',-10);
Problem4 = SOP_F1('N',50,'maxFE',10000,'D',30);
Algorithm4.Solve(Problem4);

fprintf('收敛曲线数据点数: %d\n', size(Algorithm4.result,1));
fprintf('初始最优值: %.6e\n', Algorithm4.result{1,2}(1).obj);
fprintf('最终最优值: %.6e\n', Algorithm4.result{end,2}(1).obj);
fprintf('改进率: %.2f%%\n\n', ...
    (1 - Algorithm4.result{end,2}(1).obj/Algorithm4.result{1,2}(1).obj)*100);

%% 测试5：与标准PSO对比
fprintf('========================================\n');
fprintf('测试5：与标准PSO对比\n');
fprintf('========================================\n');

% VPPSO
AlgVPPSO = VPPSO('outputFcn',@(~,~)[],'save',1);
ProVPPSO = SOP_F1('N',50,'maxFE',10000,'D',30);
AlgVPPSO.Solve(ProVPPSO);
resultVPPSO = AlgVPPSO.result{end}(1).obj;

% PSO
AlgPSO = PSO('outputFcn',@(~,~)[],'save',1);
ProPSO = SOP_F1('N',50,'maxFE',10000,'D',30);
AlgPSO.Solve(ProPSO);
resultPSO = AlgPSO.result{end}(1).obj;

fprintf('VPPSO最优值: %.6e\n', resultVPPSO);
fprintf('PSO最优值:   %.6e\n', resultPSO);
if resultVPPSO < resultPSO
    fprintf('VPPSO性能更优 (提升 %.2f%%)\n', (1-resultVPPSO/resultPSO)*100);
else
    fprintf('PSO性能更优\n');
end

fprintf('\n========================================\n');
fprintf('所有测试完成！\n');
fprintf('========================================\n');
