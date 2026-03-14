function L_xmin=Interpolation(xi,xj,xk,fi,fj,fk,l,u)
% Quadratic interpolation to find minimum
% Given three points (xi,fi), (xj,fj), (xk,fk)
% Fit a quadratic curve and find its extremum point

  % Eq.(5) - Calculate quadratic interpolation
  a = (xj^2-xk^2)*fi + (xk^2-xi^2)*fj + (xi^2-xj^2)*fk;
  b = 2*((xj-xk)*fi + (xk-xi)*fj + (xi-xj)*fk);
  L_xmin = a/(b+eps); 
  
  % Boundary check and random fallback
  if isnan(L_xmin) || isinf(L_xmin) || L_xmin>u || L_xmin<l
    L_xmin = (rand*(u-l)+l);
  end
