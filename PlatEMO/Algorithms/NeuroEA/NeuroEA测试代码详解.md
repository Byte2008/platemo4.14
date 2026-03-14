# PlatEMO NeuroEA 测试代码详解

## 概述

PlatEMO提供了两个测试模块用于验证训练后的NeuroEA算法：
1. **Algorithm Creation模块的测试功能** (`module_cre.m`) - 快速单次测试
2. **Test模块** (`module_test.m`) - 完整的算法性能测试

---

## 一、Algorithm Creation模块的测试功能

### 1.1 测试入口

**位置**: `GUI/module_cre.m` 第693-745行

**GUI界面**: Algorithm Creation → Testing面板（右下角）

### 1.2 测试流程

#### 步骤1: 算法对象创建
```matlab
% 从GUI画布获取Block和连接图
Blocks = obj.Graph.Nodes.block;
Graph  = adjacency(obj.Graph,'weighted');

% 验证算法有效性
Blocks.Validity(Graph);

% 创建NeuroEA实例
ALG = NeuroEA('parameter', {Blocks, Graph}, ...
              'outputFcn', @obj.outputFcnTest, ...
              'save', 1);
```

**关键参数**:
- `parameter`: 传入训练好的Blocks和Graph
- `outputFcn`: 输出函数，用于更新GUI进度
- `save`: 保存间隔（每1代保存一次结果）

#### 步骤2: 问题对象创建
```matlab
% 从GUI参数列表获取问题配置
[name, para] = GUI.GetParameterSetting(obj.app.listD.items(1));

% 创建问题实例
PRO = feval(name, 'N', para{1}, ...      % 种群大小
                  'M', para{2}, ...      % 目标数
                  'D', para{3}, ...      % 决策变量维度
                  obj.app.listD.items(1).label(4).Text, para{4}, ...
                  'parameter', para(5:end));
```

#### 步骤3: 执行算法
```matlab
% 运行算法求解问题
ALG.Solve(PRO);
```

### 1.3 输出函数 (outputFcnTest)

**位置**: `module_cre.m` 第847-854行

```matlab
function outputFcnTest(obj, Algorithm, Problem)
    % 检查是否点击了Stop按钮
    assert(strcmp(obj.app.buttonE(2).Enable,'on'), ...
           'PlatEMO:Termination', '');
    
    % 更新进度显示
    obj.app.labelE.Text = sprintf('%.2f%%', ...
                                  Problem.FE/Problem.maxFE*100);
    
    % 处理暂停功能
    if strcmp(obj.app.buttonE(1).Text, 'Continue')
        waitfor(obj.app.buttonE(1), 'Text');
    end
    
    % 再次检查Stop状态
    assert(strcmp(obj.app.buttonE(2).Enable,'on'), ...
           'PlatEMO:Termination', '');
end
```

**功能**:
- 实时更新进度百分比
- 支持暂停/继续功能
- 支持中途停止

### 1.4 结果显示 (cb_stoptest)

**位置**: `module_cre.m` 第746-769行

```matlab
function cb_stoptest(obj, ~, ~, metValue)
    % 计算性能指标
    if obj.data{2}.M == 1  % 单目标
        metValue = obj.data{2}.CalMetric('Min_value', ...
                                         obj.data{1}.result{end});
    else                    % 多目标
        metValue = obj.data{2}.CalMetric('HV', ...
                                         obj.data{1}.result{end});
    end
    
    % 绘制结果
    Draw(obj.app.axesE);
    if obj.data{2}.M == 1
        obj.data{2}.DrawDec(obj.data{1}.result{end});  % 决策空间
    else
        obj.data{2}.DrawObj(obj.data{1}.result{end});  % 目标空间
    end
    
    % 显示性能指标
    if obj.data{2}.M == 1
        obj.app.labelE.Text = sprintf('Min value: %.2e', metValue);
    else
        obj.app.labelE.Text = sprintf('HV: %.2e', metValue);
    end
end
```

**性能指标**:
- 单目标: `Min_value` (最小目标值)
- 多目标: `HV` (Hypervolume超体积)

