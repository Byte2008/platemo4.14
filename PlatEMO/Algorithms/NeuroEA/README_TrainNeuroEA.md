# NeuroEA参数训练说明

## 概述
`TrainNeuroEA_GA.m` 文件实现了使用遗传算法(GA)自动训练NeuroEA算法参数的功能。

## 功能特点

### ✅ 已完成的功能
1. **参数训练** - 使用GA算法优化NeuroEA的所有Block参数
2. **性能评估** - 通过多次运行评估参数的平均性能和稳定性
3. **参数保存** - 自动将最优参数保存到 `trained_params.mat` 文件
4. **结果返回** - 返回完整的训练结果，包括最优参数、性能指标等

## 使用方法

### 基本用法
```matlab
% 运行参数训练
result = TrainNeuroEA_GA();

% 查看训练结果
fprintf('最优目标值: %.6f\n', result.BestScore);
fprintf('参数保存位置: %s\n', result.SavedFile);
```

### 加载训练好的参数
```matlab
% 加载保存的参数
load('Algorithms/NeuroEA/trained_params.mat', 'bestDec', 'bestObj', 'Blocks', 'Graph');

% 使用训练好的参数运行NeuroEA
Blocks.ParameterSet(bestDec);
ALG = NeuroEA('parameter', {Blocks, Graph});
```

## 训练配置

### 当前配置
- **训练器**: GA (遗传算法)
- **种群大小**: 50
- **最大评估次数**: 10000
- **测试问题**: SOP_F1 (单目标优化问题)
- **重复运行次数**: 3次 (用于评估稳定性)

### Block结构
```matlab
Blocks = [
    Block_Population,           % 种群块
    Block_Tournament(200,10),   % 锦标赛选择块
    Block_Crossover(2,5),       % 交叉块
    Block_Mutation(5),          % 变异块
    Block_Selection(100)        % 选择块
];
```

### 连接图
```
Population -> Tournament -> Crossover -> Mutation -> Selection -> Population
```

## 保存的文件

训练完成后，以下内容会保存到 `Algorithms/NeuroEA/trained_params.mat`:
- `bestDec` - 最优参数向量
- `bestObj` - 最优目标函数值
- `Blocks` - 配置好的Block数组
- `Graph` - Block连接图

## 自定义训练

### 修改训练配置
如需修改训练配置，可以编辑以下部分：

```matlab
% 修改种群大小和最大评估次数
trainerProblem = UserProblem('N',100,'maxFE',20000, ...);

% 修改重复运行次数
R = 5;  % 在trainObj函数中修改
```

### 更换测试问题
```matlab
% 使用其他测试问题
PRO = SOP_F2();  % 或其他问题
```

## 注意事项

1. 训练过程可能需要较长时间，取决于配置的评估次数
2. 每次训练会覆盖之前保存的参数文件
3. 建议在训练前备份重要的参数文件
4. 目标函数同时优化性能(均值)和稳定性(标准差)

## 返回值说明

`TrainNeuroEA_GA()` 返回的结构体包含：
- `BestParam` - 最优参数向量
- `BestScore` - 最优目标函数值
- `Trainer` - 训练器对象(GA)
- `TrainerProblem` - 训练问题对象
- `Blocks` - 配置好的Block数组
- `Graph` - 连接图
- `SavedFile` - 参数文件保存路径
