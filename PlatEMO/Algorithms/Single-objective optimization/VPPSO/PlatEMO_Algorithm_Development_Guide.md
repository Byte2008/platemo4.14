# PlatEMO算法开发指南

基于CSO、GA和VPPSO的改造经验总结

---

## 一、PlatEMO平台核心设计原则

### 1.1 面向对象架构

```
ALGORITHM (基类)
    ├─ 参数管理
    ├─ 结果保存
    ├─ 终止条件
    ├─ 性能指标
    └─ 输出控制
    
具体算法 (子类)
    └─ main方法 (实现优化逻辑)
```

### 1.2 统一接口设计

所有算法遵循相同的接口规范：
- 继承ALGORITHM基类
- 实现main(Algorithm,Problem)方法
- 使用标准的参数管理机制
- 使用标准的种群评估接口

---

## 二、算法开发模板

### 2.1 基本模板

```matlab
classdef AlgorithmName < ALGORITHM
% <year> <type> <encoding> <scale> <constraint>
% Algorithm full name
% param1 --- default1 --- Description of param1
% param2 --- default2 --- Description of param2

%------------------------------- Reference --------------------------------
% Author. Title. Journal/Conference, Year, Volume(Issue): Pages.
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
            [param1,param2] = Algorithm.ParameterSet(default1,default2);
            
            %% Generate random population
            Population = Problem.Initialization();
            
            %% Optimization
            while Algorithm.NotTerminated(Population)
                % Your optimization logic here
            end
        end
    end
end
```

### 2.2 模板说明

#### 类注释格式
```matlab
% <year> <type> <encoding> <scale> <constraint>
```

- `year`: 算法发表年份
- `type`: 算法类型
  - `single`: 单目标
  - `multi`: 多目标
- `encoding`: 编码类型
  - `real`: 实数
  - `integer`: 整数
  - `binary`: 二进制
  - `permutation`: 排列
  - `label`: 标签
- `scale`: 规模
  - `none`: 普通规模
  - `large`: 大规模
- `constraint`: 约束
  - `none`: 无约束
  - `constrained`: 有约束

#### 参数注释格式
```matlab
% paramName --- defaultValue --- Description
```

---

## 三、关键组件使用指南

### 3.1 参数管理

```matlab
%% 单个参数
param = Algorithm.ParameterSet(defaultValue);

%% 多个参数
[param1,param2,param3] = Algorithm.ParameterSet(default1,default2,default3);

%% 使用示例
% 在类注释中声明
% W --- 0.4 --- Inertia weight
% c1 --- 2.0 --- Cognitive coefficient

% 在main方法中获取
[W,c1] = Algorithm.ParameterSet(0.4,2.0);
```

**用户覆盖参数：**
```matlab
% 使用默认参数
Algorithm = AlgorithmName();

% 覆盖参数
Algorithm = AlgorithmName('parameter',{0.5,2.5});
```

---

### 3.2 种群初始化

```matlab
%% 基本初始化
Population = Problem.Initialization();
% 返回：N个已评估的SOLUTION对象

%% 获取种群信息
N = Problem.N;           % 种群大小
D = Problem.D;           % 决策变量维度
M = Problem.M;           % 目标函数数量
lower = Problem.lower;   % 下界
upper = Problem.upper;   % 上界
```

---

### 3.3 SOLUTION对象操作

```matlab
%% 获取决策变量
PopDec = Population.decs;  % N×D矩阵

%% 获取目标函数值
PopObj = Population.objs;  % N×M矩阵

%% 获取约束违反度
PopCon = Population.cons;  % N×1向量

%% 获取附加数据（如速度）
PopVel = Population.adds(zeros(N,D));  % N×D矩阵

%% 访问单个个体
BestSolution = Population(1);
dec = BestSolution.dec;   % 1×D向量
obj = BestSolution.obj;   % 1×M向量
```

---

### 3.4 个体评估