---

## 二、Test模块的完整测试

### 2.1 测试入口

**位置**: `GUI/module_test.m` 第103-161行

**GUI界面**: Test标签页

### 2.2 完整测试流程

#### 步骤1: 算法和问题选择
```matlab
% 从算法列表获取参数
[name, para] = GUI.GetParameterSetting(obj.app.listB.items(1));

% 创建算法实例
ALG = feval(name, 'parameter', para, ...
                  'outputFcn', @obj.outputFcn, ...
                  'save', 20);  // 每20代保存一次

% 从问题列表获取参数
[name, para] = GUI.GetParameterSetting(obj.app.listB.items(2));

% 创建问题实例
PRO = feval(name, 'N', para{1}, ...
                  'M', para{2}, ...
                  'D', para{3}, ...
                  obj.app.listB.items(2).label(4).Text, para{4}, ...
                  'parameter', para(5:end));
```

**特点**:
- 支持任意算法（不限于NeuroEA）
- 支持任意测试问题
- 保存间隔更大（20代），减少存储开销

#### 步骤2: 数据存储
```matlab
% 构建配置信息字符串
str = sprintf('<Algorithm: %s>\n', class(ALG));
for i = 1 : length(obj.app.listB.items(1).label)
    str = [str, sprintf('%s: %s\n', ...
           obj.app.listB.items(1).label(i).Text, ...
           obj.app.listB.items(1).edit(i).Value)];
end
str = [str, sprintf('\n<Problem: %s>\n', class(PRO))];
for i = 1 : length(obj.app.listB.items(2).label)
    str = [str, sprintf('%s: %s\n', ...
           obj.app.listB.items(2).label(i).Text, ...
           obj.app.listB.items(2).edit(i).Value)];
end

% 存储到数据数组（支持多次运行对比）
obj.data = [obj.data; {ALG}, {PRO}, {str}];
```

#### 步骤3: 执行算法
```matlab
ALG.Solve(PRO);
```

### 2.3 输出函数 (outputFcn)

**位置**: `module_test.m` 第177-186行

```matlab
function outputFcn(obj, Algorithm, Problem)
    % 更新滑块位置（进度）
    obj.app.slider.Value = Problem.FE / max(Problem.FE, Problem.maxFE);
    
    % 触发结果显示更新
    obj.cb_slider();
    
    % 检查Stop按钮
    assert(strcmp(obj.app.buttonC(2).Enable,'on'), ...
           'PlatEMO:Termination', '');
    
    % 处理暂停
    if strcmp(obj.app.buttonC(1).Text, 'Continue')
        waitfor(obj.app.buttonC(1), 'Text');
    end
    
    % 再次检查Stop
    assert(strcmp(obj.app.buttonC(2).Enable,'on'), ...
           'PlatEMO:Termination', '');
end
```

**功能增强**:
- 实时更新进度滑块
- 自动刷新可视化图表
- 支持暂停/继续/停止

### 2.4 动态结果显示 (cb_slider)

**位置**: `module_test.m` 第188-250行

