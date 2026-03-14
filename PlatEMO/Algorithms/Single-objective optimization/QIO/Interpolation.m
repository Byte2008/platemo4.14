function L_xmin=Interpolation(xi,xj,xk,fi,fj,fk,l,u)
% 给定三个点 (xi, fi), (xj, fj), (xk, fk)，通过这三个点拟合一条二次曲线（抛物线），
% 然后找到这条抛物线的极值点 x_min = -B / (2A) 作为新的搜索位置。
  %Eq.(5)
  % 计算二次插值公式的分子
  a = (xj^2-xk^2)*fi + (xk^2-xi^2)*fj + (xi^2-xj^2)*fk;
  % 计算二次插值公式的分母（加2是因为求导后的系数）
  b = 2*((xj-xk)*fi + (xk-xi)*fj + (xi-xj)*fk);
  % 计算极值点位置（加eps避免除零错误）
  L_xmin = a/(b+eps); 
  % 异常处理：如果结果无效或超出边界，则随机生成一个合法值
  if isnan(L_xmin) || isinf(L_xmin) || L_xmin>u || L_xmin<l
    L_xmin = (rand*(u-l)+l);  % 在[l, u]范围内随机生成
  end
   
 