```matlab
%% 基本评估（只有决策变量）
Offspring = Problem.Evaluation(OffDec);

%% 带附加数据的评估（如速度）
Offspring = Problem.Evaluation(OffDec,OffVel);

%% 注意事项
% 1. OffDec必须是N×D矩阵
% 2. 评估会自动更新Problem.FE（函数评估次数）
% 3. 返回的是SOLUTION对象数组
```

---

### 3.5 终止条件

```matlab
%% 标准用法
while Algorithm.NotTerminated(Population)
    % 优化逻辑
end

%% NotTerminated自动完成的工作
% 1. 检查 Problem.FE < Problem.maxFE
% 2. 更新运行时间
% 3. 保存中间结果
% 4. 调用输出函数
% 5. 更新显示

%% 获取进度信息
FE = Problem.FE;           % 当前评估次数
maxFE = Problem.maxFE;     % 最大评估次数
progress = FE/maxFE;       % 进度百分比
```

---

### 3.6 适应度计算

```matlab
%% 单目标优化
Fitness = FitnessSingle(Population);
% 返回：N×1向量，值越小越好

%% 多目标优化
% 使用特定的适应度分配方法
% 如：非支配排序、拥挤距离等
```

---

## 四、常见算法模式

### 4.1 遗传算法模式（GA）

```matlab
function main(Algorithm,Problem)
    %% Parameter setting
    [proC,disC,proM,disM] = Algorithm.ParameterSet(1,20,1,20);
    
    %% Generate random population
    Population = Problem.Initialization();
    
    %% Optimization
    while Algorithm.NotTerminated(Population)
        % 1. 选择
        MatingPool = TournamentSelection(2,Problem.N,FitnessSingle(Population));
        
        % 2. 交叉和变异
        Offspring = OperatorGA(Problem,Population(MatingPool),{proC,disC,proM,disM});
        
        % 3. 环境选择
        Population = [Population,Offspring];
        [~,rank] = sort(FitnessSingle(Population));
        Population = Population(rank(1:Problem.N));
    end
end
```

---

### 4.2 粒子群算法模式（PSO）

```matlab
function main(Algorithm,Problem)
    %% Parameter setting
    W = Algorithm.ParameterSet(0.4);
    
    %% Generate random population
    Population = Problem.Initialization();
    Pbest = Population;
    [~,best] = min(FitnessSingle(Pbest));
    Gbest = Pbest(best);
    
    %% Optimization
    while Algorithm.NotTerminated(Population)
        % 1. 更新粒子
        Population = OperatorPSO(Problem,Population,Pbest,Gbest,W);
        
        % 2. 更新个体最优
        replace = FitnessSingle(Pbest) > FitnessSingle(Population);
        Pbest(replace) = Population(replace);
        
        % 3. 更新全局最优
        [~,best] = min(FitnessSingle(Pbest));
        Gbest = Pbest(best);
    end
end
```

---

### 4.3 竞争群算法模式（CSO）

```matlab
function main(Algorithm,Problem)
    %% Parameter setting
    phi = Algorithm.ParameterSet(0.1);
    
    %% Generate random population
    Population = Problem.Initialization();
    
    %% Optimization
    while Algorithm.NotTerminated(Population)
        % 1. 随机配对
        rank = randperm(Problem.N);
        loser = rank(1:end/2);
        winner = rank(end/2+1:end);
        
        % 2. 竞争确定胜负
        replace = FitnessSingle(Population(loser)) < FitnessSingle(Population(winner));
        temp = loser(replace);
        loser(replace) = winner(replace);
        winner(replace) = temp;
        
        % 3. 失败者学习
        LoserDec = Population(loser).decs;
        WinnerDec = Population(winner).decs;
        LoserVel = Population(loser).adds(zeros(size(LoserDec)));
        % ... 更新逻辑
        Population(loser) = Problem.Evaluation(LoserDec,LoserVel);
    end
end
```

---

## 五、辅助函数开发

### 5.1 算子函数模板

