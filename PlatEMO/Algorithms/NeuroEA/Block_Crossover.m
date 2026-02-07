classdef Block_Crossover < BLOCK
% Unified crossover for real variables
% nParents --- 2 --- Number of parents generating one offspring
% nSets    --- 5 --- Number of parameter sets

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = private)
        nParents;	% <hyperparameter> Number of parents for generating an offspring
        nSets;      % <hyperparameter> Number of weight sets
        Weight;     % <parameter> Weight sets
        Fit;        % <parameter> Probability of using each weight set
    end
    methods
        %% Default settings of the block
        function obj = Block_Crossover(nParents,nSets)
            obj.nParents = nParents;	% Hyperparameter ，如2,表示父类个数.
            obj.nSets    = nSets;     	% Hyperparameter，如5，表示参数集的个数.
            %第 1 个参数 ：正态分布的 标准差 (σ)，标准差下限 0 ：标准差必须 ≥ 0，这是数学约束，上限 1 ：限制标准差不会过大，避免采样过度分散；
            %第 2 个参数 ：正态分布的 均值 (μ)， 下限 -1 ：允许负偏移，上限 1 ：限制偏移范围在 [-1, 1] 之间， 这样设置使均值在 0 附近对称分布
            %权重 (第 3 个参数)：下限 1e-20 ：非常小的正数，避免除以零， 上限 1 ：权重归一化到 [0, 1] 范围。
            obj.lower    = repmat([0 -1 1e-20],1,(nParents-1)*nSets);	% 标准差、均值、采样概率下限。
            obj.upper    = ones(1,3*(nParents-1)*nSets);              	% 标准差、均值、采样概率上限。
            % Randomly set the parameters
            obj.parameter = unifrnd(obj.lower,obj.upper);                %产生3*(nParents-1)*nSets个均匀随机数（维数与lower、upper保持一致)。
            obj.ParameterAssign();
        end
        %% Assign parameters to variables
        function ParameterAssign(obj)
            obj.Weight = reshape(obj.parameter,[],obj.nSets)';    %reshape(obj.parameter,[],obj.nSets),分成nSets列，每连续多个元素组成一列。
            %                                   父代2                                           父代3(假设 nParents=3 ， nSets=5)
            %         σ1                     μ1                  w1                  σ2                   μ2                w2
            %参数集1 0.311215042044805	0.0570662710124255	0.165648729499781	0.601981941401637	-0.474057430919711	0.654079098476782
            %参数集2 0.689214503140008	0.496303185647419	0.450541598502498	0.0838213779969326	-0.542046062566362	0.913337361501670
            %参数集3 0.152378018969223	0.651633954979095	0.538342435260057	0.996134716626886	-0.843648942493633	0.442678269775446
            %参数集4 0.106652770180584	0.923796161710107	0.00463422413406744	0.774910464711502	0.634606441306866	0.868694705363510
            %参数集5 0.0844358455109103	-0.200434701802207	0.259870402850654	0.800068480224308	-0.137172345072911	0.910647594429523
            obj.Fit    = cumsum(obj.Weight(:,3:3:end),1);         %3:3:end 表示从第3列开始，每隔3列取一列（步长为3），cumsum(...,1) ：计算累积和，其中1表示沿第1维（行方向）计算,对每一列计算累加和;
            %(假设 nParents=3 ， nSets=5)obj.Fit归一化处理后实例
            % 0.0579732837082828	0.262084668348588
            % 0.397765515789070	0.494124983998696
            % 0.493332539822081	0.602607613736166
            % 0.852916048032859	0.823798920943952
            % 1	                1
            obj.Fit    = obj.Fit./repmat(max(obj.Fit,[],1),size(obj.Fit,1),1);  %对 obj.Fit 进行归一化处理，计算每列的最大值，然后将整个矩阵除以这些最大值。obj.Fit 就成为了一个从0到1递增的序列，可用于轮盘赌选择。
        end
        %% Main procedure of the block
        function Main(obj,Problem,Precursors,Ratio)
            %Precursors实参为Blocks(logical(Graph(:,i)))，为当前节点的前驱节点；Ratio实参为Graph(:,i)，为Graph矩阵中当前元素前驱节点的比例。2表示收集的是决策向量，不是solution.
            ParentDec = obj.Gather(Problem,Precursors,Ratio,2,obj.nParents);
            %创建一个用于存储参数采样结果的矩阵 R,每nParents个父亲产生一个子对象；nParents个父亲第一个固定，其他通过概率抽取。
            R = zeros(size(ParentDec,1)-size(ParentDec,1)./obj.nParents,size(ParentDec,2));
            %采样所有子对象的第i对父类对象。
            for i = 1 : obj.nParents-1
                %i:obj.nParents-1:end：所有子类对象的第i个父类采样。[size(ParentDec,1)./obj.nParents,size(R,2)]表示[子类个数，维数]
                %obj.Weight(:,(i-1)*3+1:(i-1)*3+2)所有子类对象的第i个父类采样的均值和标准差。
                %obj.Fit(:,i)：所有子类对象的第i个父类采样的采样概率。
                R(i:obj.nParents-1:end,:) = ParaSampling([size(ParentDec,1)./obj.nParents,size(R,2)],obj.Weight(:,(i-1)*3+1:(i-1)*3+2),obj.Fit(:,i));
            end
            %创建一个存储后代决策变量的矩阵,
            OffDec = zeros(size(ParentDec,1)./obj.nParents,size(ParentDec,2));
            for i = 1 : size(OffDec,1)
                %用于生成第i个子类对象的obj.nParents-1个父类采样。
                r = R((i-1)*(obj.nParents-1)+1:i*(obj.nParents-1),:);
                %[1-sum(r,1);r]每一个行表示一个父类对象维的比例。ParentDec((i-1)*obj.nParents+1:i*obj.nParents表示第i个子类对象nParents个父类的决策向量，sum(...,1)按列求和。
                OffDec(i,:) = sum([1-sum(r,1);r].*ParentDec((i-1)*obj.nParents+1:i*obj.nParents,:),1);
            end
            %检查子类对象每一维的边界，并赋值给输出。
            obj.output = min(repmat(Problem.upper,size(OffDec,1),1),max(repmat(Problem.lower,size(OffDec,1),1),OffDec));
        end
    end
end

%- 第一个参数：指定采样矩阵的维度 [行数, 列数];- 第二个参数：参数集中某父类标准差、均值矩阵;- 第三个参数：参数集中参数的轮渡盘选择概率
function r = ParaSampling(xy,weight,fit)
% Parameter sampling
    %randn(xy(1),1),1,xy(2),randn产生正太分布的随机变量。randn(xy(1),1)生成一个xy(1)行，1列的随机向量。
    r    = repmat(randn(xy(1),1),1,xy(2));
    %k = find(X,n) 返回与 X 中的非零元素对应的前 n 个索引。type数组结构与xy相同，每个元素为fit中第一个大于随机数的索引。
    %%B = arrayfun(func,A) 将函数 func 应用于 A 的元素，一次一个元素。然后 arrayfun 将 func 的输出串联成输出数组 B，因此，对于 A 的第 i 个元素来说，B(i) = func(A(i))。
    %type存储的是每个每个子类对象的每一维从参数集中抽取的参数序号。
    type = arrayfun(@(S)find(rand<=fit,1),zeros(xy));
    for i = 1 : length(fit)
        %生成一个与 type 矩阵同维度的逻辑矩阵,当 type 矩阵中元素等于 i 时， index 对应位置为 true ，否则为false.获取分布为参数集中i的逻辑矩阵      
        index = type == i;      
        % 如果需要生成均值为 mu，标准差为 sigma 的正态分布随机数，使用线性变换:
        % mu = 5;      % 目标均值
        % sigma = 2;   % 目标标准差
        % r = mu + sigma * randn;        % 单个随机数
        % R = mu + sigma * randn(m, n);  % m×n 矩阵
        r(index) = r(index)*weight(i,1) + weight(i,2);
      
    end
end