classdef BLOCK < handle & matlab.mixin.Heterogeneous
%BLOCK - The superclass of blocks.
%< handle - 表示该类继承自 handle 基类，继承handle类的对象是引用类型，而不是值类型，引用类型对象在赋值时不会创建副本，而是传递引用。
%<matlab.mixin.Heterogeneous ，该类实现了 matlab.mixin.Heterogeneous 混合类，允许不同子类的对象存储在同一个数组中

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties(SetAccess = protected)
        parameter;      % Parameters in the block
        lower;          % Lower bound of each parameter
        upper;          % Upper bound of each parameter
        output;         % Current output of the block
        nextOut = 1;	% Index of next output solution
    end
    properties
        trainTime = 0;	% Number of training times
    end
    methods
        function Main(obj,Problem,Precursors,Ratio)
        %Main - Main procedure of the block.
        %
        %   obj.Main(Pro,Pre,Ratio) performs the main procedure of block
        %   obj. Pro is a PROBLEM object, Pre are multiple BLOCK objects,
        %   and Ratio are the ratios of solutions gathered from the outputs
        %   of blocks Pre. The output of the main procedure is stored in
        %   obj.output.
        %
        %   Example:
        %       Blocks(i).Main(Problem,Blocks(logical(Graph(:,i))),Graph(:,i));
        end
        function ParameterAssign(obj)
        %ParameterAssign - Assign parameters to block-specific variables.
        %
        %   This function is automatically called when the value of
        %   obj.parameter is changed.
        end
    end
	methods(Sealed = true)     
        function ParameterSet(obj,value)
        %ParameterSet - Set the parameters of multiple blocks.
        %
        %   obj.ParameterSet(Par) sets obj.parameter to Par. Here obj can
        %   be multiple BLOCK objects, where Par is a vector concatenating
        %   the parameters of all the objects.
        %
        %   obj.ParameterAssign() is automatically called after this
        %   function.
        %
        %   Example:
        %       Blocks(1:5).ParameterSet(Par);
        
            k = 1;
            for i = 1 : length(obj)
                %参数值提取 ： value(k:k-1+length(obj(i).parameter))，从输入的参数向量 value 中提取当前 BLOCK 对象 obj(i) 对应的参数值
                %范围限制 ： max(obj(i).lower, ...) 和 min(obj(i).upper, ...)实现了参数值的 裁剪 操作，确保所有参数都在有效范围内
                obj(i).parameter = min(obj(i).upper,max(obj(i).lower,value(k:k-1+length(obj(i).parameter))));

                obj(i).ParameterAssign();
                obj(i).trainTime = obj(i).trainTime + 1;
                k = k + length(obj(i).parameter);
            end
        end
        function value = parameters(obj)
        %parameters - Get the parameters of multiple blocks.
        %
        %   Par = obj.parameters returns a vector concatenating the
        %   parameters of multiple blocks obj.
            %MATLAB 的 cat 函数用于连接数组。 2 表示沿第二维度（水平方向）连接。
            % cat(2,a.lower),ans =  1     1     1
            value = cat(2,obj.parameter);
        end
        function value = lowers(obj)
        %lowers - Get the lower bounds of the parameters of multiple blocks.
        %
        %   Lower = obj.lowers returns a vector concatenating the lower
        %   bounds of the parameters of multiple blocks obj.
        
            value = cat(2,obj.lower);
        end
        function value = uppers(obj)
        %uppers - Get the upper bounds of the parameters of multiple blocks.
        %
        %   Upper = obj.uppers returns a vector concatenating the upper
        %   bounds of the parameters of multiple blocks obj.
        
            value = cat(2,obj.upper);
        end
        function Output = Gather(obj,Problem,Predecessors,Ratio,inType,multiple)
        %Gather - Gather the output from multiple precursors
        %
        %   Output = obj.Gather(Pro,Pre,Ratio,inType,mul) gathers outputs
        %   from multiple blocks for block obj. Pro is a PROBLEM object,
        %   Pre are multiple BLOCK objects, Ratio are the ratios of
        %   solutions gathered from the outputs of blocks Pre, inType is
        %   the type of gathered solutions (1. SOLUTION objects, 2. decision
        %   matrix), and mul indicates that the number of gathered
        %   solutions should be a multiple of mul.
        %
        %   This function is usually called at the beginning of obj.Main.
        %
        %   Example:
        %       Population = obj.Gather(Problem,Predecessors,Ratio,1,1);
        %       ParentDec = obj.Gather(Problem,Predecessors,Ratio,2,2);
        
            Ratio  = Ratio(Ratio>0);
            Output = [];
            Lens   = [];
            for i = 1 : length(Predecessors)
                if inType == 1
                    % Get SOLUTION objects from the outputs of predecessors
                    if ~isa(Predecessors(i).output,'SOLUTION')
                        Predecessors(i).output = Problem.Evaluation(Predecessors(i).output);
                    end
                    Out    = Predecessors(i).output;
                     %这行代码生成了一个索引向量Index，用于从前驱块的输出中循环地截取指定数量个体的索引。
                     %使用mod()函数对索引范围取模，确保索引在0到length(Out)-1之间， 最后加1，将索引转换为 MATLAB 的 1-based 索引系统
                    Index  = mod(Predecessors(i).nextOut-1:Predecessors(i).nextOut+floor(length(Out)*Ratio(i))-2,length(Out)) + 1;
                    Output = [Output,Out(Index)];
                    Lens   = [Lens,length(Index)];
                    Predecessors(i).nextOut = mod(Index(end),length(Out)) + 1;
                else
                    % Get decision matrix from the outputs of predecessors
                    if ~isa(Predecessors(i).output,'SOLUTION')
                        Out = Predecessors(i).output;
                    else
                        Out = Predecessors(i).output.decs;
                    end
                    Index  = mod(Predecessors(i).nextOut-1:Predecessors(i).nextOut+floor(size(Out,1)*Ratio(i))-2,size(Out,1)) + 1;
                    Output = [Output;Out(Index,:)];
                    Lens   = [Lens,length(Index)];
                    Predecessors(i).nextOut = mod(Index(end),size(Out,1)) + 1;
                end
            end
            % Interleave the outputs from multiple precursors
            %构建基准索引矩阵 ( repmat(1:max(Lens), ...) )：- 创建一个矩阵，行数为前驱块数量，列数为最大数据长度。
            %每一行都是 1, 2, 3, ..., max(Lens) 。这代表“第几个元素”。
            %构建偏移索引矩阵 ( repmat([0,cumsum(Lens(1:end-1))]',1,max(Lens)) )：- 创建一个矩阵，行数为前驱块数量，列数为最大数据长度。
            %每一行都是 0, Lens(1), Lens(1)+Lens(2), ..., Lens(1)+...+Lens(end-1) 。这代表“从第几个元素开始”。
            %相加得到最终索引矩阵 Index：- 每个元素都是“第几个元素”加上“从第几个元素开始”，即从每个前驱块的输出中截取的具体位置。
            %确保索引不超过总长度：- 使用 min(Index,sum(Lens)) 确保索引不超过每个前驱块输出的总长度。
            %移除重复索引：- 使用 unique(Index(:),'stable') 移除重复索引，保持原始顺序。

            Index = repmat(1:max(Lens),length(Lens),1) + repmat([0,cumsum(Lens(1:end-1))]',1,max(Lens));
            Index = min(Index,sum(Lens));
            Index = unique(Index(:),'stable');

            %截断输出个体的数量 ，以确保最终输出的个体总数是 multiple 的整数倍。
            if inType == 1
                Output = Output(Index(1:floor(end/multiple)*multiple));
            else
                Output = Output(Index(1:floor(end/multiple)*multiple),:);
            end
            % Reset the next output solution of the current block
            obj.nextOut = 1;
        end
        function Validity(obj,Graph)
        %Validity - Check the validity of an algorithm with mulitple blocks
        %
        %   obj.Validity(G) throws an error if the algorithm is invalid.
        %   obj is an array of BLOCK objects constituting the algorithm and
        %   G is the adjacency matrix. After the error err is caught, use
        %   err.identifier to determine the error type and use
        %   str2num(err.cause{1}.message) to obtain the indexes of invalid
        %   objects. Besides, nothing happens if the algorithm is valid.
        %
        %   Example:
        %       try
        %           Blocks.Validity(Graph);
        %       catch err
        %           switch err.identifier
        %               case 'BLOCK:NoInput'
        %                   str2num(err.cause{1}.message)
        %               case 'BLOCK:NoOutput'
        %                   str2num(err.cause{1}.message)
        %               case ...
        %                   ...
        %           end
        %       end

            try
                type = strrep(arrayfun(@class,obj,'UniformOutput',false),'Block_','');
                G    = digraph(Graph);
                invalidStr = '';
                assert(strcmp('Population',type{1}),'BLOCK:NoPopulation','the first block is not a population.',invalidStr);
                assert(any(ismember({'Crossover','Exchange','Mutation'},type)),'BLOCK:NoOperator','the algorithm does not contain variation operator.',invalidStr);
                invalidStr = num2str(find(indegree(G)==0)');
                assert(isempty(invalidStr),'BLOCK:NoInput','the block #%s have no predecessor.',invalidStr);
                invalidStr = num2str(find(outdegree(G)==0)');
                assert(isempty(invalidStr),'BLOCK:NoOutput','the block #%s have no successor.',invalidStr);
                invalidStr = num2str(find(conncomp(G,'Type','weak')>1));
                assert(isempty(invalidStr),'BLOCK:Isolation','the block #%s are isolated.',invalidStr);
                invalidStr = num2str(find(diag(Graph))');
                assert(isempty(invalidStr),'BLOCK:SelfLoop','the block #%s have self-loop.',invalidStr);
                if ismethod(G,'allcycles')
                    cycles     = allcycles(G);
                    invalidStr = num2str(cell2mat(cycles(find(cellfun(@(a)~ismember('Population',type(a)),cycles),1))));
                    assert(isempty(invalidStr),'BLOCK:InfLoop','the cycle #%s have no population.',invalidStr);
                end
            catch err
                err = addCause(err,MException('',invalidStr));
                rethrow(err);
            end
        end
    end
end