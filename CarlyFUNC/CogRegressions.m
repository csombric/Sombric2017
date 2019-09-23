function [Pslope yfit r coef RHO_Pearson PVAL_Pearson RHO_Spearman PVAL_Spearman, Resid ] = CogRegressions( x, y )
%[Pslope y r coef Pintercept Resid] = CogRegressions( x, y )
%CogRegressions runs a linear regresion
%   inputs are the x and y varialbes, where x is a cognitive score and y is
%   transfer
%   The outputs are as follors:
%       p= is the p value for the hypothesis that the slope=0
%       y= are the fitted y values based on the x values
%       r= is the r^2 value for the fit
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

X = [x];
T = [ 0 0;1 0];
mdl = LinearModel.fit(X,y,T);%, 'RobustOpts', 'cauchy');
%weights=mdl.Robust.Weights;
Pslope=double(mdl.Coefficients{2,4});
Pintercept=double(mdl.Coefficients{1,4});
yfit=mdl.Fitted';
r=mdl.Rsquared.Ordinary;
coef=double(mdl.Coefficients{:,1});%Intercept=(1, 1), slop=(2,1)
Resid=mdl.Residuals.Studentized;

%Pearson Coefficient
[RHO_Pearson,PVAL_Pearson] = corr(x,y,'type', 'Pearson');

%Spearman Coefficient
[RHO_Spearman,PVAL_Spearman] = corr(x,y,'type', 'Spearman');

% figure
% plot(x, y, '.b'); hold on
% plot(x, yfit, 'r')
% xlabel('X', 'FontSize', 18)
% ylabel('Y', 'FontSize', 18)
% title(['P= ' num2str(Pslope)], 'FontSize', 18)

end

