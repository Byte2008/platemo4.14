# VPPSO 快速开始指南

## 5分钟上手VPPSO

### 1️⃣ 最简单的使用（GUI）

```matlab
platemo
```
在GUI界面中：
1. 选择算法：VPPSO
2. 选择问题：SOP_F1
3. 点击"Start"

---

### 2️⃣ 命令行快速测试

```matlab
% 使用默认参数
platemo('algorithm',@VPPSO,'problem',@SOP_F1);
```

---

### 3️⃣ 自定义参数

```matlab
% 设置参数：c1=2.0, c2=1.5, rate=0.6
platemo('algorithm',{@VPPSO,2.0,1.5,0.6},'problem',@SOP_F1,'N',100,'maxFE',50000);
```

---

### 4️⃣ 编程调用

```matlab
% 创建算法和问题
Algorithm = VPPSO('parameter',{1.5,1.2,0.5});
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);

% 运行
Algorithm.Solve(Problem);

% 查看结果
fprintf('最优值: %.6e\n', Algorithm.result{end}(1).obj);
```

---

### 5️⃣ 查看收敛曲线

```matlab
Algorithm = VPPSO('save',-10);
Problem = SOP_F1('N',50,'maxFE',10000);
Algorithm.Solve(Problem);
% 自动显示收敛曲线图
```

---

### 6️⃣ 保存结果到文件

```matlab
Algorithm = VPPSO('save',10);  % 保存10个检查点
Problem = SOP_F1('N',50,'maxFE',10000);
Algorithm.Solve(Problem);
% 结果自动保存到 Data/VPPSO/ 目录
```

---

### 7️⃣ 运行完整测试

```matlab
run('Algorithms/Single-objective optimization/VPPSO/Test_VPPSO.m')
```

---

## 参数说明

| 参数 | 默认值 | 说明 | 推荐范围 |
|------|--------|------|---------|
| c1   | 1.5    | 认知系数 | 1.0-2.5 |
| c2   | 1.2    | 社会系数 | 1.0-2.5 |
| rate | 0.5    | 第一群比例 | 0.3-0.7 |

---

## 常用测试问题

```matlab
% 单峰函数
platemo('algorithm',@VPPSO,'problem',@SOP_F1);  % Sphere
platemo('algorithm',@VPPSO,'problem',@SOP_F2);  % Ellipsoid

% 多峰函数
platemo('algorithm',@VPPSO,'problem',@SOP_F5);  % Rastrigin
platemo('algorithm',@VPPSO,'problem',@SOP_F6);  % Ackley
```

---

## 与其他算法对比

```matlab
% 对比VPPSO、PSO、GA
platemo('algorithm',{@VPPSO,@PSO,@GA},'problem',@SOP_F1);
```

---

## 自定义问题

```matlab
% 定义自己的目标函数
myFunc = @(x) sum(x.^2,2);  % Sphere函数

% 创建问题
Problem = UserProblem('N',50,'maxFE',10000,'D',10, ...
    'lower',-5,'upper',5,'objFcn',myFunc);

% 运行算法
Algorithm = VPPSO();
Algorithm.Solve(Problem);
```

---

## 获取详细结果

```matlab
Algorithm = VPPSO();
Problem = SOP_F1('N',50,'maxFE',10000,'D',30);
Algorithm.Solve(Problem);

% 最优解
BestSolution = Algorithm.result{end}(1);
fprintf('最优值: %.6e\n', BestSolution.obj);
fprintf('最优解: ');
disp(BestSolution.dec);

% 运行时间
fprintf('运行时间: %.2f秒\n', Algorithm.metric.runtime);

% 最终种群
FinalPopulation = Algorithm.result{end};
fprintf('种群大小: %d\n', length(FinalPopulation));
```

---

## 多次运行统计

```matlab
results = zeros(30,1);
for run = 1:30
    Algorithm = VPPSO('outputFcn',@(~,~)[],'save',1);
    Problem = SOP_F1('N',50,'maxFE',10000,'D',30);
    Algorithm.Solve(Problem);
    results(run) = Algorithm.result{end}(1).obj;
end

fprintf('平均值: %.6e ± %.6e\n', mean(results), std(results));
fprintf('最优值: %.6e\n', min(results));
fprintf('最差值: %.6e\n', max(results));
```

---

## 常见问题

**Q: 如何加快运行速度？**
```matlab
% 禁用输出函数
Algorithm = VPPSO('outputFcn',@(~,~)[]);
```

**Q: 如何调整种群大小？**
```matlab
Problem = SOP_F1('N',100);  % 设置种群大小为100
```

**Q: 如何增加评估次数？**
```matlab
Problem = SOP_F1('maxFE',50000);  % 设置最大评估次数为50000
```

**Q: 如何改变问题维度？**
```matlab
Problem = SOP_F1('D',50);  % 设置维度为50
```

---

## 下一步

- 📖 阅读 `README.md` 了解更多细节
- 📊 运行 `Test_VPPSO.m` 查看完整测试
- 🔍 查看 `VPPSO_PlatEMO_Adaptation.md` 了解改造过程
- 📚 阅读 `PlatEMO_Algorithm_Development_Guide.md` 学习开发

---

**开始使用VPPSO吧！** 🚀
