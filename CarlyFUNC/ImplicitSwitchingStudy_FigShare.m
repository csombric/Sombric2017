%% Sombric et al, 2017 Code
close all
clear all
clc

%Please navigate so that your path includes the code from gitHub and make
%sure you are in the appropriate data foulder
display('Make sure the data available on FigShare is in your working directory')

%% Figure 2:Early Adaptaiton Behavior

%Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-12:end), 'TreadmillData')~=1
    error('Please navigate to be in the folder with the treadmill data')
end

StudyData_TM=makeSMatrix;
subs=[{subFileList(StudyData_TM.OA)} {subFileList(StudyData_TM.OASV)} {subFileList(StudyData_TM.YA)} {subFileList(StudyData_TM.YASV)}];
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];
conds=[{'TM base'} {'adaptation'} {'re-adaptation'}];
adaptationData.plotAvgTimeCourse(subs,params,conds,5, 0);% How to do the general timecourse plotting
conds=[{'adaptation'} {'re-adaptation'}];
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];
A=barGroupsFirstSteps(StudyData_TM, params, {'OA','OASV', 'YA', 'YASV'}, 1, [], []);
epochs=[{'Strides2SS'} {'PerForget'}];
[FinalStata]=AvgTimeCourse_Whole(subs,params,conds,A); %This is the function that I use to do the rate calculations
B=barGroupsFirstSteps(StudyData_TM, params, {'OA','OASV', 'YA', 'YASV'}, 0, FinalStata, epochs); %this is how the bar plots are made

%% Figure 3: %Forgetting and Rate
KinRegressionDebuggingV9

%% Figure 4: %Late Adaptation Behavior
%Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-12:end), 'TreadmillData')~=1
    error('Please navigate to be in the folder with the treadmill data')
end

StudyData_TM=makeSMatrix;
epochs=[{'TMsteady2'} {'AdaptExtent'} {'catch'}];
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];
barGroupsFirstSteps(StudyData_TM, params, {'OA','OASV', 'YA', 'YASV'}, 1, [], epochs);

%% Figure 5: Overground Behavior
%Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-13:end), 'OvergroundData')~=1
    error('Please navigate to be in the folder with the treadmill data')
end

StudyData_OG=makeSMatrix;
subs=[{subFileList(StudyData_OG.OA)} {subFileList(StudyData_OG.OASV)} {subFileList(StudyData_OG.YA)} {subFileList(StudyData_OG.YASV)}];
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];
conds=[{'OG base'} {'OG post'}];
adaptationData.plotAvgTimeCourse(subs,params,conds,5, 0);% How to do the general timecourse plotting
epochs=[{'OGafter'} {'Transfer2'}];
A=barGroupsFirstSteps(StudyData_TM, params, {'OA','OASV', 'YA', 'YASV'}, 1, [], epochs);

%% Figure 6: Cognitive Correlations
CogRegressionDebuggingV9

%% Figure 7: Treadmill Washout
%Just making sure you are in the correct foulder
WhereAreWe=cd;
if strcmp(WhereAreWe(end-12:end), 'TreadmillData')~=1
    error('Please navigate to be in the folder with the treadmill data')
end

StudyData_TM=makeSMatrix;
params=[{'spatialContribution'} {'stepTimeContribution'} {'velocityContribution'} {'netContribution'}];
epochs=[{'TMafter'} {'Washout2'} ];
barGroupsFirstSteps(StudyData_TM, params, {'OA','OASV', 'YA', 'YASV'}, 1, [], epochs);

