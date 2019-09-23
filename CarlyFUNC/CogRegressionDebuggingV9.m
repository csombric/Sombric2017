%CogRegressionDebuggingV9
close all
clear all
clc
%Corrections that need to be made
%This update is going to also run correlations on young people and will
%also repor the rho values

%% Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-13:end), 'OvergroundData')~=1
    error('Please navigate to be in the folder with the overground data')
end
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do you want to plot Transfer or %Transfer?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IndicatorT=1;%Look at OGafter
%IndicatorT=2;%Look at %Transfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Smatrix=makeSMatrix;

params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];

groups=[2, 4, 1]; %OA, OASV, YA


% ~~~~~~~~~~~~~~~~~~~~~~~ Load the Cognitive Scores ~~~~~~~~~~~~~~~~~~~~~~~
AllOldAbrupt=load('FinalCogScores.mat');%This has ALL of the cognitive scores for everyone
%ID	Group	ShiftValid	StroopValid	Shift	Stroop	reaction time percentile	Executive funtion %	Cognitive flexibility %	Processing Speed


% ~~~~~~~~~~~~~~~~~~~~~~~ Load the Transfer Values ~~~~~~~~~~~~~~~~~~~~~~~
OFFSET=[];
ReorderingSubjects=([1; 3; 0; 1; 1; 0; 1;1; 2; 2; 1; 1; 0; 1; 1; 1; 1]);
strValues = strtrim(cellstr(num2str([ReorderingSubjects(:)],'(%d)')));
OAResults=barGroupsSpecial(Smatrix, params, {'OA', 'OASV', 'YA', 'YASV'}, OFFSET);%});%Ignores the first few steps

%% 02/09/2016 --> Don't wnat to include OG98?
AllOldAbrupt.FinalCogScores((find(AllOldAbrupt.FinalCogScores(:,1)==98)), 2)=NaN;
AllOldAbrupt.FinalCogScores((find(AllOldAbrupt.FinalCogScores(:,1)==94)), 2)=1;

% ~~~~~~~~~~~~~~~~~~~~~~~ Combine Cognitive and Transfer ~~~~~~~~~~~~~~~~~~~~~~~
dummies=find(AllOldAbrupt.FinalCogScores(:,5)<=.6);%Here I am removing those that did below chance levels
dummies=[dummies; find( AllOldAbrupt.FinalCogScores(:,10)<=.6)];
if isempty(dummies)==0
   AllOldAbrupt.FinalCogScores(dummies,:)=[];
end

COGindex=[];
for i=groups
    COGindex=[COGindex; find(AllOldAbrupt.FinalCogScores(:,2)==i)];
end
 age=[];
 group=[];
RefinedCog=AllOldAbrupt.FinalCogScores(COGindex, :);
old1=[]; old2=[]; young=[]; youngAGE=[];
for k=1:size(RefinedCog, 1)
    
    if RefinedCog(k,2)==2 %OA
        subtemp=[subFileList(Smatrix.OA)];
        for u=1:numel(subtemp)
            if size(subtemp{u},2)==14
                S(u)=  str2num(subtemp{u}(3:4));
            elseif size(subtemp{u},2)==15
                S(u)=  str2num(subtemp{u}(3:5));
            end
        end
        if IndicatorT==1;%Look at OGafter
            RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.OGafter.indiv.OA(find(RefinedCog(k,1)==S), :)];
        elseif IndicatorT==2;%Look at %Transfer
            RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.Transfer2.indiv.OA(find(RefinedCog(k,1)==S), :)];
        end
       group=[group; 2];
        age=[age; 1];youngAGE=[youngAGE; NaN];
    elseif RefinedCog(k,2)==4 %OASV
        subtemp=[subFileList(Smatrix.OASV)];
        for u=1:numel(subtemp)
            if size(subtemp{u},2)==14
                S(u)=  str2num(subtemp{u}(3:4));
            elseif size(subtemp{u},2)==15
                S(u)=  str2num(subtemp{u}(3:5));
            end
        end
        if IndicatorT==1;%Look at OGafter
            RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.OGafter.indiv.OASV(find(RefinedCog(k,1)==S), :)];
        elseif IndicatorT==2;%Look at %Transfer
            RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.Transfer2.indiv.OASV(find(RefinedCog(k,1)==S), :)];
        end
        group=[group; 4];
         age=[age; 1];
         youngAGE=[youngAGE; NaN];
    elseif RefinedCog(k,2)==9 %OANC
    elseif RefinedCog(k,2)==1 %YA
             subtemp=[subFileList(Smatrix.YA)];
        for u=1:numel(subtemp)
            if size(subtemp{u},2)==14
                S(u)=  str2num(subtemp{u}(3:4));
            elseif size(subtemp{u},2)==15
                S(u)=  str2num(subtemp{u}(3:5));
            end
        end
        if isempty(S(find(RefinedCog(k,1)==S)))==1
            RefinedTran(k, :)=[nan*ones(1, size(RefinedTran, 2)) ];
        else
            if IndicatorT==1;%Look at OGafter
                RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.OGafter.indiv.YA(find(RefinedCog(k,1)==S), :)];
            elseif IndicatorT==2;%Look at %Transfer
                RefinedTran(k, :)=[S(find(RefinedCog(k,1)==S)) OAResults.Transfer2.indiv.YA(find(RefinedCog(k,1)==S), :)];
            end
        end
        group=[group; 9];
        age=[age; NaN];
        youngAGE=[youngAGE; 1];
        
    end
    clear subtemp S
