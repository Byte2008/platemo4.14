function L=GQI(a,b,c,fa,fb,fc,low,up)
% Generalized Quadratic Interpolation (GQI)
% Given three points and their function values, select different 
% interpolation strategies based on their position relationships

fabc=[fa fb fc];
[fijk,ind]=sort(fabc);
fi=fijk(1);fj=fijk(2);fk=fijk(3);
dim=length(a);
ai=ind(1); bi=ind(2);ci=ind(3);
L = zeros(1,dim);

for i = 1:dim
    x = [a(i) b(i) c(i)];
    xi = x(ai);
    xj = x(bi);
    xk = x(ci);
    
    % Eq.(23) - xi is in the middle
    if (xk>=xi && xi>=xj) || (xj>=xi && xi>=xk)
        L(i)=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
    % Eq.(19) - xi < xj < xk
    elseif (xk>=xj && xj>=xi)        
        I=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
        if  I<xj
            L(i)=I;
        else
            L(i)=Interpolation(xi,xj,3*xi-2*xj,fi,fj,fk,low(i),up(i));
        end
    % Eq.(20) - xi > xj > xk
    elseif (xi>=xj && xj>=xk)
        I=Interpolation(xi,xj,xk,fi,fj,fk,low(i),up(i));
        if  I>xj
            L(i)=I;
        else
            L(i)=Interpolation(xi,xj,3*xi-2*xj,fi,fj,fk,low(i),up(i));
        end
    % Eq.(21) - xj >= xk >= xi
    elseif (xj>=xk && xk>=xi)
        L(i)=Interpolation(xi,2*xi-xk,xk,fi,fj,fk,low(i),up(i));
    % Eq.(22) - xi >= xk >= xj
    elseif (xi>=xk && xk>=xj)
        L(i)=Interpolation(xi,2*xi-xk,xk,fi,fj,fk,low(i),up(i));
    end
end
