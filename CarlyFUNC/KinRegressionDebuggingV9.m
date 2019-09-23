close all
clear all
clc
%Corrections that need to be made
%This update is going to also run correlations on young people and will
%also repor the rho values

%% Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-12:end), 'TreadmillData')~=1
    error('Please navigate to be in the folder with the treadmill data')
end
%%

StudyData_TM=makeSMatrix;

Colors={[0 0 1],[1 0 0 ],[0 1 0],[1 0 1]};
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];

OFFSET=[];

A=barGroupsFirstSteps(StudyData_TM, params, {'OA', 'YA', 'OASV', 'YASV'}, 0, [], []); %Same as what is done above
subs=[{subFileList(StudyData_TM.OA)} {subFileList(StudyData_TM.OASV)} {subFileList(StudyData_TM.YA)} {subFileList(StudyData_TM.YASV)}];
group=[];
for i=1:length(subs)
    group=[group; i.*ones(length(subs{1, i}), 1)];
end

conds=[{'adaptation'} {'re-adaptation'}];
[Strides2SS]=AvgTimeCourse_Whole(subs,params,conds,A); %This is the function that I use to do the rate calculations

Forgetting=[A.PerForget.indiv.OA; A.PerForget.indiv.OASV; A.PerForget.indiv.YA; A.PerForget.indiv.YASV];
%Strides2SS=[A.Strides2SS.indiv.OA; A.Strides2SS.indiv.OASV; A.Strides2SS.indiv.YA];
Learn=[A.catch.indiv.OA; A.catch.indiv.OASV; A.catch.indiv.YA; A.catch.indiv.YASV];
Extent1=[A.AdaptExtent1.indiv.OA; A.AdaptExtent1.indiv.OASV; A.AdaptExtent1.indiv.YA; A.AdaptExtent1.indiv.YASV];  


for i=1:size(params, 2)
    [P(i) fit(i,:) r(i) coef(i,:) RHO_Pearson(i) PVAL_Pearson(i) RHO_Spearman(i) PVAL_Spearman(i)]=CogRegressions(Forgetting(:,i), Strides2SS(:,i)); % % %  Shift
    %[P(i) fit(i,:) r(i) coef(i,:) RHO_Pearson(i) PVAL_Pearson(i) RHO_Spearman(i) PVAL_Spearman(i)]=CogRegressions(Learn(:,i), Extent1(:,i)); % % %  Shift

end

figure
subplot(4, 6, 1); hold all
cat=1;

for i=1:length(subs)
   if i==length(subs)
       plot(Forgetting(cat:end,1), Strides2SS(cat:end,1), '.', 'MarkerFaceColor', Colors{i}); hold on
   else
    plot(Forgetting(cat:length(subs{1, i})+cat,1), Strides2SS(cat:length(subs{1, i})+cat,1), '.', 'MarkerFaceColor', Colors{i}); hold on
   end
    cat=cat+length(subs{1, i});
end


plot(Forgetting(:,1),  fit(1, :), 'k', 'LineWidth', 2); hold on
 xlabel({['PerForgetting']}, 'FontSize', 10)
 ylabel({['Strides2SS']}, 'FontSize', 10)
 title({[params{1}];...
     ['Rho=' num2str(RHO_Pearson(1)) ' (p=' num2str(PVAL_Pearson(1)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')
legend ('OA', 'OASV', 'YA', 'YASV')

subplot(4, 6, 7); hold all
cat=1;

for i=1:length(subs)
   if i==length(subs)
       plot(Forgetting(cat:end,2), Strides2SS(cat:end,2), '.', 'MarkerFaceColor', Colors{i}); hold on
   else
    plot(Forgetting(cat:length(subs{1, i})+cat,2), Strides2SS(cat:length(subs{1, i})+cat,2), '.',  'MarkerFaceColor', Colors{i}); hold on
   end
    cat=cat+length(subs{1, i});
end

plot(Forgetting(:,2),  fit(2, :), 'k', 'LineWidth', 2); hold on
 xlabel({['PerForgetting']}, 'FontSize', 10)
 ylabel({['Strides2SS']}, 'FontSize', 10)
title({[params{2}];...
   ['Rho=' num2str(RHO_Pearson(2)) ' (p=' num2str(PVAL_Pearson(2)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')

subplot(4, 6, 19); hold all
cat=1;

for i=1:length(subs)
   if i==length(subs)
       plot(Forgetting(cat:end,4), Strides2SS(cat:end,4), '.', 'MarkerFaceColor', Colors{i}); hold on
   else
    plot(Forgetting(cat:length(subs{1, i})+cat,4), Strides2SS(cat:length(subs{1, i})+cat,4), '.', 'MarkerFaceColor', Colors{i}); hold on
   end
    cat=cat+length(subs{1, i});
end

plot(Forgetting(:,4),  fit(4, :), 'k', 'LineWidth', 2); hold on
 xlabel({['PerForgetting']}, 'FontSize', 10)
 ylabel({['Strides2SS']}, 'FontSize', 10)
title({[params{4}];...
   ['Rho=' num2str(RHO_Pearson(4)) ' (p=' num2str(PVAL_Pearson(4)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')