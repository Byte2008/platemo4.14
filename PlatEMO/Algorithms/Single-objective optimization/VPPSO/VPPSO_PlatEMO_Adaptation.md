# VPPSO算法改造说明

## 改造概述
将原始的VPPSO函数式实现改造为符合PlatEMO平台规范的面向对象实现。

---

## PlatEMO平台算法开发原理

### 核心设计模式

#### 1. 类继承结构
```matlab
classdef VPPSO < ALGORITHM
```
- 所有算法必须继承自 `ALGORITHM` 基类
- 基类提供统一的接口和功能（参数管理、结果保存、终止条件等）

#### 2. 主函数签名
```matlab
function main(Algorithm,Problem)
```
- `Algorithm` - 算法对象本身，用于访问参数和方法
- `Problem` - 问题对象，提供问题相关信息和评估接口

#### 3. 参数管理
```matlab
[c1,c2,rate] = Algorithm.ParameterSet(1.5,1.2,0.5);
```
- 使用 `ParameterSet` 方法获取参数
- 参数可以在创建算法时覆盖默认值
- 格式：`[param1,param2,...] = Algorithm.ParameterSet(default1,default2,...)`

#### 4. 种群初始化
```matlab
Population = Problem.Initialization();
```
- 使用 `Problem.Initialization()` 生成初始种群
- 返回 `SOLUTION` 对象数组
- 自动处理边界约束和评估

#### 5. 终止条件
```matlab
while Algorithm.NotTerminated(Population)
```
- `NotTerminated` 方法自动管理：
  - 函数评估次数检查
  - 运行时间记录
  - 结果保存
  - 输出函数调用

#### 6. 个体评估
```matlab
Offspring = Problem.Evaluation(OffDec,OffVel);
```
- 使用 `Problem.Evaluation()` 评估新个体
- 第一个参数：决策变量矩阵
- 第二个参数（可选）：附加数据（如速度）
- 返回 `SOLUTION` 对象数组

#### 7. SOLUTION对象
```matlab
Population.decs    % 获取决策变量矩阵
Population.objs    % 获取目标函数值
Population.adds()  % 获取附加数据（如速度）
```

---

## 原始VPPSO与改造后的对比

### 原始实现的问题

1. **函数式接口**
   ```matlab
   function [gbest_fitness,gbest,Fitness_Curve]= VPPSO(NT,max_iteration,lb,ub,dim,fobj)
   ```
   - 不符合PlatEMO的面向对象架构
   - 参数传递方式不统一

2. **手动边界处理**
   ```matlab
   lb=lb.*ones(1,dim);
   ub=ub.*ones(1,dim);
   ```
   - PlatEMO的Problem对象已经包含边界信息

3. **手动初始化**
   ```matlab
   Position(i,:)=X_min+(X_max-X_min).*rand(1,dim);
   ```
   - PlatEMO提供统一的初始化接口

4. **手动终止条件**
   ```matlab
   for t=1:max_iteration
   ```
   - PlatEMO自动管理终止条件

5. **手动适应度计算**
   ```matlab
   fitness(i)=fobj(Position(i,:));
   ```
   - PlatEMO通过Problem.Evaluation统一管理

---

## 改造要点详解

### 1. 类结构改造

**原始：**
```matlab
function [gbest_fitness,gbest,Fitness_Curve]= VPPSO(NT,max_iteration,lb,ub,dim,fobj)
```

**改造后：**
```matlab
classdef VPPSO < ALGORITHM
    methods
        function main(Algorithm,Problem)
```

**改造说明：**
- 从函数改为类方法
- 继承ALGORITHM基类获得平台功能
- 使用统一的main方法签名

---

### 2. 参数获取改造

**原始：**
```matlab
N = round(NT*0.5);
c1 = 1.5;
c2 = 1.2;
```

**改造后：**
```matlab
[c1,c2,rate] = Algorithm.ParameterSet(1.5,1.2,0.5);
N = round(Problem.N * rate);
```

**改造说明：**
- 使用ParameterSet统一管理参数
- 参数可在算法创建时覆盖
- 种群大小从Problem对象获取

---