```matlab
function Offspring = OperatorName(Problem,Parent,param1,param2)
%OperatorName - Brief description
%
%   Off = OperatorName(Pro,P,param1,param2) detailed description
%
%   Example:
%       Offspring = OperatorName(Problem,Population,0.9,20)

    %% Get parent information
    ParentDec = Parent.decs;
    [N,D] = size(ParentDec);
    
    %% Operator logic
    OffDec = ...; % Your operator logic
    
    %% Evaluate offspring
    Offspring = Problem.Evaluation(OffDec);
end
```

### 5.2 选择函数示例

```matlab
function MatingPool = TournamentSelection(K,N,Fitness)
%TournamentSelection - Tournament selection
%
%   MatingPool = TournamentSelection(K,N,Fitness) performs K-tournament
%   selection to select N individuals from the population with fitness
%   values Fitness.

    MatingPool = zeros(1,N);
    for i = 1:N
        % 随机选择K个个体
        candidates = randperm(length(Fitness),K);
        % 选择适应度最好的
        [~,best] = min(Fitness(candidates));
        MatingPool(i) = candidates(best);
    end
end
```

---

## 六、调试和测试

### 6.1 基本测试

```matlab
%% 创建算法和问题
Algorithm = YourAlgorithm();
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);

%% 运行算法
Algorithm.Solve(Problem);

%% 检查结果
fprintf('最优值: %.6e\n', Algorithm.result{end}(1).obj);
fprintf('运行时间: %.2f秒\n', Algorithm.metric.runtime);
```

### 6.2 收敛性测试

```matlab
%% 保存收敛曲线
Algorithm = YourAlgorithm('save',-10);
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);
Algorithm.Solve(Problem);
% 自动显示收敛曲线
```

### 6.3 多次运行测试

```matlab
%% 运行30次取平均
results = zeros(30,1);
for run = 1:30
    Algorithm = YourAlgorithm('outputFcn',@(~,~)[],'save',1);
    Problem = SOP_F1('N',50,'maxFE',10000,'D',30);
    Algorithm.Solve(Problem);
    results(run) = Algorithm.result{end}(1).obj;
end

fprintf('平均值: %.6e\n', mean(results));
fprintf('标准差: %.6e\n', std(results));
fprintf('最优值: %.6e\n', min(results));
fprintf('最差值: %.6e\n', max(results));
```

---

## 七、常见问题和解决方案

### 7.1 速度信息管理

**问题：**如何在PSO类算法中管理速度？

**解决方案：**
```matlab
%% 初始化时不需要显式创建速度
Population = Problem.Initialization();
% 速度会在第一次调用adds时自动初始化为0

%% 获取速度
ParticleVel = Particle.adds(zeros(N,D));

%% 更新速度并评估
OffVel = ...; % 计算新速度
OffDec = ParticleDec + OffVel;
Offspring = Problem.Evaluation(OffDec,OffVel);
% 速度会自动存储在Offspring中
```

---

### 7.2 边界处理

**问题：**如何处理决策变量越界？

**解决方案：**
```matlab
%% 方法1：截断到边界
OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));

%% 方法2：随机重新初始化
for i = 1:N
    for j = 1:D
        if OffDec(i,j) < Problem.lower(j) || OffDec(i,j) > Problem.upper(j)
            OffDec(i,j) = unifrnd(Problem.lower(j),Problem.upper(j));
        end
    end
end

%% 方法3：反弹
OffDec = min(OffDec,repmat(Problem.upper,N,1));
OffDec = max(OffDec,repmat(Problem.lower,N,1));
```

---

### 7.3 动态参数

**问题：**如何实现随进化过程变化的参数？

**解决方案：**
```matlab
%% 基于评估次数
progress = Problem.FE / Problem.maxFE;
W = 0.9 - 0.5 * progress;  % 线性递减

%% 基于代数（需要手动计数）
gen = 0;
while Algorithm.NotTerminated(Population)
    gen = gen + 1;
    W = 0.9 * (0.4/0.9)^(gen/maxGen);  % 指数递减
    % ...
end

%% 基于性能
currentBest = min(FitnessSingle(Population));
if currentBest < threshold
    param = value1;
else
    param = value2;
end
```

