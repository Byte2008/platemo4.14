# 如何在Experiment Module中使用训练好的NeuroEA算法

## 方法概述

将训练好的NeuroEA算法保存为独立算法类，使其能在PlatEMO的Experiment Module中像NSGA-II等标准算法一样被选择和使用。

---

## 完整操作步骤

### 步骤1：在Algorithm Creation模块中训练算法

1. 打开PlatEMO GUI
2. 切换到"Algorithm Creation"标签页
3. 搭建你的NeuroEA算法结构（拖拽Block并连接）
4. 在Training面板中配置训练参数
5. 点击"Start"开始训练
6. 等待训练完成

### 步骤2：生成算法代码

**在Algorithm Creation模块中**：

1. 点击工具栏的"Generate code"按钮（代码图标）
2. 在弹出的保存对话框中输入算法名称，例如：`NeuroEA_trained`
3. 选择保存位置（建议保存在 `Algorithms/NeuroEA/` 文件夹）
4. 点击"保存"

**系统会自动生成两个文件**：
- `NeuroEA_trained.m` - 算法类文件
- `NeuroEA_trained.mat` - 训练好的参数文件

### 步骤3：验证文件结构

确保生成的文件符合以下结构：

```
Algorithms/NeuroEA/
├── NeuroEA_trained.m      ← 算法类文件
├── NeuroEA_trained.mat    ← 训练参数文件
├── NeuroEA.m
├── BLOCK.m
├── Block_*.m
└── ...
```

### 步骤4：重启PlatEMO GUI

**重要**：必须重启GUI才能识别新算法

```matlab
% 在MATLAB命令窗口
close all
clear classes
platemo
```

### 步骤5：在Experiment Module中使用

1. 打开PlatEMO GUI
2. 切换到"Experiment"标签页
3. 在"Algorithm selection"列表中查找你的算法
   - 如果按年份筛选，选择"2026"或"All year"
   - 在列表中找到"NeuroEA_trained"
4. 选择测试问题（Problem selection）
5. 配置实验参数
6. 点击"Start"运行实验

---

## 算法文件格式说明

### 必需的元数据注释

```matlab
classdef NeuroEA_trained < ALGORITHM
% <年份> <优化类型> <变量类型> <约束类型>
% 算法描述

%------------------------------- Reference --------------------------------
% 参考文献
%------------------------------- Copyright --------------------------------
% 版权信息
%--------------------------------------------------------------------------
```

**元数据格式**：
- `<2026>` - 发布年份
- `<multi/single>` - 多目标/单目标
- `<real/integer/label/binary/permutation>` - 支持的变量类型
- `<constrained/none>` - 是否支持约束

### 完整的算法类结构

```matlab
classdef NeuroEA_trained < ALGORITHM
% <2026> <multi/single> <real> <none>
% Trained NeuroEA

    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            % 定义Block结构
            Blocks = [...];
            Graph = [...];
            
            % 加载训练好的参数
            matFile = fullfile(fileparts(mfilename('fullpath')),'NeuroEA_trained.mat');
            if exist(matFile,'file')
                load(matFile,'Blocks','Graph');
            end
            [Blocks,Graph] = Algorithm.ParameterSet(Blocks,Graph);
            
            %% Generate random population
            isPop = arrayfun(@(s)isa(s,'Block_Population'),Blocks(:)');
            Blocks(isPop).Initialization(Problem.Initialization());

            %% Optimization
            while Algorithm.NotTerminated(Blocks(1).output)
                % 算法主循环
                ...
            end
        end
    end
end
```

---

## 常见问题排查

### 问题1：算法列表中找不到新算法

**原因**：GUI缓存未更新

**解决方案**：
```matlab
close all
clear classes
platemo
```

### 问题2：运行时提示"找不到NeuroEA_trained.mat"

**原因**：.mat文件路径不正确

**解决方案**：
1. 确保.mat文件与.m文件在同一目录
2. 检查代码中的文件路径：
```matlab
matFile = fullfile(fileparts(mfilename('fullpath')),'NeuroEA_trained.mat');
```

### 问题3：算法运行出错

**原因**：参数未正确加载或Block定义错误

**解决方案**：
1. 在Algorithm Creation模块中点击"Validation"验证算法
2. 检查.mat文件是否包含正确的Blocks和Graph变量：
```matlab
load('Algorithms/NeuroEA/NeuroEA_trained.mat');
whos Blocks Graph
```

