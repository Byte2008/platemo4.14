function L=GQI(a,b,c,fa,fb,fc,low,up)
%%%%%%%%%%%%%%% 实现了广义二次插值（Generalized Quadratic Interpolation, GQI）
 %%%%%%%%%%%%%%%%%给定三个点及其函数值，根据它们的位置关系选择不同的插值策略，以确保生成的新点更有可能接近最优解。
%确保 fi ≤ fj ≤ fk，即 xi 是当前最好的点。
fabc=[fa fb fc];
[fijk,ind]=sort(fabc);
fi=fijk(1);fj=fijk(2);fk=fijk(3);
dim=length(a);
ai=ind(1); bi=ind(2);ci=ind(3);
L = zeros(1,dim);               % 存储新位置
for i = 1:dim                   % 对每个维度独立处理
    x = [a(i) b(i) c(i)];       % 三个点在第i维的坐标
    xi = x(ai);                 % 最优点在第i维的坐标
    xj = x(bi);                 % 次优点
    xk = x(ci);                 % 最差点
    %Eq.(23)最优点 xi 在中间位置，直接使用三点二次插值
    if (xk>=xi && xi>=xj) || (xj>=xi && xi>=xk)
        L(i)=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
    %Eq.(19)三点按 xi < xj < xk 排列，策略：如果插值点 I 落在 [xi, xj] 区间（向最优点方向），接受；否则用外推点 3*xi-2*xj 替换 xk 重新插值
    elseif (xk>=xj && xj>=xi)        
        I=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
        if  I<xj
            L(i)=I;
        else
            %外推点 3*xi-2*xj：从 xj 到 xi 的方向再延伸相同距离，用于探索更远的区域
            L(i)=Interpolation(xi,xj,3*xi-2*xj,fi,fj,fk,low(i),up(i));
        end
    %Eq.(20)三点按 xi > xj > xk 排列（位置递增但函数值递减）
    elseif (xi>=xj && xj>=xk)
        I=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
        if  I>xj
            L(i)=I;
        else
            L(i)=Interpolation(xi,xj,3*xi-2*xj,fi,fj,fk,low(i),up(i));
        end
    %Eq.(21)xi 最小，xj 最大，xk 在中间，用镜像点 2*xi-xk 替换 xj，形成以 xi 为中心的对称探索
    elseif (xj>=xk && xk>=xi)
        L(i)=Interpolation(xi,2*xi-xk,xk,fi,fj,fk,low(i),up(i));
    %Eq.(22)
    elseif (xi>=xk && xk>=xj)
        L(i)=Interpolation(xi,2*xi-xk,xk,fi,fj,fk,low(i),up(i));
    end
end


