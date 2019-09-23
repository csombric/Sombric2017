function [FinalStata]=AvgTimeCourse_Whole(adaptDataList,params,conditions, A)
% this version was my first attempt to plot the readaptation stuff,
% AND DO SO WITHOUT CROPPING THE DATA
%adaptDataList must be cell array of 'param.mat' file names
%params is cell array of parameters to plot. List with commas to
%plot on separate graphs or with semicolons to plot on same graph.
%conditions is cell array of conditions to plot
%binwidth is the number of data points to average in time
%indivFlag - set to true to plot individual subject time courses
%indivSubs - must be a cell array of 'param.mat' file names that is
%a subset of those in the adaptDataList. Plots specific subjects
%instead of all subjects.

allValues=cell(4, 4);
allValuesC=cell(4, 4);
allValuesALL=cell(4, 4);
Stride2SS=cell(4,4);
whereIS=cell(4,4);
ToAICAnalysis=[];
Divider=cell(4, 4);
%First: see if adaptDataList is a single subject (char), a cell
%array of subject names (one group of subjects), or a cell array of cell arrays of
%subjects names (several groups of subjects), and put all the
%cases into the same format
if isa(adaptDataList,'cell')
    if isa(adaptDataList{1},'cell')
        auxList=adaptDataList;
    else
        auxList{1}=adaptDataList;
    end
elseif isa(adaptDataList,'char')
    auxList{1}={adaptDataList};
else
    auxList=fieldnames(adaptDataList);%New 9/23/2019
end
Ngroups=length(auxList);

%make sure params is a cell array
if isa(params,'char')
    params={params};
end

%check condition input
if nargin>2
    if isa(conditions,'char')
        conditions={conditions};
    end
else
    load(auxList{1}{1})
    conditions=adaptData.metaData.conditionName; %default
end
for c=1:length(conditions)
    cond{c}=conditions{c}(ismember(conditions{c},['A':'Z' 'a':'z' '0':'9'])); %remove non alphanumeric characters
end

if nargin<4
    binwidth=1;
end

if nargin>5 && isa(indivSubs,'cell')
    if ~isa(adaptDataList{1},'cell')
        indivSubs{1}=indivSubs;
    end
elseif nargin>5 && isa(indivSubs,'char')
    indivSubs{1}={indivSubs};
end

%Load data and determine length of conditions
nConds= length(conditions);
s=1;

for group=1:Ngroups
    for subject=1:length(auxList{group})
        %Load subject
        load(auxList{group}{subject});
        
        %normalize contributions based on combined step lengths
        SLf=adaptData.data.getParameter('stepLengthFast');
        SLs=adaptData.data.getParameter('stepLengthSlow');
        Dist=SLf+SLs;
        contLabels={'spatialContribution','stepTimeContribution','velocityContribution','netContribution'};
        [~,dataCols]=isaParameter(adaptData.data,contLabels);
        for c=1:length(contLabels)
            contData=adaptData.data.getParameter(contLabels(c));
            contData=contData./Dist;
            adaptData.data.Data(:,dataCols(c))=contData;
        end
        
        %EDIT: create contribution error values
        vels=adaptData.data.getParameter('stanceSpeedSlow');
        velf=adaptData.data.getParameter('stanceSpeedFast');
        deltaST=adaptData.data.getParameter('stanceTimeDiff');
        velCont=adaptData.data.getParameter('velocityContribution');
        stepCont=adaptData.data.getParameter('stepTimeContribution');
        spatialCont=adaptData.data.getParameter('spatialContribution');
        Tideal=((vels+velf)./2).*deltaST./Dist;
        Sideal=(-velCont)-Tideal;
        [~,dataCols]=isaParameter(adaptData.data,{'Tgoal','Sgoal'});
        adaptData.data.Data(:,dataCols(1))=Tideal-stepCont;
        adaptData.data.Data(:,dataCols(2))=Sideal-spatialCont;
        
        adaptData = adaptData.removeBias; %CJS
        
        for c=1:nConds
            %                         if false
            if strcmpi(conditions{c},'adaptation')  || strcmpi(conditions{c},'TM post') || strcmpi(conditions{c},'re-adaptation')
                trials=adaptData.getTrialsInCond(conditions{c});
                for t=1:length(trials)
                    dataPts=adaptData.getParamInTrial(params,trials(t));
                    nPoints=size(dataPts,1);
                    if nPoints == 0
                        numPts.(cond{c}).(['trial' num2str(t)])(s)=NaN;
                    else
                        numPts.(cond{c}).(['trial' num2str(t)])(s)=nPoints;
                    end
                    for p=1:length(params)
                        %itialize so there are no inconsistant dimensions or out of bounds errors
                        values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,1000); %this assumes that the max number of data points that could exist in a single condition is 1000
                        values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
                    end
                end
                if min(numPts.(cond{c}).(['trial' num2str(t)]))==0
                    bad=find(numPts.(cond{c}).(['trial' num2str(t)])==0);
                    numPts.(cond{c}).(['trial' num2str(t)])=[];
                end
                %~~~~~~~~~~~~
            end
        end
        s=s+1;
    end