### 问题4：算法在列表中显示但无法选择

**原因**：元数据注释格式错误

**解决方案**：
确保第2行注释格式正确：
```matlab
% <2026> <multi/single> <real> <none>
```

---

## 高级用法

### 创建多个训练版本

可以为不同问题类型训练不同版本：

```
Algorithms/NeuroEA/
├── NeuroEA_trained_MOP.m       ← 多目标优化版本
├── NeuroEA_trained_MOP.mat
├── NeuroEA_trained_SOP.m       ← 单目标优化版本
├── NeuroEA_trained_SOP.mat
├── NeuroEA_trained_Constrained.m  ← 约束优化版本
└── NeuroEA_trained_Constrained.mat
```

修改元数据以区分：
```matlab
% NeuroEA_trained_MOP.m
% <2026> <multi> <real> <none>
% Trained NeuroEA for Multi-objective Optimization

% NeuroEA_trained_SOP.m
% <2026> <single> <real> <none>
% Trained NeuroEA for Single-objective Optimization
```

### 添加自定义参数

可以在算法类中添加可调参数：

```matlab
classdef NeuroEA_trained < ALGORITHM
% <2026> <multi> <real> <none>
% Trained NeuroEA
% operator --- GA --- Genetic operator

    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            operator = Algorithm.ParameterSet('GA');
            
            % 根据参数选择不同的训练版本
            if strcmp(operator,'GA')
                matFile = 'NeuroEA_trained_GA.mat';
            else
                matFile = 'NeuroEA_trained_DE.mat';
            end
            
            % 加载对应的参数
            load(fullfile(fileparts(mfilename('fullpath')),matFile),'Blocks','Graph');
            ...
        end
    end
end
```

---

## 验证算法是否正确安装

### 方法1：通过GUI验证

1. 打开PlatEMO
2. 切换到Experiment标签
3. 在Algorithm selection中搜索你的算法名称
4. 如果能找到并选择，说明安装成功

### 方法2：通过命令行验证

```matlab
% 检查算法是否在路径中
which NeuroEA_trained

% 应该输出类似：
% E:\PlatEMO\...\Algorithms\NeuroEA\NeuroEA_trained.m

% 测试算法是否可以实例化
try
    alg = NeuroEA_trained();
    disp('算法创建成功！');
catch ME
    disp(['错误: ', ME.message]);
end
```

### 方法3：运行简单测试

```matlab
% 创建算法和问题
ALG = NeuroEA_trained();
PRO = DTLZ2('N',100,'M',3,'D',10);

% 运行算法
ALG.Solve(PRO);

% 查看结果
HV = PRO.CalMetric('HV',ALG.result{end});
fprintf('HV: %.4e\n', HV);
```

---

## 最佳实践

1. **命名规范**：使用描述性名称，如 `NeuroEA_DTLZ_trained`、`NeuroEA_v2`
2. **版本管理**：为不同训练结果保留多个版本
3. **文档记录**：在注释中记录训练配置和性能
4. **参数备份**：定期备份.mat文件
5. **性能测试**：在Experiment Module中与标准算法对比

---

## 完整示例

假设你训练了一个针对DTLZ问题优化的NeuroEA：

### 1. 生成代码
```
文件名: NeuroEA_DTLZ
保存位置: Algorithms/NeuroEA/
```

### 2. 修改元数据
```matlab
classdef NeuroEA_DTLZ < ALGORITHM
% <2026> <multi> <real> <none>
% NeuroEA trained on DTLZ benchmark problems
```

### 3. 重启GUI
```matlab
close all; clear classes; platemo
```

### 4. 在Experiment中使用
- Algorithm: NeuroEA_DTLZ
- Problem: DTLZ1-DTLZ7
- Runs: 30
- 点击Start运行实验

### 5. 查看结果
在Result display中查看性能指标和Pareto前沿

---

## 总结

通过"Generate code"功能，你可以：
✅ 将训练好的NeuroEA保存为独立算法
✅ 在Experiment Module中像使用标准算法一样使用它
✅ 进行大规模性能对比实验
✅ 与其他算法进行公平比较
✅ 生成可发表的实验结果

训练好的算法会自动加载优化后的参数，无需手动配置！