end

 ToRemove=find(isnan(RefinedTran(:, 1))==1);
 RefinedTran( ToRemove, :)=[];
 RefinedCog( ToRemove,:)=[];
 age( ToRemove)=[];
 youngAGE( ToRemove)=[];
 
 old1=AllOldAbrupt.FinalCogScores(find(AllOldAbrupt.FinalCogScores(:,2)==2), :);
 old2=AllOldAbrupt.FinalCogScores(find(AllOldAbrupt.FinalCogScores(:,2)==4), :);
 young=AllOldAbrupt.FinalCogScores(find(AllOldAbrupt.FinalCogScores(:,2)==1), :);

% ~~~~~~~~~~~~~~~~~~~~~~~ Perform Stats ~~~~~~~~~~~~~~~~~~~~~~~
RefinedTran(:,1)=[];
for i=1:size(RefinedTran, 2) %S
    [P(i) fit(i,:) r(i) coef(i,:) RHO_Pearson(i) PVAL_Pearson(i) RHO_Spearman(i) PVAL_Spearman(i)]=CogRegressions(RefinedCog(:,5), RefinedTran(:,i)); % % %  Shift
end

lastold=find(isnan(age)==0, 1, 'last');
%Shifting Attention Just Old
for i=1:size(RefinedTran, 2) %S
    [Pold(i) fitold(i,:) rold(i) coefold(i,:) RHO_Pearsonold(i) PVAL_Pearsonold(i) RHO_Spearmanold(i) PVAL_Spearmanold(i)]=CogRegressions(RefinedCog(1:lastold,5), RefinedTran(1:lastold,i)); % % %  Shift
end

%Shifting Attention Just young
for i=1:size(RefinedTran, 2) %S
    special=[lastold+1:length(RefinedCog(:,5))];
    [Pyoung(i) fityoung(i,:) ryoung(i) coefyoung(i,:) RHO_Pearsonyoung(i) PVAL_Pearsonyoung(i) RHO_Spearmanyoung(i) PVAL_Spearmanyoung(i)]=CogRegressions(RefinedCog(special,5), RefinedTran(special,i)); % % %  Shift
end

 RefinedCog(:,7:10)=RefinedCog(:,7:10)/100; 
 
%Processing Speed Percentile
for i=1:size(RefinedTran, 2)
    [Pps(i) fitps(i,:) rps(i) coefps(i,:) RHO_Pearsonps(i) PVAL_Pearsonps(i) RHO_Spearmanps(i) PVAL_Spearmanps(i)]=CogRegressions(RefinedCog(:,10), RefinedTran(:,i)); % % % Processing Speed
end