```matlab
function cb_slider(obj, ~, ~, ax)
    % 获取当前算法和问题
    ALG = obj.data{obj.app.dropD(1).Value, 1};
    PRO = obj.data{obj.app.dropD(1).Value, 2};
    
    % 计算当前进度
    rate = PRO.FE / max(PRO.FE, PRO.maxFE);
    obj.app.slider.Value = min(obj.app.slider.Value, rate);
    
    % 根据滑块位置确定要显示的代数
    index = max(1, round(obj.app.slider.Value/rate * size(ALG.result,1)));
    obj.app.labelC.Text = sprintf('%d evaluations', ALG.result{index,1});
    
    % 多目标优化的可视化选项
    if PRO.M > 1
        switch obj.app.dropC(1).Value
            case 'Population (objectives)'
                PRO.DrawObj(ALG.result{index,2});  % 目标空间
            case 'Population (variables)'
                PRO.DrawDec(ALG.result{index,2});  % 决策空间
            case 'True Pareto front'
                Draw(PRO.optimum, ...
                     {'\it f\rm_1','\it f\rm_2','\it f\rm_3'});
            otherwise  % 性能指标曲线
                obj.app.waittip.Visible = 'on'; drawnow();
                Draw([cell2mat(ALG.result(:,1)), ...
                      ALG.CalMetric(obj.app.dropC(1).Value)], ...
                     '-k.', 'LineWidth', 1.5, 'MarkerSize', 10, ...
                     {'Number of function evaluations', ...
                      strrep(obj.app.dropC(1).Value,'_',' '), []});
                obj.app.waittip.Visible = 'off';
        end
    else  % 单目标优化
        switch obj.app.dropC(2).Value
            case 'Population (variables)'
                PRO.DrawDec(ALG.result{index,2});
            otherwise  % 性能指标曲线
                Draw([cell2mat(ALG.result(:,1)), ...
                      ALG.CalMetric(obj.app.dropC(2).Value)], ...
                     '-k.', 'LineWidth', 1.5, 'MarkerSize', 10, ...
                     {'Number of function evaluations', ...
                      strrep(obj.app.dropC(2).Value,'_',' '), []});
        end
    end
end
```

**可视化选项**:

多目标优化:
- Population (objectives): 目标空间分布
- Population (variables): 决策空间分布
- True Pareto front: 真实Pareto前沿
- 各种性能指标: HV, IGD, GD, Spacing等

单目标优化:
- Population (variables): 决策空间分布
- 各种性能指标: Min_value, Mean_value等

### 2.5 结果保存功能

**位置**: `module_test.m` 第169-175行

```matlab
function cb_save(obj, ~, ~, type)
    ALG = obj.data{obj.app.dropD(1).Value, 1};
    PRO = obj.data{obj.app.dropD(1).Value, 2};
    
    % 获取当前滑块对应的代数
    rate = PRO.FE / max(PRO.FE, PRO.maxFE);
    index = max(1, round(obj.app.slider.Value/rate * size(ALG.result,1)));
    
    % 保存种群
    GUI.SavePopulation(obj.GUI.app.figure, ...
                       ALG.result{index,2}, type);
end
```

**保存选项**:
- Save best solutions: 仅保存非支配解
- Save all solutions: 保存完整种群

### 2.6 高级功能

#### GIF动画生成 (cb_toolbutton1)

**位置**: `module_test.m` 第252-275行

```matlab
function cb_toolbutton1(obj, ~, ~)
    [file, folder] = uiputfile({'*.gif','GIF image'}, '');
    if file ~= 0
        filename = fullfile(folder, file);
        figure('NumberTitle','off','Name','Figure for creating the gif');
        
        % 生成20帧动画
        for i = linspace(0, 1, 20)
            obj.app.slider.Value = i;
            obj.cb_slider([], [], gca);
            drawnow('limitrate');
            
            % 捕获当前图像
            [I, map] = rgb2ind(print('-RGBImage'), 20);
            
            if i == 0
                imwrite(I, map, filename, 'gif', ...
                        'Loopcount', inf, 'DelayTime', 0.2);
            else
                imwrite(I, map, filename, 'gif', ...
                        'WriteMode', 'append', 'DelayTime', 0.2);
            end
        end
        delete(gcf);
    end
end
```

**功能**: 将进化过程保存为GIF动画

#### 导出到新窗口 (cb_toolbutton2)

**位置**: `module_test.m` 第277-294行

```matlab
function cb_toolbutton2(obj, ~, ~)
    if isempty(get(gcf, 'CurrentAxes'))
        % 创建新坐标轴
        axes('FontName', obj.app.axes.FontName, ...
             'FontSize', obj.app.axes.FontSize, ...
             'NextPlot', obj.app.axes.NextPlot, ...
             'Box', obj.app.axes.Box, ...
             'View', obj.app.axes.View);
        copyobj(obj.app.axes.Children, gca);
    else
        % 叠加到现有坐标轴（用于对比）
        h = copyobj(obj.app.axes.Children, gca);
        for i = 1 : length(h)
            if strcmp(h(i).Type, 'line')
                set(h(i), 'Color', rand(1,3), ...
                          'Markerfacecolor', rand(1,3));
            end
        end
    end
    axis tight;
    
    % 导出数据到工作空间
    Data = arrayfun(@(s){s.XData, s.YData, s.ZData}, ...
                    get(gca,'Children'), 'UniformOutput', false);
    assignin('base', 'Data', cat(1, Data{:}));
end
```

