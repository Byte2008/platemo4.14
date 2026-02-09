# trainer.Solve(trainerProblem) 详细工作流程

## 概述
`trainer.Solve(trainerProblem)` 这行代码启动了遗传算法(GA)的完整优化过程，用于寻找NeuroEA算法的最优参数配置。

---

## 完整工作流程

### 第一阶段：初始化 (Solve方法)

```matlab
% 位置：ALGORITHM.Solve() 方法
trainer.Solve(trainerProblem)
```

**执行步骤：**

1. **重置结果存储**
   ```matlab
   obj.result = {};              % 清空之前的结果
   obj.metric = struct('runtime',0);  % 重置性能指标
   ```

2. **设置问题对象**
   ```matlab
   obj.pro = Problem;            % 保存问题对象引用
   obj.pro.FE = 0;              % 函数评估次数归零
   ```

3. **记录开始时间**
   ```matlab
   obj.starttime = tic;         % 开始计时
   ```

4. **调用主算法**
   ```matlab
   obj.main(obj.pro);           % 调用GA的main方法
   ```

---

### 第二阶段：遗传算法主循环 (GA.main方法)

```matlab
% 位置：GA.main() 方法
function main(Algorithm,Problem)
```

#### 步骤1：参数设置
```matlab
[proC,disC,proM,disM] = Algorithm.ParameterSet(1,20,1,20);
```
- `proC = 1` : 交叉概率
- `disC = 20` : 模拟二进制交叉的分布指数
- `proM = 1` : 变异变量数的期望
- `disM = 20` : 多项式变异的分布指数

#### 步骤2：生成初始种群
```matlab
Population = Problem.Initialization();
```

**这里会调用 UserProblem 的初始化，进而调用我们定义的 trainInit 函数：**

```matlab
function PopDec = trainInit(N)
    % N = 50 (种群大小)
    % 生成50个个体，每个个体是一组NeuroEA的参数配置
    PopDec = unifrnd(repmat(Blocks.lowers,N,1), repmat(Blocks.uppers,N,1));
end
```

**然后评估初始种群：**
- 对每个个体调用 `trainObj(PopDec)` 计算目标函数值
- 每个参数配置运行NeuroEA算法3次，计算平均性能和稳定性

#### 步骤3：进化循环
```matlab
while Algorithm.NotTerminated(Population)
    % 3.1 锦标赛选择
    MatingPool = TournamentSelection(2,Problem.N,FitnessSingle(Population));
    
    % 3.2 遗传操作（交叉和变异）
    Offspring = OperatorGA(Problem,Population(MatingPool),{proC,disC,proM,disM});
    
    % 3.3 合并种群
    Population = [Population,Offspring];
    
    % 3.4 环境选择（保留最优的N个个体）
    [~,rank] = sort(FitnessSingle(Population));
    Population = Population(rank(1:Problem.N));
end
```

**详细说明每个子步骤：**

##### 3.1 锦标赛选择
- 从当前种群中选择父代个体
- 每次随机选2个个体，保留适应度更好的
- 重复N次，得到N个父代

##### 3.2 遗传操作
- **交叉**：两两配对，按proC概率进行模拟二进制交叉
- **变异**：对每个后代，按proM期望变异若干个变量
- **评估**：对每个新生成的后代调用 `trainObj` 评估性能

**trainObj 的工作流程：**
```matlab
function PopObj = trainObj(PopDec)
    R = 3;  % 重复3次
    for i = 1 : size(PopDec,1)  % 对每个后代
        Blocks.ParameterSet(PopDec(i,:));  % 设置参数
        for j = 1 : R
            ALG.Solve(PRO);  % 运行NeuroEA求解SOP_F1
            PopObj(i,j) = PRO.CalMetric('Min_value',ALG.result{end});
        end
    end
    PopObj = mean(PopObj,2) + std(PopObj,0,2);  % 均值+标准差
end
```

##### 3.3 合并种群
- 将父代(N个)和子代(N个)合并，得到2N个个体

##### 3.4 环境选择
- 按适应度排序
- 保留最优的N个个体进入下一代

---

### 第三阶段：终止条件检查 (NotTerminated方法)

```matlab
% 位置：ALGORITHM.NotTerminated() 方法
while Algorithm.NotTerminated(Population)
```

**每次迭代都会执行：**

1. **更新运行时间**
   ```matlab
   obj.metric.runtime = obj.metric.runtime + toc(obj.starttime);
   ```

2. **保存当前种群**
   ```matlab
   index = ceil(num*obj.pro.FE/obj.pro.maxFE);
   obj.result(index,:) = {obj.pro.FE,Population};
   ```

3. **调用输出函数**
   ```matlab
   obj.outputFcn(obj,obj.pro);  % 在TrainNeuroEA_GA中设为空函数
   ```

4. **检查是否终止**
   ```matlab
   nofinish = obj.pro.FE < obj.pro.maxFE;  % FE < 10000?
   ```

5. **重新计时**
   ```matlab
   obj.starttime = tic;
   ```

---

## 关键数据流

### 输入数据
```matlab
trainerProblem = UserProblem(
    'N', 50,                          % 种群大小
    'maxFE', 10000,                   % 最大评估次数
    'D', length(Blocks.parameters),   % 参数维度
    'lower', Blocks.lowers,           % 参数下界
    'upper', Blocks.uppers,           % 参数上界
    'initFcn', @trainInit,            % 初始化函数
    'objFcn', @trainObj               % 目标函数
);
```

### 输出数据
```matlab
trainer.result{end}  % 最终种群
    .decs            % 每个个体的参数配置
    .objs            % 每个个体的目标函数值
```

---

## 计算量估算

假设配置如下：
- 种群大小 N = 50
- 最大评估次数 maxFE = 10000
- 每个参数配置重复运行 R = 3 次

**总计算量：**
- 初始种群评估：50 × 3 = 150 次 NeuroEA运行
- 进化过程：约 (10000 - 50) × 3 = 29,850 次 NeuroEA运行
- **总共约 30,000 次 NeuroEA算法运行**

每次NeuroEA运行都会在SOP_F1问题上进行完整的优化过程，因此训练时间较长。

---

## 优化策略

目标函数设计：
```matlab
PopObj = mean(PopObj,2) + std(PopObj,0,2);
```

这个设计同时优化两个目标：
1. **mean(PopObj,2)** - 平均性能（越小越好）
2. **std(PopObj,0,2)** - 稳定性（标准差越小越稳定）

通过相加，GA会寻找既性能好又稳定的参数配置。

---

## 总结

`trainer.Solve(trainerProblem)` 完成的工作：

1. ✅ 初始化50个随机参数配置
2. ✅ 评估每个配置的性能（运行3次取均值+标准差）
3. ✅ 通过遗传算法迭代优化（选择、交叉、变异）
4. ✅ 持续进化直到达到10000次函数评估
5. ✅ 保存所有中间结果到 trainer.result
6. ✅ 返回最优参数配置

最终，我们从 `trainer.result{end}` 中提取性能最好的参数配置，并保存到文件中。