### 3. 初始化改造

**原始：**
```matlab
for i=1:N
    Position(i,:)=X_min+(X_max-X_min).*rand(1,dim);
    Velocity(i,:)=zeros(1,dim);
    fitness(i)=fobj(Position(i,:));
    Pbest(i,:)=Position(i,:);
    ...
end
```

**改造后：**
```matlab
Population = Problem.Initialization();
Pbest = Population(1:N);
[~,best] = min(FitnessSingle(Population));
Gbest = Population(best);
```

**改造说明：**
- 使用Problem.Initialization()自动生成种群
- 返回已评估的SOLUTION对象
- 简化代码，减少错误

---

### 4. 主循环改造

**原始：**
```matlab
for t=1:max_iteration
    ww(t) = exp(-(2.5*t/max_iteration)^2.5);
    % 更新操作
    ...
end
```

**改造后：**
```matlab
while Algorithm.NotTerminated(Population)
    ww = exp(-(2.5*Problem.FE/Problem.maxFE)^2.5);
    % 更新操作
    ...
end
```

**改造说明：**
- 使用NotTerminated自动管理终止条件
- 使用Problem.FE获取当前评估次数
- 自动保存结果和调用输出函数

---

### 5. 速度更新改造

**原始：**
```matlab
if rand<0.3
    Velocity(i,:)= abs(Velocity(i,:)).^(rand*ww(t)) + ...
                   rand*c1*(Pbest(i,:)-Position(i,:)) + ...
                   rand*c2*(gbest-Position(i,:));
end
```

**改造后：**
```matlab
ParticleVel = Particle.adds(zeros(N,D));
for i = 1:N
    if rand < 0.3
        OffVel(i,:) = abs(ParticleVel(i,:)).^(rand*ww) + ...
                      rand*c1*(PbestDec(i,:)-ParticleDec(i,:)) + ...
                      rand*c2*(GbestDec(i,:)-ParticleDec(i,:));
    end
end
```

**改造说明：**
- 使用adds()方法获取速度信息
- 从SOLUTION对象提取决策变量
- 保持原始算法逻辑不变

---

### 6. 边界处理改造

**原始：**
```matlab
index_Pos_ub=find(Position(i,:)> ub);
index_Pos_lb=find(Position(i,:)< lb);
Position(i, index_Pos_ub) = ub(index_Pos_ub);
Position(i, index_Pos_lb) = lb(index_Pos_lb);
```

**改造后：**
```matlab
OffDec = max(min(OffDec,repmat(Problem.upper,N,1)),repmat(Problem.lower,N,1));
```

**改造说明：**
- 使用Problem.upper和Problem.lower获取边界
- 使用向量化操作提高效率
- 代码更简洁

---

### 7. 评估改造

**原始：**
```matlab
fitness(i)=fobj(Position(i,:));
```

**改造后：**
```matlab
Offspring = Problem.Evaluation(OffDec,OffVel);
```

**改造说明：**
- 使用Problem.Evaluation统一评估
- 自动更新函数评估计数
- 返回完整的SOLUTION对象

---

### 8. 适应度比较改造

**原始：**
```matlab
if fitness(i)< Pbest_finess(i)
    Pbest(i,:)=Position(i,:);
    Pbest_finess(i)=fitness(i);
end
```

**改造后：**
```matlab
replace = FitnessSingle(Pbest) > FitnessSingle(Population(1:N));
Pbest(replace) = Population(replace);
```

**改造说明：**
- 使用FitnessSingle获取适应度
- 向量化操作替代循环
- 提高代码效率

---

## 算法结构对比

### 原始VPPSO结构
```
1. 参数设置（硬编码）
2. 初始化种群（手动循环）
3. 主循环（固定迭代次数）
   ├─ 计算惯性权重
   ├─ 更新第一群（有速度）
   │  ├─ 速度更新
   │  ├─ 速度限制
   │  ├─ 位置更新
   │  └─ 边界检查
   ├─ 更新第二群（无速度）
   │  ├─ 位置更新
   │  └─ 边界检查
   ├─ 适应度评估
   ├─ 更新Pbest
   └─ 更新Gbest
4. 返回结果
```

