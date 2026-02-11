# VPPSO - Variable Probability Particle Swarm Optimization

## 算法简介

VPPSO (Variable Probability Particle Swarm Optimization) 是一种改进的粒子群优化算法，采用双群策略和变概率更新机制。

### 核心特点

1. **双群策略**
   - 第一群：使用速度更新机制，维护个体历史最优
   - 第二群：直接在全局最优附近生成新位置

2. **变概率更新**
   - 30%概率进行速度更新
   - 增加种群多样性，避免早熟收敛

3. **动态惯性权重**
   - 随进化过程自适应调整
   - 平衡全局探索与局部开发

## 算法参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| c1   | 1.5    | 认知系数 |
| c2   | 1.2    | 社会系数 |
| rate | 0.5    | 第一群占总种群的比例 |

## 使用方法

### 方法1：GUI界面
```matlab
platemo
% 在GUI中选择VPPSO算法和测试问题
```

### 方法2：命令行（默认参数）
```matlab
platemo('algorithm',@VPPSO,'problem',@SOP_F1);
```

### 方法3：命令行（自定义参数）
```matlab
% 设置 c1=2.0, c2=1.5, rate=0.6
platemo('algorithm',{@VPPSO,2.0,1.5,0.6},'problem',@SOP_F1,'N',100,'maxFE',50000);
```

### 方法4：编程调用
```matlab
% 创建算法对象
Algorithm = VPPSO('parameter',{1.5,1.2,0.5});

% 创建问题对象
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);

% 运行算法
Algorithm.Solve(Problem);

% 获取结果
BestSolution = Algorithm.result{end}(1);
fprintf('最优适应度: %.6e\n', BestSolution.obj);
fprintf('最优解: ');
disp(BestSolution.dec);
```

## 算法流程

```
1. 初始化
   ├─ 生成初始种群
   ├─ 初始化个体最优Pbest
   └─ 初始化全局最优Gbest

2. 主循环（直到满足终止条件）
   ├─ 计算动态惯性权重 ww
   ├─ 更新第一群（有速度）
   │  ├─ 以30%概率更新速度
   │  ├─ 速度限制
   │  ├─ 更新位置
   │  └─ 边界检查
   ├─ 更新个体最优Pbest
   ├─ 更新第二群（无速度）
   │  ├─ 在Gbest附近生成新位置
   │  └─ 边界检查
   └─ 更新全局最优Gbest

3. 返回最优解
```

## 关键公式

### 动态惯性权重（Equ. 12）
```matlab
ww = exp(-(2.5 * FE/maxFE)^2.5)
```

### 第一群速度更新（Equ. 13）
```matlab
if rand < 0.3
    V = |V|^(rand*ww) + rand*c1*(Pbest-X) + rand*c2*(Gbest-X)
end
```

### 第二群位置更新（Equ. 15）
```matlab
CC = ww * rand * |Gbest|^ww
if rand < 0.5
    X = Gbest + CC
else
    X = Gbest - CC
end
```

## 适用问题

- ✅ 单目标优化
- ✅ 连续变量
- ✅ 实数/整数编码
- ✅ 大规模优化
- ✅ 无约束/有约束问题

## 测试示例

### 运行测试脚本
```matlab
% 运行完整测试
run('Algorithms/Single-objective optimization/VPPSO/Test_VPPSO.m')
```

### 快速测试
```matlab
% 测试Sphere函数
Algorithm = VPPSO();
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);
Algorithm.Solve(Problem);
fprintf('最优值: %.6e\n', Algorithm.result{end}(1).obj);
```

## 性能建议

### 参数调优建议

1. **c1和c2**
   - 默认值(1.5, 1.2)适用于大多数问题
   - 增大c1：增强局部搜索能力
   - 增大c2：增强全局搜索能力

2. **rate**
   - 默认值0.5平衡两个群的作用
   - 增大rate：增强局部搜索（第一群更多）
   - 减小rate：增强全局探索（第二群更多）

3. **种群大小N**
   - 建议使用偶数
   - 低维问题：30-50
   - 高维问题：50-100

### 问题类型建议

| 问题类型 | 推荐配置 |
|---------|---------|
| 单峰函数 | c1=1.5, c2=1.2, rate=0.6 |
| 多峰函数 | c1=1.5, c2=1.2, rate=0.4 |
| 高维问题 | c1=2.0, c2=1.5, rate=0.5 |

## 与其他算法对比

```matlab
% 对比VPPSO、PSO、GA
platemo('algorithm',{@VPPSO,@PSO,@GA},'problem',@SOP_F1,'N',50,'maxFE',10000);
```

## 文件说明

- `VPPSO.m` - 算法主文件
- `Test_VPPSO.m` - 测试脚本
- `VPPSO_PlatEMO_Adaptation.md` - 详细改造说明
- `README.md` - 本文件

## 参考信息

- 原始实现来源：淘个代码
- PlatEMO平台改造：2024
- 算法类型：单目标优化
- 编码类型：实数/整数

## 注意事项

1. 种群大小建议使用偶数，以便均分两个群
2. rate参数建议在0.3-0.7之间
3. 对于高维问题，可能需要增加种群大小和评估次数
4. 第二群不维护速度信息，节省内存

## 常见问题

**Q: 如何查看收敛曲线？**
```matlab
Algorithm = VPPSO('save',-10);
Problem = SOP_F1('N',50,'maxFE',10000);
Algorithm.Solve(Problem);
% 结果会自动显示收敛曲线图
```

**Q: 如何保存结果到文件？**
```matlab
Algorithm = VPPSO('save',10);  % 保存10个检查点
Problem = SOP_F1('N',50,'maxFE',10000);
Algorithm.Solve(Problem);
% 结果自动保存到 Data/VPPSO/ 目录
```

**Q: 如何在自定义问题上使用？**
```matlab
% 使用UserProblem定义自定义问题
Problem = UserProblem('N',50,'maxFE',10000,'D',10, ...
    'lower',-5,'upper',5,'objFcn',@(x)sum(x.^2,2));
Algorithm = VPPSO();
Algorithm.Solve(Problem);
```

## 更新日志

- 2024: 改造为PlatEMO平台算法
- 原始版本: 函数式实现

## 联系方式

如有问题或建议，请通过PlatEMO平台反馈。
