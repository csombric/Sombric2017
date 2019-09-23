classdef adaptationData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        data %Contains adaptation parameters
    end
    
    properties (Dependent)
        
    end
    
    methods
        %Constructor
        function this=adaptationData(meta,sub,data)
            
            if nargin>0 && isa(meta,'experimentMetaData')
                this.metaData=meta;
            else
                ME=MException('adaptationData:Constructor','metaData is not an experimentMetaData type object.');
                throw(ME);
            end
            
            if nargin>1 && isa(sub,'subjectData')
                this.subData=sub;
            else
                ME=MException('adaptationData:Constructor','Subject data is not a subjectData type object.');
                throw(ME);
            end
            
            if nargin>2 && isa(data,'paramData')
                this.data=data;
            else
                ME=MException('adaptationData:Constructor','Data is not a paramData type object.');
                throw(ME);
            end
        end
        
        function newThis=removeBias(this,conditions)
            % removeBias('condition') or removeBias({'Condition1','Condition2',...}) 
            % removes the median value of every parameter from each trial of the
            % same type as the condition entered. If no condition is
            % specified, then the condition name that contains both the
            % type string and the string 'base' is used as the baseline
            % condition.
            
            if nargin>1
                newThis=removeBiasV2(this,conditions);
            else
                newThis=removeBiasV2(this);
            end
            
            %             if nargin>1
            %                 %convert input to standardized format
            %                 if isa(conditions,'char')
            %                     conditions={conditions};
            %                 elseif isa(conditions,'double')
            %                     conditions=conds(conditions);
            %                 end
            %                 % validate condition(s)
            %                 cInput=conditions(this.isaCondition(conditions));
            %             end
            %
            %             trialsInCond=this.metaData.trialsInCondition;
            %             conds=this.metaData.conditionName;
            %             trialTypes=this.data.trialTypes;
            %             types=unique(trialTypes(~cellfun(@isempty,trialTypes)));
            %             labels=this.data.labels;
            %
            %             for itype=1:length(types)
            %                 allTrials=[];
            %                 baseTrials=[];
            %                 for c=1:length(conds)
            %                     trials=trialsInCond{c};
            %                     if all(strcmpi(trialTypes(trials),types{itype}))
            %                         allTrials=[allTrials trials];
            %                         if nargin<2 || isempty(conditions)
            %                             %if no conditions were entered, this just searches all
            %                             %condition names for the string 'base' and
            %                             %the Type string
            %                             if ~isempty(strfind(lower(conds{c}),'base')) && ~isempty(strfind(lower(conds{c}),lower(types{itype})))
            %                                 baseTrials=[baseTrials trials];
            %                             end
            %                         else
            %                             if any(ismember(cInput,conds{c}))
            %                                 baseTrials=[baseTrials trials];
            %                             end
            %                         end
            %                     end
            %                 end
            %                 inds=cell2mat(this.data.indsInTrial(allTrials));
            %                 if ~isempty(baseTrials)
            %                     base=nanmedian(this.getParamInTrial(labels,baseTrials));
            %                     newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
            %                 else
            %                     warning(['No ' types{itype} ' baseline trials detected. Bias not removed from ' types{itype} ' trials.'])
            %                     newData(inds,:)=this.data.Data(inds,:);
            %                 end
            %             end
            %
            %             newParamData=paramData(newData,labels,this.data.indsInTrial,this.data.trialTypes);
            %             newThis=adaptationData(this.metaData,this.subData,newParamData);
        end
        
        %Other I/O functions:
        function labelList=getParameters(this)
            labelList=this.data.labels;
        end
        
        function [data,inds,auxLabel]=getParamInTrial(this,label,trial)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);
            
            % validate trial(s)
            trialNum = [];
            for t=trial
                if isempty(this.data.indsInTrial(t))
                    warning(['Trial number ' num2str(t) ' is not a trial in this experiment.'])
                else
                    trialNum(end+1)=t;
                end
            end
            %get data
            inds=cell2mat(this.data.indsInTrial(trialNum));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function [data,inds,auxLabel]=getParamInCond(this,label,condition)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);
            
            % validate condition(s)
            condNum = [];
            if isa(condition,'char')
                condition={condition};
            end
            if isa(condition,'cell')
                for i=1:length(condition)
                    boolFlags=strcmpi(this.metaData.conditionName,condition{i});
                    if any(boolFlags)
                        condNum(end+1)=find(boolFlags);
                    else
                        warning([this.subData.ID ' did not perform condition ''' condition{i} ''''])
                    end
                end
            else %a numerical vector
                for i=1:length(condition)
                    if length(this.metaData.trialsInCondition)<i || isempty(this.metaData.trialsInCondition(condition(i)))
                        warning([this.subData.ID ' did not perform condition number ' num2str(condition(i))])
                    else
                        condNum(end+1)=condition(i);
                    end
                end
            end
            
            %get data
            trials=cell2mat(this.metaData.trialsInCondition(condNum));
            inds=cell2mat(this.data.indsInTrial(trials));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function figHandle=plotParamTimeCourse(this,label)
            
            if isa(label,'char')
                label={label};
            end
            
            [ah,figHandle]=optimizedSubPlot(length(label),4,1); %this changes default color order of axes
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            nPoints=size(this.data.Data,1);
            for l=1:length(label)
                dataPoints=NaN(nPoints,nConds);
                for i=1:nConds
                    trials=this.metaData.trialsInCondition{conds(i)};
                    if ~isempty(trials)
                        for t=trials
                            inds=this.data.indsInTrial{t};
                            dataPoints(inds,i)=this.getParamInTrial(label(l),t);
                        end
                    end
                end
                plot(ah(l),dataPoints,'.','MarkerSize',15)
                title(ah(l),[label{l},' (',this.subData.ID ')'])
            end
            condDes = this.metaData.conditionName;
            legend(condDes(conds)); %this is for the case when a condition number was skipped
            linkaxes(ah,'x')
            %axis tight
        end
        
        function figHandle=plotParamTrialTimeCourse(this,label)
            
            [ah,figHandle]=optimizedSubPlot(length(label),4,1);            
            
            nTrials=length(cell2mat(this.metaData.trialsInCondition));
            trials=find(~cellfun(@isempty,this.data.trialTypes));
            nPoints=size(this.data.Data,1);
            
            for l=1:length(label)
                dataPoints=NaN(nPoints,nTrials);
                for i=1:nTrials
                    inds=this.data.indsInTrial{trials(i)};
                    dataPoints(inds,i)=this.getParamInTrial(label(l),trials(i));
                end
                plot(ah(l),dataPoints,'.','MarkerSize',15)
                title(ah(l),[label{l},' (',this.subData.ID ')'])
            end
            
            trialNums = cell2mat(this.metaData.trialsInCondition);
            legendEntry={};
            for i=1:length(trialNums)
                legendEntry{end+1}=num2str(trialNums(i));
            end
            legend(legendEntry);
            linkaxes(ah,'x')
            axis tight
        end
        
        function figHandle=plotParamByConditions(this,label)
            
            N1=3; %very early number of points
            N2=5; %early number of points
            N3=20; %late number of points
            
            [ah,figHandle]=optimizedSubPlot(length(label),4,1);           
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            for l=1:length(label)
                earlyPoints=[];
                veryEarlyPoints=[];
                latePoints=[];
                for i=1:nConds
                    aux=this.getParamInCond(label(l),conds(i));
                    try %Try to get the first strides, if there are enough
                        veryEarlyPoints(i,:)=aux(1:N1);
                        earlyPoints(i,:)=aux(1:N2);
                    catch %In case there aren't enough strides, assign NaNs to all
                        veryEarlyPoints(i,:)=NaN;
                        earlyPoints(i,:)=NaN;
                    end
                    %Last 20 steps, excepting the very last 5
                    try
                        latePoints(i,:)=aux(end-N3-4:end-5);
                    catch
                        latePoints(i,:)=NaN;
                    end
                end
                axes(ah(l))
                hold on
                
                bar((1:3:3*nConds)-.25,nanmean(veryEarlyPoints,2),.15,'FaceColor',[.8,.8,.8])
                bar((1:3:3*nConds)+.25,nanmean(earlyPoints,2),.15,'FaceColor',[.6,.6,.6])
                bar(2:3:3*nConds,nanmean(latePoints,2),.3,'FaceColor',[0,.3,.6])
                errorbar((1:3:3*nConds)-.25,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                errorbar((1:3:3*nConds)+.25,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                errorbar(2:3:3*nConds,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                %plot([1:3:3*nConds]-.25,veryEarlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot([1:3:3*nConds]+.25,earlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot(2:3:3*nConds,latePoints,'x','LineWidth',2,'Color',[0,.6,.2])
                xTickPos=(1:3:3*nConds)+.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([label{l},' (',this.subData.ID ')'])
                hold off
            end
            legend('Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'); %this is for the case when a condition number was skipped
        end
        
        function [boolFlag,labelIdx]=isaCondition(this,cond)
            if isa(cond,'char')
                auxCond{1}=cond;
            elseif isa(cond,'cell')
                auxCond=cond;
            elseif isa(cond,'double')
                auxCond=this.metaData.conditionName(cond);
            end
            N=length(auxCond);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                for i=1:length(this.metaData.conditionName)
                    if strcmpi(auxCond{j},this.metaData.conditionName{i})
                        boolFlag(j)=true;
                        labelIdx(j)=i;
                        break;
                    end
                end
            end
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning([this.subData.ID 'did not perform condition ''' cond{i} ''' or the condition is misspelled.'])
                end
            end
        end
        
        function [trials]=getTrialsInCond(this,cond)
            conditions=this.metaData.conditionName(~cellfun('isempty',this.metaData.conditionName));
            trials=this.metaData.trialsInCondition(~cellfun('isempty',this.metaData.conditionName));
            trials=trials{ismember(conditions,cond)==true};
        end
        
    end
    
    
    
    methods(Static)
        function figHandle=plotGroupedSubjects(adaptDataList,label,removeBiasFlag,plotIndividualsFlag)
            
            if nargin<4 || isempty(plotIndividualsFlag)
                plotIndividualsFlag=true;
            end
            
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
            end
            Ngroups=length(auxList);
            
            %UPDATE LEGEND IF THESE LINES ARE CHANGED
            N1=3; %very early number of points
            N2=5; %early number of points
            N3=20; %late number of points
            
            [ah,figHandle]=optimizedSubPlot(length(label),4,1);
            
            load(auxList{1}{1});
            this=adaptData;
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            for l=1:length(label)
                axes(ah(l))
                hold on
                
                for group=1:Ngroups
                    earlyPoints=[];
                    veryEarlyPoints=[];
                    latePoints=[];
                    for subject=1:length(auxList{group}) %Getting data for each subject in the list
                        load(auxList{group}{subject});
                        if nargin<3 || isempty(removeBiasFlag) || removeBiasFlag==1
                            this=adaptData.removeBias; %Default behaviour
                        else
                            this=adaptData;
                        end
                        for i=1:nConds
                            trials=this.metaData.trialsInCondition{conds(i)};
                            if ~isempty(trials)
                                aux=this.getParamInCond(label(l),conds(i));
                                try %Try to get the first strides, if there are enough
                                    veryEarlyPoints(i,subject)=mean(aux(1:N1));
                                    earlyPoints(i,subject)=mean(aux(1:N2));
                                catch %In case there aren't enough strides, assign NaNs to all
                                    veryEarlyPoints(i,subject)=NaN;
                                    earlyPoints(i,subject)=NaN;
                                end
                                
                                %Last 20 steps, excepting the very last 5
                                try                                    
                                    latePoints(i,subject)=mean(aux(end-N3-4:end-5));
                                catch
                                    latePoints(i,subject)=NaN;
                                end
                            else
                                veryEarlyPoints(i,subject)=NaN;
                                earlyPoints(i,subject)=NaN;
                                latePoints(i,subject)=NaN;
                            end
                        end
                    end
                    %plot bars
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        bar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2),.15/Ngroups,'FaceColor',[.85,.85,.85].^group)
                        bar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2),.15/Ngroups,'FaceColor',[.7,.7,.7].^group)
                    else
                        h(2*(group-1)+1)=bar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2),.3/Ngroups,'FaceColor',[.6,.6,.6].^group);
                    end
                    h(2*group)=bar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2),.3/Ngroups,'FaceColor',[0,.4,.7].^group);
                    %plot individual data points
                    if Ngroups==1 || plotIndividualsFlag %Only plotting individual subject performance if there is only one group, or flag is set
                        if Ngroups==1
                            plot((1:3:3*nConds)-.25+(group-1)/Ngroups,veryEarlyPoints,'x','LineWidth',2)
                            plot((1:3:3*nConds)+.25+(group-1)/Ngroups,earlyPoints,'x','LineWidth',2)
                        else
                            plot((1:3:3*nConds)+(group-1)/Ngroups,earlyPoints,'x','LineWidth',2)
                        end
                        plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'x','LineWidth',2)
                    end
                    %plot error bars (using standard error)
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        errorbar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                        errorbar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    else
                        errorbar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    end
                    errorbar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                end
                xTickPos=(1:3:3*nConds)+.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                title([label{l}])
                hold off
            end
            linkaxes(ah,'x')
            axis tight
            condDes = this.metaData.conditionName;
            if Ngroups==1
                legend([{'Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'}, auxList{1} ]);
            else
                legStr={};
                for group=1:Ngroups
                    legStr=[legStr, {['Early (first 5), Group ' num2str(group)],['Late (last 20 (-5)), Group ' num2str(group)]}];
                end
                legend(h,legStr)
            end
        end
        
        %function [avg, indiv]=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,indivFlag,indivSubs)
        function figHandle=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,indivFlag,indivSubs)
            %adaptDataList must be cell array of 'param.mat' file names
            %params is cell array of parameters to plot. List with commas to
            %plot on separate graphs or with semicolons to plot on same graph.
            %conditions is cell array of conditions to plot
            %binwidth is the number of data points to average in time
            %indivFlag - set to true to plot individual subject time courses
            %indivSubs - must be a cell array of 'param.mat' file names that is
            %a subset of those in the adaptDataList. Plots specific subjects
            %instead of all subjects.
            
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
            end
            Ngroups=length(auxList);
            
            %make sure params is a cell array
            if isa(params,'char')
                params={params};
            end
            
            %check condition input
            if nargin>3
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
            
            if nargin>6 && isa(indivSubs,'cell')
                if ~isa(adaptDataList{1},'cell')
                    indivSubs{1}=indivSubs;
                end
            elseif nargin>6 && isa(indivSubs,'char')
                indivSubs{1}={indivSubs};
            end
            
            %Initialize plot
            [ah,figHandle]=optimizedSubPlot(size(params,2),4,1);
            set(ah(1:size(params,2)),'defaultTextFontName', 'Arial')
            legendStr={};
            % Set colors
            %poster_colorsHH;
            poster_colors;
            % Set colors order
            ColorOrder=[p_plum; p_orange; p_fade_green; p_fade_blue; p_red; p_green; p_blue; p_fade_red; p_lime; p_yellow; p_gray; p_black;p_red];

                                          LineOrder={'-','--',':','-.'};
            
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
                        if strcmpi(conditions{c},'adaptation')  || strcmpi(conditions{c},'TM post') %JUST FOR NOW %|| strcmpi(conditions{c},'re-adaptation')
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
                        elseif strcmpi(conditions{c},'re-adaptation')
                            trials=adaptData.getTrialsInCond(conditions{c});
                            t=length(trials);
                                dataPts=adaptData.getParamInTrial(params,trials(t));
                                t=2;%gerrig
                                nPoints=50; %BUGGAR BRAINS
                                numPts.(cond{c}).(['trial' num2str(t)])(s)=nPoints;
                                for p=1:length(params)
                                    %itialize so there are no inconsistant dimensions or out of bounds errors
                                    values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,1000); %this assumes that the max number of data points that could exist in a single condition is 1000
                                    values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts((end-5)-(nPoints)+1:(end-5),p);
                                end
             
                            if min(numPts.(cond{c}).(['trial' num2str(t)]))==0
                                bad=find(numPts.(cond{c}).(['trial' num2str(t)])==0);
                                numPts.(cond{c}).(['trial' num2str(t)])=[];
                            end
                            %~~~~~~~~~~~~
                            %~~~~~~~~~~~~
%                         elseif strcmpi(conditions{c},'re-adaptation')
%                             trials=adaptData.getTrialsInCond(conditions{c});
%                             t=length(trials);
%                             dataPts=adaptData.getParamInTrial(params,trials(t));
%                             nPoints=size(dataPts,1);
%                             if nPoints == 0
%                                 numPts.(cond{c}).(['trial' num2str(t)])(s)=NaN;
%                             else
%                                 numPts.(cond{c}).(['trial' num2str(t)])(s)=nPoints;
%                             end
%                             for p=1:length(params)
%                                 %itialize so there are no inconsistant dimensions or out of bounds errors
%                                 values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,1000); %this assumes that the max number of data points that could exist in a single condition is 1000
%                                 values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
%                             end
%                             %~~~~~~~~~~~~
                        elseif strcmpi(conditions{c},'TM base') || strcmpi(conditions{c},'OG base') 
                            %stepnum=40;% 5/16 -- should be 40 to be consistent with remove bias
                            stepnum=15;
                            trials=adaptData.getTrialsInCond(conditions{c});
                            for t=1:length(trials)
                                dataPts=adaptData.getParamInTrial(params,trials(t));
                                if strcmpi(conditions{c},'TM base')
                                    %dataPts=dataPts(end-5-stepnum+1:end-5, :);% HERE
                                    dataPts=dataPts(end-stepnum+1:end-6, :);% 5/16 -- should be like this to be consistent with remove bias
                                end
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
                            
                        else
                            dataPts=adaptData.getParamInCond(params,conditions{c});
                            nPoints=size(dataPts,1);
                            if nPoints == 0
                                numPts.(cond{c})(s)=NaN;
                            else
                                numPts.(cond{c})(s)=nPoints;
                            end
                            for p=1:length(params)
                                %itialize so there are no inconsistant dimensions or out of bounds errors
                                values(group).(params{p}).(cond{c})(subject,:)=NaN(1,1000); %this assumes that the max number of data points that could exist in a single condition is 1000
                                
                                % %                             %VELOCITY CONTRIBUTION IS FLIPPED HERE!!
                                %                             if strcmp(params{p},'velocityContribution')
                                %                                 values(group).(params{p}).(cond{c})(subject,1:nPoints)=abs(dataPts(:,p));
                                %                             else
                                values(group).(params{p}).(cond{c})(subject,1:nPoints)=dataPts(:,p);
                                %                             end
                            end
                        end                        
                    end
                    s=s+1;
                end    
            end
            %plot the average value of parameter(s) entered over time, across all subjects entered.
            for group=1:Ngroups
                Xstart=1;
                lineX=0;
                subjects=auxList{group};
                for c=1:length(conditions)
                    
%                     if false
                    if strcmpi(conditions{c},'adaptation') || strcmpi(conditions{c},'re-adaptation') || strcmpi(conditions{c},'TM post')  %JUST FOR NOW
                        
                        if strcmpi(conditions{c},'re-adaptation')
                        HereWeGo=[2];
                        numPts.(cond{c}).(['trial' num2str(HereWeGo)])=50; %BUGGAR BRAINS
%                         elseif strcmpi(conditions{c},'TM post')
%                                                     HereWeGo=[3];
                        
                        else
                            HereWeGo=1:length(fields(values(group).(params{p}).(cond{c})));
                        end
                        
                        for t=HereWeGo%t=1:length(fields(values(group).(params{p}).(cond{c})));
                            % 1) find the length of each trial
                            
%                             %to plot the MAX number of pts in each trial:
%                             [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
%                             while maxPts<0.75*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
%                                 numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
%                                 [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
%                             end
%                             if maxPts==0
%                                 continue
%                             end
%                             if strcmpi(conditions{c},'re-adaptation') && t==1%%
%                              maxPts=0;%%
%                             else%%
                            %to plot the MIN number of pts in each condition:
                            %[maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                            [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                            while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                                numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
                                %[maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                               [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                            end
%                             end%%
                            if maxPts==0 
                                continue
                            end
                            
                            for p=1:length(params)
                                
                                allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:maxPts-5); 
                                
                                % 2) average across subjuects within bins
                                
                                %Find (running) averages and standard deviations for bin data
                                start=1:size(allValues,2)-(binwidth-1);
                                stop=start+binwidth-1;
                                %             %Find (simple) averages and standard deviations for bin data
                                %             start = 1:binwidth:(size(allValues,2)-binwidth+1);
                                %             stop = start+(binwidth-1);
                                
                                for i = 1:length(start)
                                    t1 = start(i);
                                    t2 = stop(i);
                                    bin = allValues(:,t1:t2);
                                    
                                    %errors calculated as SE of averaged subject points
                                    subBin=nanmean(bin,2);
                                    avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(subBin);
                                    se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(subBin)/sqrt(length(subBin));
                                    indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=subBin;
                                    
                                    %                           %errors calculated as SE of all data
                                    %                           %points (before indiv subjects are averaged)
                                    %                           avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
                                    %                           se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
                                    %                           indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                                end
                                Smooth(group).(params{p}).(cond{c}).(['trial' num2str(t)])=bin_data_Variable(mean(allValues)',3, 20)';
                                %%% CJS here is where I am taking the adaptation timecourse to fit
                                % 3) plot data
                                if size(params,1)>1
                                    axes(ah)
                                    g=p;
                                    Cdiv=group;
                                    if Ngroups==1
                                        legStr=[params{p} num2str(t)];
                                    else
                                        legStr={[params{p} num2str(t) ' group ' num2str(group)]};
                                    end
                                else
                                    axes(ah(p))
                                    g=group;
                                    Cdiv=1;
                                end
                                hold on
                                if strcmpi(conditions{c},'TM post') || strcmpi(conditions{c},'re-adaptation')
                                    y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])];
                                    E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)])];
                                else
                                    y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
                                    E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
                                end
                                condLength=length(y);
                                x=Xstart:Xstart+condLength-1;
                                
                                if nargin>4 && ~isempty(indivFlag) && indivFlag
                                    if nargin>5 && ~isempty(indivSubs)
                                        subsToPlot=indivSubs{group};
                                    else
                                        subsToPlot=subjects;
                                        
                                    end
                                    
                                    for s=1:length(subsToPlot)
                                        subInd=find(ismember(subjects,subsToPlot{s}));
                                        %to plot as dots
                                        %Li{group}(s)= plot(x,indiv.(['cond' num2str(cond)])(subInd,:),'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                                        Li{group}(s)=plot(x,[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:) nan(1,10)],'.','MarkerSize',10, 'color',ColorOrder(subInd,:));
                                        %to plot as lines
                                        %Li{group}(s)=plot(x,[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:) nan(1,10)],LineOrder{group},'color',ColorOrder(subInd,:));
                                        legendStr{group}=subsToPlot;
                                    end
                                    plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group)
                                else
                                    if Ngroups==1 && ~(size(params,1)>1)
                                        %[Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);
                                        [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        %CJS STOP HERE TO GET THE
                                        %ADAPTATION TIME COURSES!!!!
                                        set(Li{c},'Clipping','off')
                                        H=get(Li{c},'Parent');
                                        %legendStr={conditions};
%                                     elseif size(params,1)>1
%                                         [Pa, Li{(group-1)*size(params,1)+p}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
%                                         set(Li{(group-1)*size(params,1)+p},'Clipping','off')
%                                         H=get(Li{(group-1)*size(params,1)+p},'Parent');
%                                         %legendStr{(group-1)*size(params,1)+p}=legStr;
                                    else
                                        [Pa, Li{g}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        set(Li{g},'Clipping','off')
                                        H=get(Li{g},'Parent');
                                        %legendStr{g}={['group' num2str(g)]};
                                    end
                                    set(Pa,'Clipping','off')
                                    set(H,'Layer','top')
                                end
                                
% %                                 %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%  if strcmp(cond{c}, 'adaptation')==1
%                                     trill=adaptData.getTrialsInCond(conditions{c});
%                                     t1length=nanmin(numPts.(cond{c}).(['trial1']))-9;
%                                     t2length=nanmin(numPts.(cond{c}).(['trial2']))+t1length-9;
%                                     t3length=nanmin(numPts.(cond{c}).(['trial3']))+t2length-9;
%                                     t4length=nanmin(numPts.(cond{c}).(['trial4']))+t3length-9;
%                                     xx=[0:1:t4length];
% 
%                                     So1=-.174*exp((-1/174.8)*xx)+.1453; So1=[So1(1:t1length) nan(1, 10) So1(t1length+1:t2length) nan(1, 10) So1(t2length+1:t3length) nan(1, 10) So1(t3length+1:t4length) nan(1, 10)];
%                                     Sy1=-.1106*exp((-1/119)*xx)+.1629; Sy1=[Sy1(1:t1length) nan(1, 10) Sy1(t1length+1:t2length) nan(1, 10) Sy1(t2length+1:t3length) nan(1, 10) Sy1(t3length+1:t4length) nan(1, 10)];
% % %                                     So2=-.1269*exp((-1/93.9)*xx)+.1072; So2=[So2(1:t1length) nan(1, 10) So2(t1length+1:t2length) nan(1, 10) So2(t2length+1:t3length) nan(1, 10) So2(t3length+1:t4length) nan(1, 10)];
% % %                                     Sy2=-.06922*exp((-1/154)*xx)+.1851; Sy2=[Sy2(1:t1length) nan(1, 10) Sy2(t1length+1:t2length) nan(1, 10) Sy2(t2length+1:t3length) nan(1, 10) Sy2(t3length+1:t4length) nan(1, 10)];
%                                     So2=-.09925*exp((-1/265.6)*xx) -.1047*exp((-1/16.47)*xx)+0.1329; So2=[So2(1:t1length) nan(1, 10) So2(t1length+1:t2length) nan(1, 10) So2(t2length+1:t3length) nan(1, 10) So2(t3length+1:t4length) nan(1, 10)];
%                                     Sy2=-.1206*exp((-1/832.6)*xx) -.08836*exp((-1/8.143)*xx)+0.2577; Sy2=[Sy2(1:t1length) nan(1, 10) Sy2(t1length+1:t2length) nan(1, 10) Sy2(t2length+1:t3length) nan(1, 10) Sy2(t3length+1:t4length) nan(1, 10)];%                                     
% % 
% % 
%                                     No1=-.18*exp((-1/158)*xx)+-.03868; No1=[No1(1:t1length) nan(1, 10) No1(t1length+1:t2length) nan(1, 10) No1(t2length+1:t3length) nan(1, 10) No1(t3length+1:t4length) nan(1, 10)];
%                                     Ny1=-.1579*exp((-1/115.5)*xx)+-.01303; Ny1=[Ny1(1:t1length) nan(1, 10) Ny1(t1length+1:t2length) nan(1, 10) Ny1(t2length+1:t3length) nan(1, 10) Ny1(t3length+1:t4length) nan(1, 10)];
% % %                                     No2=-.1522*exp((-1/100.9)*xx)+-.06637; No2=[No2(1:t1length) nan(1, 10) No2(t1length+1:t2length) nan(1, 10) No2(t2length+1:t3length) nan(1, 10) No2(t3length+1:t4length) nan(1, 10)];
% % %                                     Ny2=-.1109*exp((-1/143.9)*xx)+-.0009004; Ny2=[Ny2(1:t1length) nan(1, 10) Ny2(t1length+1:t2length) nan(1, 10) Ny2(t2length+1:t3length) nan(1, 10) Ny2(t3length+1:t4length) nan(1, 10)];
%                                     No2=-.1341*exp((-1/342.8)*xx) -.1279*exp((-1/16.79)*xx)-0.02015; No2=[No2(1:t1length) nan(1, 10) No2(t1length+1:t2length) nan(1, 10) No2(t2length+1:t3length) nan(1, 10) No2(t3length+1:t4length) nan(1, 10)];
%                                     Ny2=-.1115*exp((-1/299.9)*xx) -.1019*exp((-1/7.717)*xx)+0.02497; Ny2=[Ny2(1:t1length) nan(1, 10) Ny2(t1length+1:t2length) nan(1, 10) Ny2(t2length+1:t3length) nan(1, 10) Ny2(t3length+1:t4length) nan(1, 10)];
% %                                     
% %                                     %One exponential
%                                     To1=-.03475*exp((-1/25.61)*xx)+.06971; To1=[To1(1:t1length) nan(1, 10) To1(t1length+1:t2length) nan(1, 10) To1(t2length+1:t3length) nan(1, 10) To1(t3length+1:t4length) nan(1, 10)];
%                                     Ty1=-.03562*exp((-1/19.99)*xx)+.0746; Ty1=[Ty1(1:t1length) nan(1, 10) Ty1(t1length+1:t2length) nan(1, 10) Ty1(t2length+1:t3length) nan(1, 10) Ty1(t3length+1:t4length) nan(1, 10)];
% % %                                     To2=-.01481*exp((-1/125)*xx)+.07945;  To2=[To2(1:t1length) nan(1, 10) To2(t1length+1:t2length) nan(1, 10) To2(t2length+1:t3length) nan(1, 10) To2(t3length+1:t4length) nan(1, 10)];
% % %                                     Ty2=-.02565*exp((-1/273.9)*xx)+.07743;  Ty2=[Ty2(1:t1length) nan(1, 10) Ty2(t1length+1:t2length) nan(1, 10) Ty2(t2length+1:t3length) nan(1, 10) Ty2(t3length+1:t4length) nan(1, 10)];
%                                     
%                                         %Two Exponentials
% % %                                     To12=-1.131*exp((-1/4.153e+04)*xx) -0.03502*exp((-1/11.91)*xx)+ 1.194;%-5.368*exp((-1/2.886*10^5)*x)-.03176*exp((-1/19.07)*x)+5.433;
% % %                                     Ty12=-0.01381*exp((-1/197.7)*xx)-0.03508 *exp((-1/7.876)*xx)+0.07921;%-.01376*exp((-1/184.2)*x)-.03497*exp((-1/7.704)*x)+0.0789;
% %                                     To22=-0.2667 *exp((-1/1.153e+04)*xx) -0.02204*exp((-1/8.556)*xx)+0.3375;%-.7779*exp((-1/4.118*10^4)*x)-.02095*exp((-1/11.04)*x)+0.8496;
%                                     Ty22=-0.03076*exp((-1/459.5)*xx)-0.01776*exp((-1/4.102)*xx)+0.08465;%-.03091*exp((-1/464.5)*x)-.01753*exp((-1/4.243)*x)+0.8484;
%                                     %%% Binwidth 50 %%% To22= -0.8768*exp((-1/4.258e+04)*xx)+-0.005297*exp((-1/12.39)*xx)+0.9489;  To22=[To22(1:t1length) nan(1, 10) To22(t1length+1:t2length) nan(1, 10) To22(t2length+1:t3length) nan(1, 10) To22(t3length+1:t4length) nan(1, 10)];
% %                                   
% %                                     To12=[To12(1:t1length) nan(1, 10) To12(t1length+1:t2length) nan(1, 10) To12(t2length+1:t3length) nan(1, 10) To12(t3length+1:t4length) nan(1, 10)];
% %                                     Ty12=[Ty12(1:t1length) nan(1, 10) Ty12(t1length+1:t2length) nan(1, 10) Ty12(t2length+1:t3length) nan(1, 10) Ty12(t3length+1:t4length) nan(1, 10)];
%                                     To22=[To22(1:t1length) nan(1, 10) To22(t1length+1:t2length) nan(1, 10) To22(t2length+1:t3length) nan(1, 10) To22(t3length+1:t4length) nan(1, 10)];
%                                     Ty22=[Ty22(1:t1length) nan(1, 10) Ty22(t1length+1:t2length) nan(1, 10) Ty22(t2length+1:t3length) nan(1, 10) Ty22(t3length+1:t4length) nan(1, 10)];
% %                                     
% % %                                     So1=-.174*exp((-1/174.8)*xx)+.1453; So1=[So1(1:138) nan(1, 10) So1(139:193) nan(1, 10) So1(194:314) nan(1, 10) So1(315:433) nan(1, 10)];
% % %                                     Sy1=-.1106*exp((-1/119)*xx)+.1629; Sy1=[Sy1(1:138) nan(1, 10) Sy1(139:193) nan(1, 10) Sy1(194:314) nan(1, 10) Sy1(315:433) nan(1, 10)];
% % %                                     So2=-.1269*exp((-1/93.9)*xx)+.1072; So2=[So2(1:138) nan(1, 10) So2(139:193) nan(1, 10) So2(194:314) nan(1, 10) So2(315:433) nan(1, 10)];
% % %                                     Sy2=-.06922*exp((-1/154)*xx)+.1851; Sy2=[Sy2(1:138) nan(1, 10) Sy2(139:193) nan(1, 10) Sy2(194:314) nan(1, 10) Sy2(315:433) nan(1, 10)];
% % %                                     
% % %                                     No1=-.18*exp((-1/158)*xx)+-.03868; No1=[No1(1:138) nan(1, 10) No1(139:193) nan(1, 10) No1(194:314) nan(1, 10) No1(315:433) nan(1, 10)];
% % %                                     Ny1=-.1579*exp((-1/115.5)*xx)+-.01303; Ny1=[Ny1(1:138) nan(1, 10) Ny1(139:193) nan(1, 10) Ny1(194:314) nan(1, 10) Ny1(315:433) nan(1, 10)];
% % %                                     No2=-.1522*exp((-1/100.9)*xx)+-.06637; No2=[No2(1:138) nan(1, 10) No2(139:193) nan(1, 10) No2(194:314) nan(1, 10) No2(315:433) nan(1, 10)];
% % %                                     Ny2=-.1109*exp((-1/143.9)*xx)+-.0009004; Ny2=[Ny2(1:138) nan(1, 10) Ny2(139:193) nan(1, 10) Ny2(194:314) nan(1, 10) Ny2(315:433) nan(1, 10)];
% % %                                     
% % %                                     %One exponential
% % %                                     To1=-.03475*exp((-1/25.61)*xx)+.06971; To1=[To1(1:138) nan(1, 10) To1(139:193) nan(1, 10) To1(194:314) nan(1, 10) To1(315:433) nan(1, 10)];
% % %                                     Ty1=-.03562*exp((-1/19.99)*xx)+.0746; Ty1=[Ty1(1:138) nan(1, 10) Ty1(139:193) nan(1, 10) Ty1(194:314) nan(1, 10) Ty1(315:433) nan(1, 10)];
% % %                                     To2=-.01481*exp((-1/125)*xx)+.07945;  To2=[To2(1:138) nan(1, 10) To2(139:193) nan(1, 10) To2(194:314) nan(1, 10) To2(315:433) nan(1, 10)];
% % %                                     Ty2=-.02565*exp((-1/273.9)*xx)+.07743;  Ty2=[Ty2(1:138) nan(1, 10) Ty2(139:193) nan(1, 10) Ty2(194:314) nan(1, 10) Ty2(315:433) nan(1, 10)];
% % %                                     
% % %                                     %Two Exponentials
% % %                                     To12=-1.131*exp((-1/4.153e+04)*xx) -0.03502*exp((-1/11.91)*xx)+ 1.194;%-5.368*exp((-1/2.886*10^5)*x)-.03176*exp((-1/19.07)*x)+5.433;
% % %                                     Ty12=-0.01381*exp((-1/197.7)*xx)-0.03508 *exp((-1/7.876)*xx)+0.07921;%-.01376*exp((-1/184.2)*x)-.03497*exp((-1/7.704)*x)+0.0789;
% % %                                     To22=-0.2667 *exp((-1/1.153e+04)*xx) -0.02204*exp((-1/8.556)*xx)+0.3375;%-.7779*exp((-1/4.118*10^4)*x)-.02095*exp((-1/11.04)*x)+0.8496;
% % %                                     Ty22=-0.03076*exp((-1/459.5)*xx)-0.01776*exp((-1/4.102)*xx)+0.08465;%-.03091*exp((-1/464.5)*x)-.01753*exp((-1/4.243)*x)+0.8484;
% % %                                     
% % %                                     To12=[To12(1:138) nan(1, 10) To12(139:193) nan(1, 10) To12(194:314) nan(1, 10) To12(315:433) nan(1, 10)];
% % %                                     Ty12=[Ty12(1:138) nan(1, 10) Ty12(139:193) nan(1, 10) Ty12(194:314) nan(1, 10) Ty12(315:433) nan(1, 10)];
% % %                                     To22=[To22(1:138) nan(1, 10) To22(139:193) nan(1, 10) To22(194:314) nan(1, 10) To22(315:433) nan(1, 10)];
% % %                                     Ty22=[Ty22(1:138) nan(1, 10) Ty22(139:193) nan(1, 10) Ty22(194:314) nan(1, 10) Ty22(315:433) nan(1, 10)];
% %                                     
%                                     if strcmp(subjects{1}(1:4),'OG10')==1% old, Day 1
%                                         legendStr{g}={['group OA Day 1']};
%                                         if strcmp(params{p}, 'spatialContribution')==1
%                                             plot(x, So1(x(1):x(end)), 'Color', ColorOrder(5,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'netContribution')==1
%                                             plot(x, No1(x(1):x(end)), 'Color', ColorOrder(5,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'stepTimeContribution')==1
%                                             plot(x, To1(x(1):x(end)), 'Color', ColorOrder(5,:), 'LineWidth', 3)
%                                             %plot(x, To12(x(1):x(end)), 'Color', ColorOrder(g,:), 'LineWidth', 5)
%                                         end
%                                     elseif strcmp(subjects{1}(1:4),'OG20')% youg , Day 1
%                                         legendStr{g}={['group YA Day 1']};
%                                         if strcmp(params{p}, 'spatialContribution')==1
%                                             plot(x, Sy1(x(1):x(end)), 'Color', ColorOrder(6,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'netContribution')==1
%                                             plot(x, Ny1(x(1):x(end)), 'Color', ColorOrder(6,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'stepTimeContribution')==1
%                                             plot(x, Ty1(x(1):x(end)), 'Color', ColorOrder(6,:), 'LineWidth', 3)
%                                             %plot(x, Ty12(x(1):x(end)), 'Color', ColorOrder(g,:), 'LineWidth', 5)
%                                         end
%                                     elseif strcmp(subjects{1}(1:5),'OG210')% old, day 2
%                                         legendStr{g}={['group OA Day 2']};
%                                         if strcmp(params{p}, 'spatialContribution')==1
%                                             plot(x, So2(x(1):x(end)), 'Color', ColorOrder(10,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'netContribution')==1
%                                             plot(x, No2(x(1):x(end)), 'Color', ColorOrder(10,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'stepTimeContribution')==1
%                                             %plot(x, To2(x(1):x(end)), 'Color', ColorOrder(g,:), 'LineWidth', 5)
%                                             plot(x, To22(x(1):x(end)), 'Color', ColorOrder(10,:), 'LineWidth', 3)
%                                         end
%                                     elseif strcmp(subjects{1}(1:5),'OG221')% youg , Day 2
%                                         legendStr{g}={['group YA Day 2']};
%                                         if strcmp(params{p}, 'spatialContribution')==1
%                                             plot(x, Sy2(x(1):x(end)), 'Color', ColorOrder(7,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'netContribution')==1
%                                             plot(x, Ny2(x(1):x(end)), 'Color', ColorOrder(7,:), 'LineWidth', 3)
%                                         elseif strcmp(params{p}, 'stepTimeContribution')==1
%                                             %plot(x, Ty2(x(1):x(end)), 'Color', ColorOrder(g,:), 'LineWidth', 5)
%                                             plot(x, Ty22(x(1):x(end)), 'Color', ColorOrder(7,:), 'LineWidth', 3)
%                                         end
%                                     end
%                                 end
% % %                                 %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                h=refline(0,0);
                                set(h,'color','k')                        
                                hold off
                            end                            
                            Xstart=Xstart+condLength;                            
                        end              
                        for p=1:length(params)
                            if c==length(conditions) && group==Ngroups
                                %on last iteration of conditions loop, add title and
                                %vertical lines to seperate conditions
                                if ~(size(params,1)>1)
                                    axes(ah(p))
                                    title(params{p},'fontsize',12)                                    
                                else
                                    axes(ah)
                                end
                                axis tight
                                line([lineX; lineX],ylim,'color','k')
                                xticks=lineX+diff([lineX Xstart])./2;
                                set(gca,'fontsize',8,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', conditions)
                            end                           
                        end
                        lineX(end+1)=Xstart-0.5;
                        %~~~~~~~~~
                    elseif strcmpi(conditions{c},'TM base') %|| strcmpi(conditions{c},'OG base') %?
                                   
                                   if strcmp(subjects{1}(1:4),'OG10')==1% old, Day 1
                                        legendStr{group}={['group OA Day 1']};
                                    elseif strcmp(subjects{1}(1:4),'OG20')% youg , Day 1
                                        legendStr{group}={['group YA Day 1']};
                                    elseif strcmp(subjects{1}(1:5),'OG210')% old, day 2
                                        legendStr{group}={['group OA Day 2']};
                                    elseif strcmp(subjects{1}(1:5),'OG221')% youg , Day 2
                                        legendStr{group}={['group YA Day 2']};
                                   end
                        
                        for t=1:length(fields(values(group).(params{p}).(cond{c})));
                            % 1) find the length of each trial
                            
%                             %to plot the MAX number of pts in each trial:
%                             [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
%                             while maxPts<0.75*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
%                                 numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
%                                 [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
%                             end
%                             if maxPts==0
%                                 continue
%                             end
                            
                            %to plot the MIN number of pts in each condition:
                            [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                            %[maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                            while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                                numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
                                %[maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                               [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                            end
                            if maxPts==0
                                continue
                            end
                            
                            for p=1:length(params)
                                
                                %allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:maxPts-5);
                                if maxPts<20 %new 04/2015
                                allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:20);
                                else
                                    allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:maxPts);
                                end
                                % 2) average across subjuects within bins
                                
                                %Find (running) averages and standard deviations for bin data
                                start=1:size(allValues,2)-(binwidth-1);
                                stop=start+binwidth-1;
                                %             %Find (simple) averages and standard deviations for bin data
                                %             start = 1:binwidth:(size(allValues,2)-binwidth+1);
                                %             stop = start+(binwidth-1);
                                
                                for i = 1:length(start)
                                    t1 = start(i);
                                    t2 = stop(i);
                                    bin = allValues(:,t1:t2);
                                    
                                    %errors calculated as SE of averaged subject points
                                    subBin=nanmean(bin,2);
                                    avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(subBin);
                                    se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(subBin)/sqrt(length(subBin));
                                    indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=subBin;
                                    
                                    %                           %errors calculated as SE of all data
                                    %                           %points (before indiv subjects are averaged)
                                    %                           avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
                                    %                           se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
                                    %                           indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                                end
                                
                                % 3) plot data
                                if size(params,1)>1
                                    axes(ah)
                                    g=p;
                                    Cdiv=group;
                                    if Ngroups==1
                                        legStr=[params{p} num2str(t)];
                                    else
                                        legStr={[params{p} num2str(t) ' group ' num2str(group)]};
                                    end
                                else
                                    axes(ah(p))
                                    g=group;
                                    Cdiv=1;
                                end
                                hold on
                                y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
                                E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
                                condLength=length(y);
                                x=Xstart:Xstart+condLength-1;
                                
                                if nargin>4 && ~isempty(indivFlag) && indivFlag
                                    if nargin>5 && ~isempty(indivSubs)
                                        subsToPlot=indivSubs{group};
                                    else
                                        subsToPlot=subjects;
                                        
                                    end
                                    
                                    for s=1:length(subsToPlot)
                                        subInd=find(ismember(subjects,subsToPlot{s}));
                                        %to plot as dots
                                        % plot(x,indiv.(['cond' num2str(cond)])(subInd,:),'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                                        %to plot as lines
                                        Li{group}(s)=plot(x,[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:) nan(1,10)],LineOrder{group},'color',ColorOrder(subInd,:));
                                        %legendStr{group}=subsToPlot;
                                    end
                                    plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group)
                                else
                                    if Ngroups==1 && ~(size(params,1)>1)
                                        [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);
                                        set(Li{c},'Clipping','off')
                                        H=get(Li{c},'Parent');
                                        %legendStr={conditions};
                                    elseif size(params,1)>1
                                        [Pa, Li{(group-1)*size(params,1)+p}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        set(Li{(group-1)*size(params,1)+p},'Clipping','off')
                                        H=get(Li{(group-1)*size(params,1)+p},'Parent');
                                        %legendStr{(group-1)*size(params,1)+p}=legStr;
                                    else
                                        [Pa, Li{g}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        set(Li{g},'Clipping','off')
                                        H=get(Li{g},'Parent');
                                        %legendStr{g}={['group' num2str(g)]};
                                    end
                                    set(Pa,'Clipping','off')
                                    set(H,'Layer','top')
                                end
                            end%
                            Xstart=Xstart+condLength;
                        end%
                        for p=1:length(params)
                            if c==length(conditions) && group==Ngroups
                                %on last iteration of conditions loop, add title and
                                %vertical lines to seperate conditions
                                if ~(size(params,1)>1)
                                    axes(ah(p))
                                    title(params{p},'fontsize',12)                                    
                                else
                                    axes(ah)
                                end
                                axis tight
                                line([lineX; lineX],ylim,'color','k')
                                xticks=lineX+diff([lineX Xstart])./2;
                                set(gca,'fontsize',8,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', conditions)
                            end                           
                        end
                        lineX(end+1)=Xstart-0.5;
                    %~~~~~~~~~%
                    elseif   strcmpi(conditions{c},'OG post') || strcmpi(conditions{c},'OG base')
                                   
                                   if strcmp(subjects{1}(1:4),'OG10')==1% old, Day 1
                                        legendStr{group}={['group OA Day 1']};
                                    elseif strcmp(subjects{1}(1:4),'OG20')% youg , Day 1
                                        legendStr{group}={['group YA Day 1']};
                                    elseif strcmp(subjects{1}(1:5),'OG210')% old, day 2
                                        legendStr{group}={['group OA Day 2']};
                                    elseif strcmp(subjects{1}(1:5),'OG221')% youg , Day 2
                                        legendStr{group}={['group YA Day 2']};
                                   end
                        allpts=[];           
                        %Need to concatinate all the OG trials
                        if isstruct(numPts.(cond{c}))==1
                            for t=1:length(fields(values(group).(params{p}).(cond{c})));%6
                                if size(allpts,2)>size(numPts.(cond{c}).(['trial' num2str(t)]), 2)
                                  allpts=[allpts; numPts.(cond{c}).(['trial' num2str(t)]) NaN(1, size(allpts,2)-size(numPts.(cond{c}).(['trial' num2str(t)]), 2))];  
                                else
                                allpts=[allpts; numPts.(cond{c}).(['trial' num2str(t)])];
                                end
                            end
                        else
                            allpts=numPts.(cond{c});
                        end
                        allpts(find(allpts==0))=NaN;
                            %to plot the MIN number of pts in each condition:
                            [maxPts,loc]=nanmin(allpts);
%                             while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
%                                 numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
%                                 %[maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
%                                [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
%                             end
                            if maxPts==0
                                continue
                            end
                            
                            for p=1:length(params)
                                
                                allValues=[];
                                if isstruct(values(group).(params{p}).(cond{c}))==1
                                    for t=1:length(fields(values(group).(params{p}).(cond{c})));%6
                                        allValues=[allValues; values(group).(params{p}).(cond{c}).(['trial' num2str(t)])];
                                    end
                                else
                                    allValues=[ values(group).(params{p}).(cond{c})];
                                end
                                maxPts=min(maxPts);%CJS new idk if it is good?
                                if strcmpi(conditions{c},'OG post')
                                allValues=allValues(:,1:maxPts-5);
                                elseif maxPts<=19
                                    allValues=allValues(:,1:maxPts);
                                else
                                allValues=allValues(:,maxPts-19:maxPts);
                                end
                                
                                % 2) average across subjuects within bins
                                
                                %Find (running) averages and standard deviations for bin data
                                if (binwidth-1)>=size(allValues,2)%New 09/2015
                                 start=1:size(allValues,2);
                                stop=[size(allValues,2).*ones(1, size(allValues,2))];
                                else %old way
                                start=1:size(allValues,2)-(binwidth-1);
                                stop=start+binwidth-1;
                                end
                                %             %Find (simple) averages and standard deviations for bin data
                                %             start = 1:binwidth:(size(allValues,2)-binwidth+1);
                                %             stop = start+(binwidth-1);
                                
                                for i = 1:length(start)
                                    t1 = start(i);
                                    t2 = stop(i);
                                    bin = allValues(:,t1:t2);
                                    
                                    %errors calculated as SE of averaged subject points
                                    subBin=nanmean(bin,2);
                                    avg(group).(params{p}).(cond{c})(i)=nanmean(subBin);
                                    se(group).(params{p}).(cond{c})(i)=nanstd(subBin)/sqrt(length(subBin));
                                    indiv(group).(params{p}).(cond{c})(:,i)=subBin;
% %                                     
%                                     avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(subBin);
%                                     se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(subBin)/sqrt(length(subBin));
%                                     indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=subBin;
%                                     
                                                                        

                                    %                           %errors calculated as SE of all data
                                    %                           %points (before indiv subjects are averaged)
                                    %                           avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
                                    %                           se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
                                    %                           indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                                end
                                
                                % 3) plot data
                                if size(params,1)>1
                                    axes(ah)
                                    g=p;
                                    Cdiv=group;
                                    if Ngroups==1
                                        legStr=[params{p} num2str(t)];
                                    else
                                        legStr={[params{p} num2str(t) ' group ' num2str(group)]};
                                    end
                                else
                                    axes(ah(p))
                                    g=group;
                                    Cdiv=1;
                                end
                                hold on
                                if strcmpi(conditions{c},'OG post')
                                    y=[avg(group).(params{p}).(cond{c})];
                                    E=[se(group).(params{p}).(cond{c})];
                                else
                                    y=[avg(group).(params{p}).(cond{c}) NaN(1,10)];
                                    E=[se(group).(params{p}).(cond{c}) NaN(1,10)];
                                end
                                %
                                condLength=length(y);
                                x=Xstart:Xstart+condLength-1;
                                
                                if nargin>4 && ~isempty(indivFlag) && indivFlag
                                    if nargin>5 && ~isempty(indivSubs)
                                        subsToPlot=indivSubs{group};
                                    else
                                        subsToPlot=subjects;
                                        
                                    end
                                    
                                    for s=1:length(subsToPlot)
                                        subInd=find(ismember(subjects,subsToPlot{s}));
                                        %to plot as dots
                                        % plot(x,indiv.(['cond' num2str(cond)])(subInd,:),'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                                        %to plot as lines
                                        
                                        %THis is what used to be here
                                        %Li{group}(s)=plot(x,[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:) nan(1,10)],LineOrder{group},'color',ColorOrder(subInd,:));
                                        
                                        %This is what I put here so that I
                                        %could plot mulitple subjects
                                        if c==1
                                        Li{group}(s)=plot(x,[indiv.(params{p}).(cond{c})(subInd,:) nan(1,10)],LineOrder{group},'color',ColorOrder(subInd,:));
                                        %Li{group}(s)=plot(x,[indiv.(params{p}).(cond{c})(subInd,:) nan(1,10)],'.','MarkerSize',10, 'color',ColorOrder(subInd,:));
                                        %Li{group}(s)=plot(x,[indiv.(params{p}).(cond{c})(subInd,:) ],'.','MarkerSize',10, 'color',ColorOrder(subInd,:));
                                        elseif c==2
                                        %Li{group}(s)=plot(x,[indiv.(params{p}).(cond{c})(subInd,1:end-10) nan(1,10)],LineOrder{group},'color',ColorOrder(subInd,:));
                                        Li{group}(s)=plot(x,[indiv.(params{p}).(cond{c})(subInd,1:end-10) nan(1,10)],'.','MarkerSize',10, 'color',ColorOrder(subInd,:));
                                        end
                                        legendStr{group}=subsToPlot;
                                    end
                                    plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group)
                                else
                                    if Ngroups==1 && ~(size(params,1)>1)
                                        [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);
                                        set(Li{c},'Clipping','off')
                                        H=get(Li{c},'Parent');
                                        %legendStr={conditions};
                                    elseif size(params,1)>1
                                        [Pa, Li{(group-1)*size(params,1)+p}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        set(Li{(group-1)*size(params,1)+p},'Clipping','off')
                                        H=get(Li{(group-1)*size(params,1)+p},'Parent');
                                        %legendStr{(group-1)*size(params,1)+p}=legStr;
                                    else
                                        [Pa, Li{g}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                        set(Li{g},'Clipping','off')
                                        H=get(Li{g},'Parent');
                                        legendStr{g}={['group' num2str(g)]};
                                    end
                                    set(Pa,'Clipping','off')
                                    set(H,'Layer','top')
                                end
                            h=refline(0,0);
                            set(h,'color','k')
                            end%
                            Xstart=Xstart+condLength;

                        %end%
                        for p=1:length(params)
                            if c==length(conditions) && group==Ngroups
                                %on last iteration of conditions loop, add title and
                                %vertical lines to seperate conditions
                                if ~(size(params,1)>1)
                                    axes(ah(p))
                                    title(params{p},'fontsize',12)                                    
                                else
                                    axes(ah)
                                end
                                axis tight
                                line([lineX; lineX],ylim,'color','k')
                                xticks=lineX+diff([lineX Xstart])./2;
                                set(gca,'fontsize',8,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', conditions)
                            end                           
                        end
                        lineX(end+1)=Xstart-0.5;
                    %~~~~~~~~~%
                    else
                        % 1) find the length of each condition
                        
                        %to plot the min number of pts in each condition:
                        [maxPts,loc]=nanmin(numPts.(cond{c}));
                        while maxPts<0.75*nanmin(numPts.(cond{c})([1:loc-1 loc+1:end]))
                            numPts.(cond{c})(loc)=nanmean(numPts.(cond{c})([1:loc-1 loc+1:end])); %do not include min in mean
                            [maxPts,loc]=nanmin(numPts.(cond{c}));
                        end
%                         
%                         %to plot the max number of pts in each condition:
%                         [maxPts,loc]=nanmax(numPts.(cond{c}));
%                         while maxPts>1.25*nanmax(numPts.(cond{c})([1:loc-1 loc+1:end]))
%                             numPts.(cond{c})(loc)=nanmean(numPts.(cond{c})([1:loc-1 loc+1:end])); %do not include min in mean
%                             [maxPts,loc]=nanmax(numPts.(cond{c}));
%                         end
                        
                        for p=1:length(params)
                            
                            allValues=values(group).(params{p}).(cond{c})(:,1:maxPts);
                            
                            % 2) average across subjuects within bins
                            
                            %Find (running) averages and standard deviations for bin data
                            start=1:size(allValues,2)-(binwidth-1);
                            stop=start+binwidth-1;
                            %             %Find (simple) averages and standard deviations for bin data
                            %             start = 1:binwidth:(size(allValues,2)-binwidth+1);
                            %             stop = start+(binwidth-1);
                            
                            for i = 1:length(start)
                                t1 = start(i);
                                t2 = stop(i);
                                bin = allValues(:,t1:t2);
                                
                                %errors calculated as SE of averaged subject points
                                subBin=nanmean(bin,2);
                                avg(group).(params{p}).(cond{c})(i)=nanmean(subBin);
                                se(group).(params{p}).(cond{c})(i)=nanstd(subBin)/sqrt(length(subBin));
                                indiv(group).(params{p}).(cond{c})(:,i)=subBin;
                                
                                %                           %errors calculated as SE of all data
                                %                           %points (before indiv subjects are averaged)
                                %                           avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
                                %                           se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
                                %                           indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                            end
                            
                            % 3) plot data
                            if size(params,1)>1
                                axes(ah)
                                g=p;
                                Cdiv=group;
                                if Ngroups==1
                                    legStr=params(p);
                                else
                                    legStr={[params{p} num2str(group)]};
                                end
                            else
                                axes(ah(p))
                                g=group;
                                Cdiv=1;
                            end
                            hold on
%                             y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
%                             E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)]) NaN(1,10)];
                            y=avg(group).(params{p}).(cond{c});
                            E=se(group).(params{p}).(cond{c});
                            condLength=length(y);
                            x=Xstart:Xstart+condLength-1;
                            
                            if nargin>4 && ~isempty(indivFlag) && indivFlag
                                if nargin>5 && ~isempty(indivSubs)
                                    subsToPlot=indivSubs{group};
                                else
                                    subsToPlot=subjects;
                                end
                                for s=1:length(subsToPlot)
                                    subInd=find(ismember(subjects,subsToPlot{s}));
                                    %to plot as dots
                                    % plot(x,indiv.(['cond' num2str(cond)])(subInd,:),'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                                    %to plot as lines
                                    Li{group}(s)=plot(x,indiv(group).(params{p}).(cond{c})(subInd,:),LineOrder{group},'color',ColorOrder(subInd,:));
                                    %legendStr{group}=subsToPlot;
                                end
                                plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group)
                            else
                                if Ngroups==1 && ~(size(params,1)>1)
                                    [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);
                                    set(Li{c},'Clipping','off')
                                    H=get(Li{c},'Parent');
                                    %legendStr={conditions};
                                elseif size(params,1)>1
                                    [Pa, Li{(group-1)*size(params,1)+p}]=nanJackKnife(x,y,E,ColorOrder(g,:)./Cdiv,ColorOrder(g,:)./Cdiv+0.5.*abs(ColorOrder(g,:)./Cdiv-1),0.7);
                                    set(Li{(group-1)*size(params,1)+p},'Clipping','off')
                                    H=get(Li{(group-1)*size(params,1)+p},'Parent');
                                    %legendStr{(group-1)*size(params,1)+p}=legStr;
                                else
                                    [Pa, Li{g}]=nanJackKnife(x,y,E,ColorOrder(g,:),ColorOrder(g,:)+0.5.*abs(ColorOrder(g,:)-1),0.7);
                                    set(Li{g},'Clipping','off')
                                    H=get(Li{g},'Parent');
                                    %legendStr{g}={['group' num2str(g)]};
                                end
                                set(Pa,'Clipping','off')
                                set(H,'Layer','top')
                            end
                            h=refline(0,0);
                            set(h,'color','k')
                            
                            if c==length(conditions) && group==Ngroups
                                %on last iteration of conditions loop, add title and
                                %vertical lines to seperate conditions
                                if ~(size(params,1)>1)
                                    title(params{p},'fontsize',12)
                                end
                                axis tight
                                axis()
                                line([lineX; lineX],ylim,'color','k')
                                xticks=lineX+diff([lineX Xstart+condLength])./2;
                                set(gca,'fontsize',8,'Xlim',[0 Xstart+condLength],'Xtick', xticks, 'Xticklabel', conditions)                                
                            end
                            hold off
                        end
                        Xstart=Xstart+condLength;
                        lineX(end+1)=Xstart-0.5;
                    end
                    
                end
            end
            % linkaxes(ah,'y')
                        
            %set(ah(1:4),'Ylim',[-.03 .18])%Washout?
% % % % % %             set(ah(1),'Ylim',[-.02 .05])%Washout?
% % % % % %             set(ah(2),'Ylim',[-.01 .055])%Washout?
% % % % % %             set(ah(3),'Ylim',[-.03 .18])%Washout?
% % % % % %             set(ah(4),'Ylim',[-.01 .085])%Washout?
%             %set(ah(1:4),'Ylim',[-.03 .09])%transfer?
            
            %set(ah(1:4),'Ylim',[-.08 .17])
            %set(ah(1:4),'Ylim',[.066 .082])
            
%             set(ah(1),'Ylim',[-.1 .3]) % ADAPTATION
%             set(ah(2),'Ylim',[-.01 .11])
%             set(ah(3),'Ylim',[-.3 .02])
%             set(ah(4),'Ylim',[-.3 .02])
           % legend('O1', 'O2', 'Y1', 'Y2')
            set(gcf,'Renderer','painters');
            if indivFlag==1
            tiny=legend([Li{:}],[legendStr{:}]);
            set(tiny, 'FontSize', 12)
            end
        end
       
    end %static methods
    
end
