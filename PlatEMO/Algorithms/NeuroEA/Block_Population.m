classdef Block_Population < BLOCK
% A population

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    methods
        %% Main procedure of the block，实现了父类定义的Main方法，用于从Precursors中收集个体并赋值给output属性
        function Main(obj,Problem,Precursors,Ratio)
            obj.output = obj.Gather(Problem,Precursors,Ratio,1,1);
        end
        %% Initialize the solutions
        function Initialization(obj,Population)
            %deal(Population) ：这是 MATLAB 的一个函数，当它只有一个输入但有多个输出时，它会将 同一个输入值 赋值给所有的输出。
            % [obj.output] ：这是一个逗号分隔列表（Comma-Separated List），代表对象数组中每个对象的 output 属性。
            [obj.output] = deal(Population);
        end
    end
end