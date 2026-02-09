function out = TrainNeuroEA_GA()
% TrainNeuroEA_GA - 使用遗传算法(GA)训练NeuroEA算法的参数
%
% 功能说明：
%   该函数通过遗传算法优化NeuroEA算法中各个Block的参数，以提高算法性能。
%   训练完成后，将最优参数保存到文件中供后续使用。
%
% 输出：
%   out - 结构体，包含以下字段：
%       BestParam      : 最优参数向量
%       BestScore      : 最优目标函数值
%       Trainer        : 训练器(GA算法对象)
%       TrainerProblem : 训练问题对象
%       Blocks         : 配置好最优参数的Block数组
%       Graph          : Block之间的连接图
%       SavedFile      : 参数保存的文件路径

    %% 1. 定义NeuroEA算法的结构
    % 创建Block数组：种群块、锦标赛选择块、交叉块、变异块、选择块
    Blocks = [Block_Population, Block_Tournament(200,10),Block_Crossover(2,5),Block_Mutation(5),Block_Selection(100)];
    
    % 定义Block之间的连接关系（邻接矩阵）
    % Graph(i,j)=1 表示Block i的输出连接到Block j的输入
    % 连接关系：Population -> Tournament -> Crossover -> Mutation -> Selection -> Population（形成循环）
    Graph  = [0 1 0 0 1;0 0 1 0 0;0 0 0 1 0;0 0 0 0 1;1 0 0 0 0];
    
    % 验证算法结构的有效性（检查是否有孤立块、自环、无输入/输出等问题）
    Blocks.Validity(Graph);
    
    %% 2. 创建待训练的NeuroEA算法实例
    % 'outputFcn',@(~,~)[] : 禁用输出函数以加快训练速度
    % 'save',1 : 保存算法运行结果
    ALG = NeuroEA('parameter',{Blocks,Graph},'outputFcn',@(~,~)[],'save',1);
    
    % 创建测试问题（单目标优化问题F1）
    PRO = SOP_F1();
    
    %% 3. 创建训练器（使用GA算法优化参数）
    trainer = GA('outputFcn',@(~,~)[],'save',1);
    
    % 定义训练问题
    % N=50 : 种群大小为50
    % maxFE=10000 : 最大函数评估次数为10000
    % D=length(Blocks.parameters) : 决策变量维度等于所有Block参数的总数
    % lower/upper : 参数的上下界
    % initFcn : 初始化函数
    % objFcn : 目标函数（评估参数性能）
    % once=true : 只运行一次
    trainerProblem = UserProblem('N',50,'maxFE',10000,'D',length(Blocks.parameters), ...
        'lower',Blocks.lowers,'upper',Blocks.uppers,'initFcn',@trainInit,'objFcn',@trainObj,'once',true);
    
    %% 4. 执行参数训练
    % trainer.Solve(trainerProblem) 启动完整的遗传算法优化过程：
    %
    % 工作流程：
    % 1) 初始化：生成50个随机参数配置（调用trainInit函数）
    % 2) 评估：对每个配置运行NeuroEA算法3次，计算性能（调用trainObj函数）
    % 3) 进化循环（重复直到达到10000次函数评估）：
    %    a. 锦标赛选择：从当前种群选择父代
    %    b. 遗传操作：对父代进行交叉和变异，生成子代
    %    c. 评估子代：对每个新参数配置运行NeuroEA算法3次
    %    d. 环境选择：从父代和子代中选择最优的50个进入下一代
    % 4) 保存结果：每代的种群和性能指标保存在trainer.result中
    %
    % 计算量：约30,000次NeuroEA算法运行（10000次评估 × 3次重复）
    % 目标：找到使NeuroEA在SOP_F1问题上性能最优且稳定的参数配置
    trainer.Solve(trainerProblem);
    
    %% 5. 提取最优参数
    % 从训练结果中找到目标函数值最小的个体
    [bestObj,idx] = min(trainer.result{end}.objs);
    bestDec = trainer.result{end}(idx).decs;
    
    % 将最优参数设置到Blocks中
    Blocks.ParameterSet(bestDec);
    
    %% 6. 保存训练结果到文件
    % 创建保存目录
    folder = fullfile('Algorithms','NeuroEA');
    [~,~]  = mkdir(folder);
    
    % 定义保存文件路径
    file   = fullfile(folder,'trained_params.mat');
    
    % 保存最优参数、目标值、Blocks配置和连接图
    save(file,'bestDec','bestObj','Blocks','Graph');
    
    %% 7. 返回训练结果
    out.BestParam = bestDec;           % 最优参数向量
    out.BestScore = bestObj;           % 最优目标函数值
    out.Trainer = trainer;             % 训练器对象
    out.TrainerProblem = trainerProblem; % 训练问题对象
    out.Blocks = Blocks;               % 配置好的Block数组
    out.Graph = Graph;                 % 连接图
    out.SavedFile = file;              % 保存文件路径
    
    %% 嵌套函数1：初始化训练种群
    function PopDec = trainInit(N)
        % trainInit - 生成训练用的初始种群决策变量
        %
        % 输入：
        %   N - 种群大小
        %
        % 输出：
        %   PopDec - N×D的决策变量矩阵，每行代表一个个体的参数配置
        %
        % 说明：
        %   使用均匀分布在参数上下界之间随机生成初始种群
        
        PopDec = unifrnd(repmat(Blocks.lowers,N,1),repmat(Blocks.uppers,N,1));
    end
    
    %% 嵌套函数2：评估参数性能（目标函数）
    function PopObj = trainObj(PopDec)
        % trainObj - 评估每组参数的性能
        %
        % 输入：
        %   PopDec - 种群的决策变量矩阵，每行是一组参数配置
        %
        % 输出：
        %   PopObj - 每组参数对应的目标函数值（越小越好）
        %
        % 评估策略：
        %   1. 对每组参数运行R次独立实验
        %   2. 计算R次实验的平均值和标准差
        %   3. 目标函数 = 平均值 + 标准差（同时优化性能和稳定性）
        
        R = 3;  % 每组参数重复运行3次以评估稳定性
        PopObj = zeros(size(PopDec,1),R);
        
        % 遍历种群中的每个个体（每组参数配置）
        for i = 1 : size(PopObj,1)
            % 将当前参数配置应用到Blocks
            Blocks.ParameterSet(PopDec(i,:));
            
            % 运行R次独立实验
            for j = 1 : R
                % 使用当前参数配置运行NeuroEA算法求解测试问题
                ALG.Solve(PRO);
                
                % 计算算法性能指标（最小值）
                PopObj(i,j) = PRO.CalMetric('Min_value',ALG.result{end});
            end
        end
        
        % 目标函数 = 均值 + 标准差
        % 这样既考虑了平均性能，也考虑了稳定性（标准差越小越稳定）
        PopObj = mean(PopObj,2) + std(PopObj,0,2);
    end
end