end

for group=1:Ngroups
    Xstart=1;
    lineX=0;
    subjects=auxList{group};
    %for c=1:length(conditions)
    if strcmpi(conditions{c},'adaptation') || strcmpi(conditions{c},'re-adaptation') || strcmpi(conditions{c},'TM post')
        trials=[adaptData.getTrialsInCond(conditions{1}) adaptData.getTrialsInCond(conditions{2})];
        
        [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
        while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
            numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
            %[maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
            [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
        end
        
        if maxPts==0
            continue
        end
        
        for p=1:length(params)
           
            %This is to get the all of adaptation for each subject
            maxPts=sum(maxPts);
            t=1;
            for person=1:size(values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,end-maxPts:end),1)
                ender1=find(isnan(values(group).(params{p}).(cond{1}).(['trial' num2str(1)])(person,:))==0, 1, 'last');
                ender2=find(isnan(values(group).(params{p}).(cond{1}).(['trial' num2str(2)])(person,:))==0, 1, 'last');
                ender3=find(isnan(values(group).(params{p}).(cond{1}).(['trial' num2str(3)])(person,:))==0, 1, 'last');
                ender4=find(isnan(values(group).(params{p}).(cond{1}).(['trial' num2str(4)])(person,:))==0, 1, 'last');
                ender5=find(isnan(values(group).(params{p}).(cond{2}).(['trial' num2str(1)])(person,:))==0, 1, 'last');
                ender6=find(isnan(values(group).(params{p}).(cond{2}).(['trial' num2str(2)])(person,:))==0, 1, 'last');
                
                
                allValues{group, p}= [allValues{group, p}(:,:); [values(group).(params{p}).(cond{1}).(['trial' num2str(1)])(person,1:ender1) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(2)])(person,1:ender2) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(3)])(person,1:ender3) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(4)])(person,1:ender4) ...
                    nan(1, 700-ender1-ender2-ender3-ender4)]]; %% CJS here is where I am taking the adaptation timecourse to fit
                Divider{group, p}=[ Divider{group, p}; ender1 ender2 ender3 ender4 ender5 ender6];
                
                allValuesC{group, p}= [allValuesC{group, p}(:,:); [values(group).(params{p}).(cond{2}).(['trial' num2str(1)])(person,1:ender5) ...
                    values(group).(params{p}).(cond{2}).(['trial' num2str(2)])(person,1:ender6) ...
                    nan(1, 700-ender5-ender6)]]; %% CJS here is where I am taking the adaptation timecourse to fit
                
                allValuesALL{group, p}= [allValuesALL{group, p}(:,:); [values(group).(params{p}).(cond{1}).(['trial' num2str(1)])(person,1:ender1) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(2)])(person,1:ender2) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(3)])(person,1:ender3) ...
                    values(group).(params{p}).(cond{1}).(['trial' num2str(4)])(person,1:ender4) ...
                    values(group).(params{p}).(cond{2}).(['trial' num2str(1)])(person,1:ender5) ...
                    values(group).(params{p}).(cond{2}).(['trial' num2str(2)])(person,1:ender6) ...
                    nan(1, 950-ender1-ender2-ender3-ender4-ender5-ender6)]];
                
                
            end
        end
    end
end