**功能**:
- 在新MATLAB图窗中打开结果
- 支持多个结果叠加对比
- 自动导出数据到工作空间变量`Data`

---

## 三、测试代码对比

| 特性 | Algorithm Creation测试 | Test模块测试 |
|------|----------------------|-------------|
| 用途 | 快速验证训练效果 | 完整性能评估 |
| 保存间隔 | 每1代 | 每20代 |
| 可视化 | 基础（最终结果） | 高级（动态+多种视图） |
| 进度控制 | 暂停/继续/停止 | 暂停/继续/停止+滑块回放 |
| 结果保存 | 无 | 支持导出种群 |
| 多次运行 | 不支持 | 支持多次运行对比 |
| GIF生成 | 不支持 | 支持 |
| 数据导出 | 不支持 | 支持导出到工作空间 |

---

## 四、使用NeuroEA进行测试的完整示例

### 4.1 GUI方式（推荐）

**Algorithm Creation模块快速测试**:
```
1. 点击"Load algorithm"加载 myAlgorithm.mat
2. 在Problem selection中选择测试问题（如DTLZ2）
3. 设置问题参数（N=100, M=3, D=10）
4. 点击Testing面板的"Start"按钮
5. 查看结果图和性能指标
```

**Test模块完整测试**:
```
1. 切换到Test标签页
2. 在Algorithm selection中选择训练好的NeuroEA算法
3. 在Problem selection中选择测试问题
4. 调整参数设置
5. 点击"Start"开始测试
6. 使用滑块回放进化过程
7. 切换不同可视化视图
8. 保存结果或生成GIF动画
```

### 4.2 编程方式

```matlab
% 加载训练好的参数
load('Algorithms/NeuroEA/myAlgorithm.mat', 'Blocks', 'Graph');

% 创建算法实例
ALG = NeuroEA('parameter', {Blocks, Graph}, 'save', 20);

% 创建测试问题
PRO = DTLZ2('N', 100, 'M', 3, 'D', 10, 'maxFE', 30000);

% 运行算法
ALG.Solve(PRO);

% 计算性能指标
HV = PRO.CalMetric('HV', ALG.result{end});
IGD = PRO.CalMetric('IGD', ALG.result{end});

fprintf('HV: %.4e\n', HV);
fprintf('IGD: %.4e\n', IGD);

% 可视化结果
figure;
PRO.DrawObj(ALG.result{end});
title('Final Population in Objective Space');
```

---

## 五、关键测试指标

### 5.1 单目标优化指标

- **Min_value**: 最小目标函数值
- **Mean_value**: 种群平均目标值
- **Std_value**: 种群目标值标准差
- **runtime**: 算法运行时间

### 5.2 多目标优化指标

- **HV (Hypervolume)**: 超体积指标（越大越好）
- **IGD (Inverted Generational Distance)**: 反向世代距离（越小越好）
- **GD (Generational Distance)**: 世代距离（越小越好）
- **Spacing**: 解的分布均匀性（越小越好）
- **Coverage**: 覆盖率
- **runtime**: 算法运行时间

---

## 六、测试最佳实践

1. **训练后立即验证**: 使用Algorithm Creation的Testing功能快速检查
2. **多问题测试**: 在Test模块中测试多个不同问题
3. **多次运行**: 每个问题运行多次（建议30次）评估稳定性
4. **对比分析**: 使用Test模块的多结果对比功能
5. **保存证据**: 生成GIF动画和导出数据用于论文/报告
6. **参数敏感性**: 测试不同问题规模（N, M, D）下的性能

测试代码通过GUI和编程两种方式，提供了从快速验证到深度分析的完整测试流程。