---

### 7.4 多种群管理

**问题：**如何管理多个子种群？

**解决方案：**
```matlab
%% 方法1：使用数组索引
N1 = round(Problem.N * 0.5);
N2 = Problem.N - N1;

Population = Problem.Initialization();
Swarm1 = Population(1:N1);
Swarm2 = Population(N1+1:end);

%% 方法2：使用元胞数组
Swarms = cell(1,numSwarms);
for i = 1:numSwarms
    Swarms{i} = Problem.Initialization();
end
```

---

## 八、性能优化技巧

### 8.1 向量化操作

```matlab
%% 避免循环
% 不好的写法
for i = 1:N
    OffDec(i,:) = ParentDec(i,:) + rand(1,D) .* (BestDec - ParentDec(i,:));
end

% 好的写法
OffDec = ParentDec + rand(N,D) .* (repmat(BestDec,N,1) - ParentDec);
```

### 8.2 预分配内存

```matlab
%% 预分配
OffDec = zeros(N,D);
for i = 1:N
    OffDec(i,:) = ...; % 计算
end

%% 而不是动态增长
OffDec = [];
for i = 1:N
    OffDec = [OffDec; ...]; % 慢！
end
```

### 8.3 批量评估

```matlab
%% 一次评估所有个体
Offspring = Problem.Evaluation(OffDec);

%% 而不是逐个评估
for i = 1:N
    Offspring(i) = Problem.Evaluation(OffDec(i,:));
end
```

---

## 九、文档规范

### 9.1 算法文件注释

```matlab
classdef AlgorithmName < ALGORITHM
% <year> <type> <encoding> <scale> <constraint>
% Full algorithm name
% param1 --- default1 --- Description
% param2 --- default2 --- Description

%------------------------------- Reference --------------------------------
% Author. Title. Journal, Year, Volume(Issue): Pages.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group...
%--------------------------------------------------------------------------
```

### 9.2 README文件

建议为每个算法创建README.md，包含：
- 算法简介
- 参数说明
- 使用示例
- 性能建议
- 参考文献

---

## 十、发布检查清单

在发布算法前，确保：

- [ ] 继承ALGORITHM基类
- [ ] 实现main方法
- [ ] 使用ParameterSet管理参数
- [ ] 使用Problem.Initialization初始化
- [ ] 使用Algorithm.NotTerminated控制循环
- [ ] 使用Problem.Evaluation评估个体
- [ ] 添加完整的类注释
- [ ] 添加参考文献
- [ ] 测试基本功能
- [ ] 测试参数自定义
- [ ] 测试多个问题
- [ ] 创建README文档
- [ ] 无语法错误
- [ ] 代码格式规范

---

## 十一、学习资源

### 11.1 参考算法

- **GA**: 遗传算法基本模式
- **PSO**: 粒子群算法模式
- **CSO**: 竞争群算法模式
- **DE**: 差分进化算法模式
- **MOEA/D**: 多目标分解算法模式

### 11.2 关键文件

- `Algorithms/ALGORITHM.m` - 基类实现
- `Problems/PROBLEM.m` - 问题基类
- `Problems/SOLUTION.m` - 解对象
- `Algorithms/Utility functions/` - 常用算子

---

## 十二、总结

### 核心要点

1. **继承ALGORITHM基类**获得平台功能
2. **使用统一接口**保证兼容性
3. **向量化操作**提高效率
4. **模块化设计**提高可维护性
5. **规范注释**符合学术标准

### 开发流程

```
1. 理解原始算法
2. 设计类结构
3. 实现main方法
4. 开发辅助函数
5. 测试验证
6. 编写文档
7. 发布
```

### 改造价值

- 提升代码质量
- 增强可维护性
- 便于学术研究
- 易于分享传播
- 符合发表要求