%% How to calculate strides to ss
for gr=[1:4]
    % Need to visualize to make sure that this is working correctly
    %subplot(2, 2, gr)
    
    for var=[1 2 4 3 ]
        
        for qq=1:size(allValues{gr, var},1)
            
            %Smooth the data:
            allValuesALL{gr, var}(qq,:)=bin_dataV1(allValuesALL{gr, var}(qq,:)',20)'; SmoothType='Whole, BW=20, first not before raw min';
            %Should be 20
  
            %Here I am using the final steady state that subjects reached
            if gr==1
                ss=A.TMsteady2.indiv.OA(qq, var);
                shifter=A.TMsteady2.indiv.OA(qq, 3)-A.TMsteady2.indiv.OA(qq, 4);
            elseif gr==2
                ss=A.TMsteady2.indiv.OASV(qq, var);
                shifter=A.TMsteady2.indiv.OASV(qq, 3)-A.TMsteady2.indiv.OASV(qq, 4);
            elseif gr==3
                ss=A.TMsteady2.indiv.YA(qq, var);
                shifter=A.TMsteady2.indiv.YA(qq, 3)-A.TMsteady2.indiv.YA(qq, 4);
            elseif gr==4
                ss=A.TMsteady2.indiv.YASV(qq, var);
                shifter=A.TMsteady2.indiv.YASV(qq, 3)-A.TMsteady2.indiv.YASV(qq, 4);
            end
            
            
            
            % % % %Here I am shifting the SLasym up
            whereIS{gr, var}(qq, :)=find(allValues{gr, var}(qq, :)==nanmin(allValues{gr, var}(qq, 1:50)),1,  'first');%use the non-smoothed data to shift the curves
            minmin=allValuesALL{gr, var}(qq, whereIS{gr, var}(qq, :));
            
            if var==4
                %This is a new thing that I am trying were I shift each
                %subject by their own velocty steady state
                allValuesALL{gr, var}(qq, :)=allValuesALL{gr, var}(qq, :)+abs(shifter);
                ss=ss+abs(shifter);
            end
            
            
            if var==3 %SLasym
                
                %This is the certified way to do this: I shif by 0.3, which
                %is approximately the SS of the velocity domain as well as
                %the lowest group average
                shifter=.3;
                allValuesALL{gr, var}(qq, :)=allValuesALL{gr, var}(qq, :)+abs(shifter);
                ss=ss+shifter;
            end
                        
            t=find(allValuesALL{gr, var}(qq, :)>=ss*.632);
          
            first_t=t(1);
            knot=2;
            while first_t<=whereIS{gr, var}(qq, :)%5
                first_t=t(knot);
                knot=knot+1;
            end
            
            Stride2SS{gr, var}=[Stride2SS{gr, var} first_t];
            
% % % % %             if var==1 %Ploting
% % % % %                 
% % % % %                 if gr == 1
% % % % %                     %ToAICAnalysis=[ToAICAnalysis; allValuesALL{gr, var}(qq, :)];
% % % % %                     figure(1)
% % % % %                     subplot(3, 4, qq)
% % % % %                     
% % % % %                     plot([allValuesALL{gr, var}(qq, :)], 'b.-', 'MarkerSize', 25);hold on
% % % % %                     %plot(t(1), allValuesALL{gr, var}(qq, (t(1))), '.c', 'MarkerSize', 25); hold on
% % % % %                     plot(whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9, allValuesALL{gr, var}(qq, whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9), 'c.', 'MarkerSize', 25);hold on
% % % % %                     plot(first_t, allValuesALL{gr, var}(qq, first_t), '.r', 'MarkerSize', 25); hold on
% % % % %                     line([0 900], [ss ss],'Color', 'k', 'LineWidth', 1)
% % % % %                     line([0 900], [ss*.632 ss*.632],'Color', 'k', 'LineWidth', 1, 'LineStyle',':')
% % % % %                     
% % % % %                     line([Divider{gr, var}(qq) Divider{gr, var}(qq)], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:2)) sum(Divider{gr, var}(qq, 1:2))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:3)) sum(Divider{gr, var}(qq, 1:3))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:4)) sum(Divider{gr, var}(qq, 1:4))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:5)) sum(Divider{gr, var}(qq, 1:5))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:6)) sum(Divider{gr, var}(qq, 1:6))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     
% % % % %                     whoIS=cell2mat(adaptDataList{1, gr}(1, qq));
% % % % %                     title([whoIS(1:end-10) '  Stride to SS = ' num2str(first_t)]);
% % % % %                     if var ==1
% % % % %                         ylabel('Spatial')
% % % % %                     elseif var==2
% % % % %                         ylabel('temporal')
% % % % %                     elseif var==4
% % % % %                         ylabel('SLasym')
% % % % %                     end
% % % % %                     
% % % % %                     xlabel(['OA ' SmoothType])
% % % % %                     axis tight
% % % % %                     
% % % % %                 end
% % % % %                 
% % % % %                 
% % % % %                 if gr == 2
% % % % %                     %ToAICAnalysis=[ToAICAnalysis; allValuesALL{gr, var}(qq, :)];
% % % % %                     figure(2)
% % % % %                     subplot(3, 4, qq)
% % % % %                     plot([allValuesALL{gr, var}(qq, :)], 'b.-', 'MarkerSize', 25);hold on
% % % % %                     %plot(t(1), allValuesALL{gr, var}(qq, (t(1))), '.c', 'MarkerSize', 25); hold on
% % % % %                     plot(whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9, allValuesALL{gr, var}(qq, whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9), 'c.', 'MarkerSize', 25);hold on
% % % % %                     plot(first_t, allValuesALL{gr, var}(qq, first_t), '.r', 'MarkerSize', 25); hold on
% % % % %                     
% % % % %                     line([0 900], [ss ss],'Color', 'k', 'LineWidth', 1)
% % % % %                     line([0 900], [ss*.632 ss*.632],'Color', 'k', 'LineWidth', 1, 'LineStyle',':')
% % % % %                     
% % % % %                     line([Divider{gr, var}(qq) Divider{gr, var}(qq)], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:2)) sum(Divider{gr, var}(qq, 1:2))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:3)) sum(Divider{gr, var}(qq, 1:3))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:4)) sum(Divider{gr, var}(qq, 1:4))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:5)) sum(Divider{gr, var}(qq, 1:5))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:6)) sum(Divider{gr, var}(qq, 1:6))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     
% % % % %                     whoIS=cell2mat(adaptDataList{1, gr}(1, qq));
% % % % %                     title([whoIS(1:end-10) '  Stride to SS = ' num2str(first_t)]);
% % % % %                     if var ==1
% % % % %                         ylabel('Spatial')
% % % % %                     elseif var==2
% % % % %                         ylabel('temporal')
% % % % %                     elseif var==4
% % % % %                         ylabel('SLasym')
% % % % %                     end
% % % % %                     xlabel(['OASV ' SmoothType])
% % % % %                 end
% % % % %                 
% % % % %                 if gr == 3
% % % % %                     %ToAICAnalysis=[ToAICAnalysis; allValuesALL{gr, var}(qq, :)];
% % % % %                     figure(3)
% % % % %                     subplot(3, 4, qq)
% % % % %                     plot([allValuesALL{gr, var}(qq, :)], 'b.-', 'MarkerSize', 25);hold on
% % % % %                     %plot(t(1), allValuesALL{gr, var}(qq, (t(1))), '.c', 'MarkerSize', 25); hold on
% % % % %                     plot(whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9, allValuesALL{gr, var}(qq, whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9), 'c.', 'MarkerSize', 25);hold on
% % % % %                     plot(first_t, allValuesALL{gr, var}(qq, first_t), '.r', 'MarkerSize', 25); hold on
% % % % %                     
% % % % %                     line([0 900], [ss ss],'Color', 'k', 'LineWidth', 1)
% % % % %                     line([0 900], [ss*.632 ss*.632],'Color', 'k', 'LineWidth', 1, 'LineStyle',':')
% % % % %                     
% % % % %                     line([Divider{gr, var}(qq) Divider{gr, var}(qq)], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:2)) sum(Divider{gr, var}(qq, 1:2))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:3)) sum(Divider{gr, var}(qq, 1:3))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:4)) sum(Divider{gr, var}(qq, 1:4))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:5)) sum(Divider{gr, var}(qq, 1:5))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:6)) sum(Divider{gr, var}(qq, 1:6))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     
% % % % %                     whoIS=cell2mat(adaptDataList{1, gr}(1, qq));
% % % % %                     title([whoIS(1:end-10) '  Stride to SS = ' num2str(first_t)]);
% % % % %                     if var ==1
% % % % %                         ylabel('Spatial')
% % % % %                     elseif var==2
% % % % %                         ylabel('temporal')
% % % % %                     elseif var==4
% % % % %                         ylabel('SLasym')
% % % % %                     end
% % % % %                     xlabel(['YA ' SmoothType])
% % % % %                 end
% % % % %                 
% % % % %                 
% % % % %                 if gr == 4
% % % % %                     ToAICAnalysis=[ToAICAnalysis; allValuesALL{gr, var}(qq, :)];
% % % % %                     figure(4)
% % % % %                     subplot(3, 4, qq)
% % % % %                     
% % % % %                     plot([allValuesALL{gr, var}(qq, :)], 'b.-', 'MarkerSize', 25);hold on
% % % % %                     %plot(t(1), allValuesALL{gr, var}(qq, (t(1))), '.c', 'MarkerSize', 25); hold on
% % % % %                     plot(whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9, allValuesALL{gr, var}(qq, whereIS{gr, var}(qq, :):whereIS{gr, var}(qq, :)+9), 'c.', 'MarkerSize', 25);hold on
% % % % %                     plot(first_t, allValuesALL{gr, var}(qq, first_t), '.r', 'MarkerSize', 25); hold on
% % % % %                     
% % % % %                     line([0 900], [ss ss],'Color', 'k', 'LineWidth', 1)
% % % % %                     line([0 900], [ss*.632 ss*.632],'Color', 'k', 'LineWidth', 1, 'LineStyle',':')
% % % % %                     
% % % % %                     line([Divider{gr, var}(qq) Divider{gr, var}(qq)], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:2)) sum(Divider{gr, var}(qq, 1:2))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:3)) sum(Divider{gr, var}(qq, 1:3))], [-.1 .1], 'Color', 'k', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:4)) sum(Divider{gr, var}(qq, 1:4))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:5)) sum(Divider{gr, var}(qq, 1:5))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     line([sum(Divider{gr, var}(qq, 1:6)) sum(Divider{gr, var}(qq, 1:6))], [-.1 .1], 'Color', 'c', 'LineStyle','--');
% % % % %                     
% % % % %                     whoIS=cell2mat(adaptDataList{1, gr}(1, qq));
% % % % %                     title([whoIS(1:end-10) '  Stride to SS = ' num2str(first_t)]);
% % % % %                     if var ==1
% % % % %                         ylabel('Spatial')
% % % % %                     elseif var==2
% % % % %                         ylabel('temporal')
% % % % %                     elseif var==4
% % % % %                         ylabel('SLasym')
% % % % %                     end
% % % % %                     xlabel(['YASV ' SmoothType])
% % % % %                 end
% % % % %             end
        end
    end
end

ReadyAIC=mean(ToAICAnalysis);

IntoStata_dataS= [];
IntoStata_dataT= [];
IntoStata_dataV= [];
IntoStata_dataN= [];
IntoStata_epoch= [];
IntoStata__group=[];
IntoStata_p=[];
IntoStata_visit=[];
IntoStata_age=[];
IntoStata_strideS=[];
IntoStata_strideT=[];
IntoStata_strideV=[];
IntoStata_strideN=[];
IntoStata_group=[];
% % %
for g=1:size(adaptDataList, 2)%4
    IntoStata_strideS= [IntoStata_strideS; Stride2SS{g, 1}'];
    IntoStata_strideT= [IntoStata_strideT; Stride2SS{g, 2}'];
    IntoStata_strideV= [IntoStata_strideV; Stride2SS{g, 3}'];
    IntoStata_strideN= [IntoStata_strideN; Stride2SS{g, 4}']; 
    
end

FinalStata= [IntoStata_strideS IntoStata_strideT IntoStata_strideV IntoStata_strideN];

end