%Processing Speed Percentile just old
for i=1:size(RefinedTran, 2)
    [Ppsold(i) fitpsold(i,:) rpsold(i) coefpsold(i,:) RHO_Pearsonpsold(i) PVAL_Pearsonpsold(i) RHO_Spearmanpsold(i) PVAL_Spearmanpsold(i)]=CogRegressions(RefinedCog(1:lastold,10), RefinedTran(1:lastold,i)); % % % Processing Speed
end

%Processing Speed Percentile just old
for i=1:size(RefinedTran, 2)
    [Ppsyoung(i) fitpsyoung(i,:) rpsyoung(i) coefpyoung(i,:) RHO_Pearsonpsyoung(i) PVAL_Pearsonpsyoung(i) RHO_Spearmanpsyoung(i) PVAL_Spearmanpsyoung(i)]=CogRegressions(RefinedCog(lastold+1:end,10), RefinedTran(lastold+1:end,i)); % % % Processing Speed
end

figure; 
subplot(2, 4, 1); hold all
plot(RefinedCog(:,5).*age, RefinedTran(:,1).*age, 'r.'); hold on
plot(RefinedCog(special,5), RefinedTran(special,1), 'b.'); hold on

plot(RefinedCog(:,5),  fit(1, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold ,5),  fitold(1, :), 'r', 'LineWidth', 2); hold on
plot(RefinedCog(special,5),  fityoung(1, :), 'b', 'LineWidth', 2); hold on
xlabel({['Shifting'] ['Attention']}, 'FontSize', 18)
ylabel(params{1}, 'FontSize', 18)
title({['Old: Rho=' num2str(RHO_Pearsonold(1)) ' (p=' num2str(PVAL_Pearsonold(1)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonyoung(1)) ' (p=' num2str(PVAL_Pearsonyoung(1)) ')'];...
    ['Both: Rho=' num2str(RHO_Pearson(1)) ' (p=' num2str(PVAL_Pearson(1)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')
legend('Old', 'Young', 'Both Fit', 'Old Fit', 'Young Fit')

subplot(2, 4, 5)
plot(RefinedCog(:,5).*age, RefinedTran(:,2).*age, 'r.'); hold on
plot(RefinedCog(special,5), RefinedTran(special,2), 'b.'); hold on

plot(RefinedCog(:,5),  fit(2, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold ,5),  fitold(2, :), 'r', 'LineWidth', 2); hold on
plot(RefinedCog(special ,5),  fityoung(2, :), 'b', 'LineWidth', 2); hold on
xlabel({['Shifting'] ['Attention']}, 'FontSize', 18)
ylabel(params{2}, 'FontSize', 18)
herewego=find(youngAGE==1,1, 'first');

axis square
title({['Old: Rho=' num2str(RHO_Pearsonold(2)) ' (p=' num2str(PVAL_Pearsonold(2)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonyoung(2)) ' (p=' num2str(PVAL_Pearsonyoung(2)) ')'];...
    ['Both: Rho=' num2str(RHO_Pearson(2)) ' (p=' num2str(PVAL_Pearson(2)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')


subplot(2, 4, 2); hold all
plot(RefinedCog(:,10).*age, RefinedTran(:,1).*age, 'r.'); hold on
plot(RefinedCog(special,10), RefinedTran(special,1), 'b.'); hold on

plot(RefinedCog(:,10),  fitps(1, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold,10),  fitpsold(1, :), 'r', 'LineWidth', 2); hold on
plot(RefinedCog(lastold+1:end,10),  fitpsyoung(1, :), 'b', 'LineWidth', 2); hold on
xlabel({['Processing'] ['Speed']}, 'FontSize', 18)
ylabel(params{1}, 'FontSize', 18)

title({['Old: Rho=' num2str(RHO_Pearsonpsold(1)) ' (p=' num2str(PVAL_Pearsonpsold(1)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonpsyoung(1)) ' (p=' num2str(PVAL_Pearsonpsyoung(1)) ')'];...
    ['Bpth: Rho=' num2str(RHO_Pearsonps(1)) ' (p=' num2str(PVAL_Pearsonps(1)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')

subplot(2, 4, 6)
plot(RefinedCog(:,10).*age, RefinedTran(:,2).*age, 'r.'); hold on
plot(RefinedCog(special,10), RefinedTran(special,2), 'b.'); hold on

plot(RefinedCog(:,10),  fitps(2, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold,10),  fitpsold(2, :), 'r', 'LineWidth', 2); hold on
plot(RefinedCog(lastold+1:end,10),  fitpsyoung(2, :), 'b', 'LineWidth', 2); hold on
xlabel({['Processing'] ['Speed']}, 'FontSize', 18)
ylabel(params{2}, 'FontSize', 18)
axis square

title({['Old: Rho=' num2str(RHO_Pearsonpsold(2)) ' (p=' num2str(PVAL_Pearsonpsold(2)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonpsyoung(2)) ' (p=' num2str(PVAL_Pearsonpsyoung(2)) ')'];...
    ['Both; Rho=' num2str(RHO_Pearsonps(2)) ' (p=' num2str(PVAL_Pearsonps(2)) ')']}, 'FontSize', 14);
set(gcf,'renderer','painters')

%%%%%%
subplot(2, 4, 4); hold all
plot(RefinedCog(:,5).*age, RefinedTran(:,4).*age, 'r.'); hold on
plot(RefinedCog(special,5), RefinedTran(special,4), 'b.'); hold on

plot(RefinedCog(:,5),  fit(4, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold ,5),  fitold(4, :), 'r', 'LineWidth', 2); hold on

plot(RefinedCog(special, 5),  fityoung(4, :), 'b', 'LineWidth', 2); hold on
xlabel({['Shifting'] ['Attention']}, 'FontSize', 18)
ylabel(params{4}, 'FontSize', 18)

title({['Old: Rho=' num2str(RHO_Pearsonold(4)) ' (p=' num2str(PVAL_Pearsonold(4)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonyoung(4)) ' (p=' num2str(PVAL_Pearsonyoung(4)) ')'];...
    ['Both: Rho=' num2str(RHO_Pearson(4)) ' (p=' num2str(PVAL_Pearson(1)) ')']}, 'FontSize', 14);
axis square
set(gcf,'renderer','painters')

subplot(2, 4, 8)
plot(RefinedCog(:,10).*age, RefinedTran(:,4).*age, '.r'); hold on
plot(RefinedCog(special,10), RefinedTran(special,4), 'b.'); hold on

plot(RefinedCog(:,10),  fitps(4, :), 'k', 'LineWidth', 2); hold on
plot(RefinedCog(1:lastold,10),  fitpsold(4, :), 'r', 'LineWidth', 2); hold on
plot(RefinedCog(lastold+1:end,10),  fitpsyoung(4, :), 'b', 'LineWidth', 2); hold on
xlabel({['Processing'] ['Speed']}, 'FontSize', 18)
ylabel(params{4}, 'FontSize', 18)
axis square
title({['Old: Rho=' num2str(RHO_Pearsonpsold(4)) ' (p=' num2str(PVAL_Pearsonpsold(4)) ')'];...
    ['Young: Rho=' num2str(RHO_Pearsonpsyoung(4)) ' (p=' num2str(PVAL_Pearsonpsyoung(4)) ')'];...
    ['Both; Rho=' num2str(RHO_Pearsonps(4)) ' (p=' num2str(PVAL_Pearsonps(4)) ')']}, 'FontSize', 14);
set(gcf,'renderer','painters')

% % % % Updated Cog scores Col headers=
% % % % 1.) ID
% % % % 2.) Group
% % % % 3.) ShiftValid
% % % % 4.) StroopValid
% % % % 5.) Shift
% % % % 6.) Stroop
% % % % 7.) PA: Tout
% % % % 8.) %PA: Tout
% % % % 9.) PA: Sout
% % % %10.) %PA: Sout
% % % %11.) PA: Tcont
% % % %12.) %PA: Tcont
% % % %13.) PA: Scout
% % % %14.) %PA: Scont
% % % %15.) PA: Vcout
% % % %16.) %PA: Vcont
% % % %17.) PA: Ncout
% % % %18.) %PA: Ncont