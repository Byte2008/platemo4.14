% 示例说明 Block_Exchange.m 中第 40-42 行的代码逻辑

% 假设参数设置
nParents = 2;  % 每2个父代产生1个子代

% 假设 ParentDec 是一个 4x3 的矩阵（4个父代，每个父代3维）
ParentDec = [
    1, 2, 3;
    4, 5, 6;
    7, 8, 9;
    10, 11, 12
];

% 第 38 行：生成 selected 矩阵
% 这里为了演示，我们手动设置 selected 矩阵，而不是通过随机数生成
% 假设生成了 2x3 的 selected 矩阵（2个子代，每个子代3维）
selected = [
    1, 2, 1;
    2, 1, 2
];

fprintf('初始 selected 矩阵:\n');
disp(selected);
fprintf('\n');

% 第 40 行：调整行索引
row_adjustment = repmat((0:size(selected,1)-1)'*nParents, 1, size(ParentDec,2));
fprintf('行调整矩阵:\n');
disp(row_adjustment);
fprintf('\n');

selected = selected + row_adjustment;
fprintf('行调整后的 selected 矩阵:\n');
disp(selected);
fprintf('\n');

% 第 41 行：调整列索引
col_adjustment = repmat((0:size(selected,2)-1)*size(ParentDec,1), size(selected,1), 1);
fprintf('列调整矩阵:\n');
disp(col_adjustment);
fprintf('\n');

selected = selected + col_adjustment;
fprintf('最终 selected 矩阵（线性索引）:\n');
disp(selected);
fprintf('\n');

% 第 42 行：根据索引获取值
obj_output = ParentDec(selected);
fprintf('最终输出 obj.output:\n');
disp(obj_output);
fprintf('\n');

% 解释线性索引的计算过程
fprintf('=== 线性索引计算解释 ===\n');
fprintf('ParentDec 矩阵的大小: %dx%d\n', size(ParentDec,1), size(ParentDec,2));
fprintf('对于 (i,j) 位置的元素，线性索引为: i + (j-1)*size(ParentDec,1)\n');
fprintf('\n');

% 验证每个元素的来源
for i = 1:size(selected,1)
    for j = 1:size(selected,2)
        linear_idx = selected(i,j);
        [row, col] = ind2sub(size(ParentDec), linear_idx);
        fprintf('子代 %d 的第 %d 维来自父代 %d 的第 %d 维，值为 %.2f\n', ...
            i, j, row, col, ParentDec(row, col));
    end
end