### 改造后VPPSO结构
```
1. 参数设置（ParameterSet）
2. 初始化种群（Problem.Initialization）
3. 初始化Pbest和Gbest
4. 主循环（NotTerminated）
   ├─ 计算惯性权重
   ├─ 更新第一群（UpdateFirstSwarm）
   │  ├─ 获取速度
   │  ├─ 速度更新（变概率）
   │  ├─ 速度限制
   │  ├─ 位置更新
   │  ├─ 边界检查
   │  └─ 评估
   ├─ 更新Pbest
   ├─ 更新第二群（UpdateSecondSwarm）
   │  ├─ 位置更新（基于Gbest）
   │  ├─ 边界检查
   │  └─ 评估
   └─ 更新Gbest
```

---

## 关键改进

### 1. 模块化设计
- 将第一群和第二群的更新分离为独立函数
- 提高代码可读性和可维护性

### 2. 向量化操作
- 减少循环使用
- 提高计算效率

### 3. 统一接口
- 符合PlatEMO平台规范
- 可与其他算法和问题无缝集成

### 4. 自动化管理
- 终止条件自动检查
- 结果自动保存
- 性能指标自动计算

---

## 使用示例

### 基本使用
```matlab
% 使用默认参数
platemo('algorithm',@VPPSO,'problem',@SOP_F1);
```

### 自定义参数
```matlab
% 自定义参数：c1=2.0, c2=1.5, rate=0.6
platemo('algorithm',{@VPPSO,2.0,1.5,0.6},'problem',@SOP_F1);
```

### 编程调用
```matlab
% 创建算法和问题对象
Algorithm = VPPSO('parameter',{2.0,1.5,0.6});
Problem = SOP_F1('N',100,'maxFE',50000);

% 运行算法
Algorithm.Solve(Problem);

% 获取结果
BestSolution = Algorithm.result{end}(1);
fprintf('Best fitness: %.6f\n', BestSolution.obj);
```

---

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| c1   | 1.5    | 认知系数，控制粒子向个体最优位置移动的程度 |
| c2   | 1.2    | 社会系数，控制粒子向全局最优位置移动的程度 |
| rate | 0.5    | 第一群占总种群的比例（0-1之间） |

---

## 算法特点

### 双群策略
1. **第一群（有速度）**
   - 使用变概率速度更新机制
   - 维护个体历史最优
   - 适合局部搜索

2. **第二群（无速度）**
   - 直接在全局最优附近生成新位置
   - 不维护历史信息
   - 适合全局探索

### 动态惯性权重
```matlab
ww = exp(-(2.5*Problem.FE/Problem.maxFE)^2.5)
```
- 随进化过程动态调整
- 前期大，后期小
- 平衡探索与开发

### 变概率更新
- 30%概率进行速度更新
- 增加种群多样性
- 避免早熟收敛

---

## 测试验证

### 建议测试问题
```matlab
% 单峰函数
platemo('algorithm',@VPPSO,'problem',@SOP_F1);  % Sphere
platemo('algorithm',@VPPSO,'problem',@SOP_F2);  % Ellipsoid

% 多峰函数
platemo('algorithm',@VPPSO,'problem',@SOP_F5);  % Rastrigin
platemo('algorithm',@VPPSO,'problem',@SOP_F6);  % Ackley
```

### 性能对比
```matlab
% 与标准PSO对比
platemo('algorithm',{@PSO,@VPPSO},'problem',@SOP_F1,'N',50,'maxFE',50000);
```

---

## 注意事项

1. **种群大小**：建议使用偶数，以便均分两个群
2. **rate参数**：建议在0.3-0.7之间，默认0.5效果较好
3. **问题类型**：适用于连续优化问题
4. **维度**：对高维问题表现良好

---

## 总结

改造后的VPPSO算法：
- ✅ 完全符合PlatEMO平台规范
- ✅ 保持原始算法的核心思想
- ✅ 代码结构清晰，易于维护
- ✅ 可与平台其他功能无缝集成
- ✅ 支持参数自定义
- ✅ 自动化结果管理
