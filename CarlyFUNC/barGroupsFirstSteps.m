function results = barGroupsFirstSteps(SMatrix,params,groups,indivFlag, FinalStata, epochs)

% Set colors
poster_colors;
% Set colors order
ColorOrder=[p_plum; p_orange; p_fade_green; p_fade_blue; p_red; p_green; p_blue; p_fade_red; p_lime; p_yellow; p_gray; p_black; p_red; p_plum; p_plum; p_plum;];

catchNumPts = 3; % catch
steadyNumPts = 50; %end of adaptation
transientNumPts = 5; % OG and Washout

if nargin<3 || isempty(groups)
    groups=fields(SMatrix);
end
ngroups=length(groups);

results.TMstart.avg=[];
results.TMstart.sd=[];
results.TMsteady1.avg=[];
results.TMsteady1.sd=[];
results.PerForget.avg=[];
results.PerForget.sd=[];
results.catch.avg=[];
results.catch.sd=[];
results.TMsteady2.avg=[];
results.TMsteady2.sd=[];


if exist('FinalStata')==1 && ~isempty(FinalStata)
    GrpNum=[size(SMatrix.(groups{1}).IDs, 1)...
        size(SMatrix.(groups{1}).IDs, 1)+size(SMatrix.(groups{2}).IDs, 1)...
        size(SMatrix.(groups{1}).IDs, 1)+size(SMatrix.(groups{2}).IDs, 1)+size(SMatrix.(groups{3}).IDs, 1)...
        size(SMatrix.(groups{1}).IDs, 1)+size(SMatrix.(groups{2}).IDs, 1)+size(SMatrix.(groups{3}).IDs, 1)+size(SMatrix.(groups{4}).IDs, 1)];
    
    results.Strides2SS.indiv.(groups{1})=[FinalStata(1:GrpNum(1), :)];
    results.Strides2SS.indiv.(groups{2})=[FinalStata(GrpNum(1)+1:GrpNum(2), :)];
    results.Strides2SS.indiv.(groups{3})=[FinalStata(GrpNum(2)+1:GrpNum(3), :)];
    results.Strides2SS.indiv.(groups{4})=[FinalStata(GrpNum(3)+1:GrpNum(4), :)];
    results.Strides2SS.avg=[nanmean(results.Strides2SS.indiv.(groups{1})); nanmean(results.Strides2SS.indiv.(groups{2})); nanmean(results.Strides2SS.indiv.(groups{3})); nanmean(results.Strides2SS.indiv.(groups{4}))];
    results.Strides2SS.sd=[nanstd(results.Strides2SS.indiv.(groups{1}))/sqrt(GrpNum(1));... %11
        nanstd(results.Strides2SS.indiv.(groups{2}))/sqrt(GrpNum(2)-GrpNum(1));... %8
        nanstd(results.Strides2SS.indiv.(groups{3}))/sqrt(GrpNum(3)-GrpNum(2));... %11
        nanstd(results.Strides2SS.indiv.(groups{4}))/sqrt(GrpNum(4)-GrpNum(3))]; %
else
    results.Strides2SS.avg=zeros(4, 4);
    results.Strides2SS.sd=zeros(4, 4);
    results.Strides2SS.indiv=zeros(4, 4);
end

results.OGafter.avg=[];
results.OGafter.sd=[];
results.TMafter.avg=[];
results.TMafter.sd=[];
results.Transfer.avg=[];
results.Transfer.sd=[];
results.Washout.avg=[];
results.Washout.sd=[];
results.Transfer2.avg=[];
results.Transfer2.sd=[];
results.Washout2.avg=[];
results.Washout2.sd=[];
results.Remember.avg=[];
results.Remember.sd=[];

results.MagAdapt1.avg=[];
results.MagAdapt1.sd=[];
results.Forget.avg=[];
results.Forget.sd=[];
results.AVGForget.avg=[];
results.AVGForget.sd=[];

results.AdaptExtent.avg=[];
results.AdaptExtent.sd=[];

results.AdaptExtent1.avg=[];
results.AdaptExtent1.sd=[];

for g=1:ngroups
    %get subjects in group
    subjects=SMatrix.(groups{g}).IDs(:,1);
    AdaptExtent=[];
    TMstart=[];
    perALL=[];
    remember=[];
    stepsymmetryCatch=[];
    perforget=[];
    AVGforget=[];
    forget=[];
    tmsteady1=[];
    tmcatch=[];
    tmsteady2=[];
    ogafter=[];
    tmafter=[];
    transfer=[];
    washout=[];
    transfer2=[];
    washout2=[];
    MagAdapt1=[];
    AdaptExtent1=[];
    for s=1:length(subjects)
        %load subject
        load([subjects{s} 'params.mat'])

        
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
        
        %remove baseline bias
        adaptData=adaptData.removeBias;
        
%         %Starting Adaptation
         TMstartData=adaptData.getParamInCond(params,'adaptation');
         TMstart=[TMstart;nanmean(TMstartData(1:5,:), 1)];
        
        %         %calculate TM steady state #1
        tmsteady1Data=adaptData.getParamInCond(params,'adaptation');
        tmsteady1=[tmsteady1;nanmean(tmsteady1Data((end-5)-(steadyNumPts)+1:(end-5),:))];
        
        
        %calculate forgetting between B1 and B2 of adaptaiton
        test=adaptData.metaData.conditionName;
        test(cellfun(@isempty,test))={''};
        epoch=find(ismember(test, 'adaptation')==1);
        wantedtrials=adaptData.metaData.trialsInCondition{epoch};
        forgetB1Data=adaptData.getParamInTrial(params,wantedtrials(1));
        forgetB2Data=adaptData.getParamInTrial(params,wantedtrials(2));
        forget=[forget; nanmean(forgetB1Data(end-4:end,:))-nanmean(forgetB2Data(1:5,:))];
        
        %calculate the average forgetting between adaptation and
        %re-adaptation
        forgetB3Data=adaptData.getParamInTrial(params,wantedtrials(3));
        forgetB4Data=adaptData.getParamInTrial(params,wantedtrials(4));
        BOCHI=[nanmean(forgetB1Data(end-4:end,:))-nanmean(forgetB2Data(1:5,:));...
            nanmean(forgetB2Data(end-4:end,:))-nanmean(forgetB3Data(1:5,:));...
            nanmean(forgetB3Data(end-4:end,:))-nanmean(forgetB4Data(1:5,:))];
        AVGforget=[AVGforget; nanmean(BOCHI)];
        
        
        %calculate TM steady state #2
        tmsteady2Data=adaptData.getParamInCond(params,'re-adaptation');
        tmsteady2=[tmsteady2;nanmean(tmsteady2Data((end-5)-steadyNumPts+1:(end-5),:))];
        
        adapt2Sasym=adaptData.getParamInCond('netContribution','re-adaptation');
        adapt2Velocity=adaptData.getParamInCond('velocityContribution','re-adaptation');
        
        AdaptExtent=[AdaptExtent; nanmean(adapt2Sasym((end-5)-steadyNumPts+1:(end-5),:)-adapt2Velocity((end-5)-steadyNumPts+1:(end-5),:))];
        
        adapt2Sasym1=adaptData.getParamInCond('netContribution','adaptation');
        adapt2Velocity1=adaptData.getParamInCond('velocityContribution','adaptation');
        
        AdaptExtent1=[AdaptExtent1; nanmean(adapt2Sasym1((end-5)-steadyNumPts+1:(end-5),:)-adapt2Velocity1((end-5)-steadyNumPts+1:(end-5),:))];
        
        % ***** Add constant, only for the net 04/2015
        minValue=[ 0 0 0 abs(tmsteady2(s, 3))]; % shift by individual velo steady state
        forgetB1Data=forgetB1Data+(repmat(minValue,length(forgetB1Data),1));
        forgetB2Data=forgetB2Data+(repmat(minValue,length(forgetB2Data),1));
        forgetB3Data=forgetB3Data+(repmat(minValue,length(forgetB3Data),1));
        forgetB4Data=forgetB4Data+(repmat(minValue,length(forgetB4Data),1));
        %*****
        
        per=[(nanmean(forgetB1Data(end-29:end-10,:))-nanmean(forgetB2Data(4:8,:)))./nanmean(forgetB1Data(end-29:end-10,:));...
            (nanmean(forgetB2Data(end-29:end-10,:))-nanmean(forgetB3Data(4:8,:)))./nanmean(forgetB2Data(end-29:end-10,:));...
            (nanmean(forgetB3Data(end-29:end-10,:))-nanmean(forgetB4Data(4:8,:)))./nanmean(forgetB3Data(end-29:end-10,:))];
        
        perALL=[perALL; per(:,4)];
        perforget=[perforget; (100*(nanmean(per)))];
        
        
        
        %%% ~~~~~~~~
        %             calculate catch as mean value during strides which caused a
        %             maximum deviation from zero in step length asymmetry during
        %             'catchNumPts' consecutive steps
        stepAsymData=adaptData.getParamInCond('stepLengthAsym','catch');
        tmcatchData=adaptData.getParamInCond(params,'catch');
        if isempty(tmcatchData)
            newtmcatchData=NaN(1,length(params));
            newStepAsymData=NaN;
        elseif size(tmcatchData,1)<catchNumPts
            newtmcatchData=nanmean(tmcatchData);
            newStepAsymData=nanmean(stepAsymData);
        else
            [newStepAsymData,~]=bin_dataV1(stepAsymData,catchNumPts);
            [newtmcatchData,~]=bin_dataV1(tmcatchData,catchNumPts);
        end
        [~,maxLoc]=max(abs(newStepAsymData),[],1);
        tmcatch=[tmcatch; newtmcatchData(maxLoc,:)];
        stepsymmetryCatch=[stepsymmetryCatch; newStepAsymData(maxLoc,:).*ones(1,size(tmcatch, 2))];
        %%% ~~~~~~~~
        
        
        
        %Magnitude adapted in the first adaptation
        MagAdapt1=[MagAdapt1; nanmean(tmsteady2Data((end-5)-(steadyNumPts)+1:(end-5),:))-nanmean(TMstartData(1:5,:), 1)];
        
        
        %First 5 strides of Transfer
        transferData=adaptData.getParamInCond(params,'OG post');
        
        %%% ~~~~~~~~
        %Band Exclusion
        %Here is where I have the strides that I would have excluded
        %before, need to recalculate the band bass, but its a start.
        %adaptData.getParamInCond({'WhatsUp'},'OG post')
        DStimes = [adaptData.getParamInCond({'doubleSupportSlow'},'OG post'); adaptData.getParamInCond({'doubleSupportFast'},'OG post')];
        SwingTimes = [adaptData.getParamInCond({'swingTimeSlow'},'OG post'); adaptData.getParamInCond({'swingTimeFast'},'OG post')];
        
        if nanmean(DStimes)<0
            DSthresh = -1.5.*nanmean(DStimes);
            Swingthresh = -1.5.*nanmean(SwingTimes);
        else
            DSthresh = 1.5.*nanmean(DStimes);
            Swingthresh = 1.5.*nanmean(SwingTimes);
        end
        
        BandData=adaptData.getParamInCond({'doubleSupportSlow', 'doubleSupportFast', 'swingTimeSlow', 'swingTimeFast'},'OG post');
        hipster=adaptData.getParamInCond({'WhatsUp'},'OG post');
        
        BadIndice=[];
        
        if isempty(transferData)==1
            ogafter=[ogafter; nan(1, size(params, 2))];
        else
            ogafter=[ogafter; nanmean(transferData(1:transientNumPts, :))];
        end

        %             calculate TM after-effects as mean value during strides which caused a
        %             maximum deviation from zero in step length asymmetry during
        WstepAsymData=adaptData.getParamInCond('stepLengthAsym','TM post');
        tmafterData=adaptData.getParamInCond(params,'TM post');

        if isempty(tmafterData)
            newtmafterData=NaN(1,length(params));
            newWSAData=NaN;
        elseif size(tmafterData,1)<transientNumPts
            newtmafterData=nanmean(tmafterData);
            newWSAData=nanmean(WstepAsymData);
        else
            [newWSAData,~]=bin_dataV1(WstepAsymData(1:25,:),transientNumPts);
            [newtmafterData,~]=bin_dataV1(tmafterData(1:25,:),transientNumPts);
        end
        [~,maxLoc]=max(abs(newWSAData),[],1);
        tmafter=[tmafter; newtmafterData(maxLoc,:)];

        %%% ~~~~~~~~
        %HERE I am inputting the Net catch values for each subject, i do
        %this because I have different param files for flat and overground
        %so I have to manually enter the TM catch values for when I
        %aprocessing the OG transfer stuff
        
        if strcmp(groups{g}, 'OA')==1
            TempTM=[0.133260439601791;0.264262815528979;0.270954600503630;0.232559310763997;0.272167427847111;0.258885239250101;0.371202830537235;0.329968622625190;0.286322713662362;0.155804463282275;0.392077997738293];
            TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.160339835773354,0.160339835773354,0.160339835773354,0.160339835773354;0.249322992547148,0.249322992547148,0.249322992547148,0.249322992547148;0.211078285810512,0.211078285810512,0.211078285810512,0.211078285810512;0.205532937989818,0.205532937989818,0.205532937989818,0.205532937989818;0.257340544734380,0.257340544734380,0.257340544734380,0.257340544734380;0.175976327967538,0.175976327967538,0.175976327967538,0.175976327967538;0.190263614046683,0.190263614046683,0.190263614046683,0.190263614046683;0.243721334959154,0.243721334959154,0.243721334959154,0.243721334959154;0.274190734546374,0.274190734546374,0.274190734546374,0.274190734546374;0.204183372769696,0.204183372769696,0.204183372769696,0.204183372769696;0.193724492735135,0.193724492735135,0.193724492735135,0.193724492735135];
        elseif strcmp(groups{g}, 'YA')==1
            TempTM=[[0.279516778950570,0.279516778950570,0.279516778950570,0.279516778950570;0.192298366835098,0.192298366835098,0.192298366835098,0.192298366835098;0.323923392840122,0.323923392840122,0.323923392840122,0.323923392840122;0.358500825965512,0.358500825965512,0.358500825965512,0.358500825965512;0.208594489243970,0.208594489243970,0.208594489243970,0.208594489243970;0.438429838146457,0.438429838146457,0.438429838146457,0.438429838146457;0.209597622046027,0.209597622046027,0.209597622046027,0.209597622046027;0.228252367268301,0.228252367268301,0.228252367268301,0.228252367268301;0.398664710822185,0.398664710822185,0.398664710822185,0.398664710822185;0.348774635805920,0.348774635805920,0.348774635805920,0.348774635805920;0.299516591045705,0.299516591045705,0.299516591045705,0.299516591045705]];
            extenter=[0.261978085786794,0.261978085786794,0.261978085786794,0.261978085786794;0.239068679589291,0.239068679589291,0.239068679589291,0.239068679589291;0.250739682398584,0.250739682398584,0.250739682398584,0.250739682398584;0.339349164554652,0.339349164554652,0.339349164554652,0.339349164554652;0.233219217437480,0.233219217437480,0.233219217437480,0.233219217437480;0.200418255962934,0.200418255962934,0.200418255962934,0.200418255962934;0.217298631866235,0.217298631866235,0.217298631866235,0.217298631866235;0.232160883348121,0.232160883348121,0.232160883348121,0.232160883348121;0.212380989542890,0.212380989542890,0.212380989542890,0.212380989542890;0.206685544922131,0.206685544922131,0.206685544922131,0.206685544922131;0.243082719831555,0.243082719831555,0.243082719831555,0.243082719831555];
        elseif strcmp(groups{g}, 'OASV')==1
            TempTM=[[0.169267873440147;0.325903711305213;0.322871486313800;0.178460389689225;0.231949816538597;0.195546372835415;0.423510938065962;0.379756841456521]];
            TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.252235956160341,0.252235956160341,0.252235956160341,0.252235956160341;0.209878061164294,0.209878061164294,0.209878061164294,0.209878061164294;0.230185530738426,0.230185530738426,0.230185530738426,0.230185530738426;0.186914834039948,0.186914834039948,0.186914834039948,0.186914834039948;0.218414383850720,0.218414383850720,0.218414383850720,0.218414383850720;0.220239926485326,0.220239926485326,0.220239926485326,0.220239926485326;0.205662315462975,0.205662315462975,0.205662315462975,0.205662315462975;0.246380931949871,0.246380931949871,0.246380931949871,0.246380931949871];
        elseif strcmp(groups{g}, 'YASV')==1
            TempTM=[0.214700576	0.214700576	0.214700576	0.214700576; 0.241866162	0.241866162	0.241866162	0.241866162; 0.228612381	0.228612381	0.228612381	0.228612381; 0.441094175	0.441094175	0.441094175	0.441094175; 0.23127038	0.23127038	0.23127038	0.23127038; 0.140259443	0.140259443	0.140259443	0.140259443; 0.320805071	0.320805071	0.320805071	0.320805071; 0.190278968	0.190278968	0.190278968	0.190278968; 0.298121755	0.298121755	0.298121755	0.298121755];%Everyone
            extenter=[0.229791913399877,0.229791913399877,0.229791913399877,0.229791913399877;0.316525637059800,0.316525637059800,0.316525637059800,0.316525637059800;0.258265091035979,0.258265091035979,0.258265091035979,0.258265091035979;0.204661699710303,0.204661699710303,0.204661699710303,0.204661699710303;0.256188484020453,0.256188484020453,0.256188484020453,0.256188484020453;0.163120217794659,0.163120217794659,0.163120217794659,0.163120217794659;0.249808504784376,0.249808504784376,0.249808504784376,0.249808504784376;0.243510427017890,0.243510427017890,0.243510427017890,0.243510427017890];
        end
        
        %Now used

        transfer=[transfer; 100*(ogafter(s,:)./TempTM(s,:))];
        washout=[washout; 100*(tmafter(s,:)./TempTM(s,:))];
       
        
    end
    
    transfer2=[transfer2; 100*(ogafter./extenter)];
    washout2=[washout2; (100*(tmafter./extenter))];
    
    results.TMstart.avg(end+1,:)=nanmean(TMstart,1);
    results.TMstart.sd(end+1,:)=nanstd(TMstart,0)/sqrt(length(TMstart));
    results.TMstart.indiv.(groups{g})=TMstart;
    
    results.Forget.avg(end+1,:)=nanmean(forget,1);
    results.Forget.sd(end+1,:)=nanstd(forget,0)/sqrt(length(forget));
    results.Forget.indiv.(groups{g})=forget;
    
    results.AVGForget.avg(end+1,:)=nanmean(AVGforget,1);
    results.AVGForget.sd(end+1,:)=nanstd(AVGforget,0)/sqrt(length(AVGforget));
    results.AVGForget.indiv.(groups{g})=AVGforget;
    
    results.PerForget.avg(end+1,:)=nanmean(perforget,1);
    results.PerForget.sd(end+1,:)=nanstd(perforget,0)/sqrt(length(perforget));
    results.PerForget.indiv.(groups{g})=perforget;
    results.PerForget.indivAll.(groups{g})=perALL;
    
    results.TMsteady1.avg(end+1,:)=nanmean(tmsteady1,1);
    results.TMsteady1.sd(end+1,:)=nanstd(tmsteady1,0)/sqrt(length(tmsteady1));
    results.TMsteady1.indiv.(groups{g})=tmsteady1;
    
    results.catch.avg(end+1,:)=nanmean(tmcatch,1);
    results.catch.sd(end+1,:)=nanstd(tmcatch,0)/sqrt(length(tmsteady1));
    results.catch.indiv.(groups{g})=tmcatch;
    
    results.TMsteady2.avg(end+1,:)=nanmean(tmsteady2,1);
    results.TMsteady2.sd(end+1,:)=nanstd(tmsteady2,0)/sqrt(length(tmsteady1));
    results.TMsteady2.indiv.(groups{g})=tmsteady2;
    
    results.TMafter.avg(end+1,:)=nanmean(tmafter,1);
    results.TMafter.sd(end+1,:)=nanstd(tmafter,0)/sqrt(length(tmsteady1));
    results.TMafter.indiv.(groups{g})=tmafter;
    
    results.OGafter.avg(end+1,:)=nanmean(ogafter,1);
    results.OGafter.sd(end+1,:)=nanstd(ogafter,0)/sqrt(length(tmsteady1));
    results.OGafter.indiv.(groups{g})=ogafter;
    
    results.Transfer.avg(end+1,:)=nanmean(transfer,1);
    results.Transfer.sd(end+1,:)=nanstd(transfer,0)/sqrt(length(tmsteady1));
    results.Transfer.indiv.(groups{g})=transfer;
    
    results.Washout.avg(end+1,:)=nanmean(washout,1);
    results.Washout.sd(end+1,:)=nanstd(washout,0)/sqrt(length(tmsteady1));
    results.Washout.indiv.(groups{g})=washout;
    
    results.Transfer2.avg(end+1,:)=nanmean(transfer2,1);
    results.Transfer2.sd(end+1,:)=nanstd(transfer2,0)/sqrt(length(tmsteady1));
    results.Transfer2.indiv.(groups{g})=transfer2;
    
    results.Washout2.avg(end+1,:)=nanmean(washout2,1);
    results.Washout2.sd(end+1,:)=nanstd(washout2,0)/sqrt(length(tmsteady1));
    results.Washout2.indiv.(groups{g})=washout2;
    
        results.Remember.avg(end+1,:)=ones(1,length(params));
    results.Remember.sd(end+1,:)=ones(1,length(params));
    
        results.AdaptExtent.avg(end+1,:)=nanmean(AdaptExtent,1)*ones(1,length(params));
    results.AdaptExtent.sd(end+1,:)=nanstd(AdaptExtent,0)/sqrt(length(AdaptExtent))*ones(1,length(params));
    results.AdaptExtent.indiv.(groups{g})=[AdaptExtent, AdaptExtent,AdaptExtent,AdaptExtent];
    
    results.MagAdapt1.avg(end+1,:)=nanmean(MagAdapt1,1);
    results.MagAdapt1.sd(end+1,:)=nanstd(MagAdapt1,0)/sqrt(length(MagAdapt1));
    results.MagAdapt1.indiv.(groups{g})=MagAdapt1;
    
            results.AdaptExtent1.avg(end+1,:)=nanmean(AdaptExtent1,1)*ones(1,length(params));
    results.AdaptExtent1.sd(end+1,:)=nanstd(AdaptExtent1,0)/sqrt(length(AdaptExtent1))*ones(1,length(params));
    results.AdaptExtent1.indiv.(groups{g})=[AdaptExtent1, AdaptExtent1,AdaptExtent1,AdaptExtent1];
    
end
%plot stuff
if ~exist('epochs')
        epochs=fields(results);
elseif isempty(epochs)
    return
end

numPlots=length(epochs)*length(params);
ah=optimizedSubPlot(numPlots,length(params),length(epochs),'ltr');
set(ah,'defaultTextFontName', 'Arial')
i=1;limymin=[];limymax=[];
for p=1:length(params)
    
    for t=1:length(epochs)
        axes(ah(i))
        hold on
        
        line([.5 4.5], [0 0], 'Color','k')
        for b=1:ngroups
            
            bar(b,results.(epochs{t}).avg(b,p),'facecolor',ColorOrder(b,:)); hold on
            errorbar(b, results.(epochs{t}).avg(b,p),results.(epochs{t}).sd(b,p),'.','LineWidth',2,'Color','k')
            
        end
        set(gca,'Xtick',[1.5 3.5],'XTickLabel',[{'Old'} {'Young'}],'fontSize',12)
        
        axis tight
        temp=[get(gca,'Ylim')];
        limymin(p, t)=temp(1);
        limymax(p, t)=temp(2);
        ylabel(params{p})
        title(epochs{t})
        i=i+1;
        
    end

end

 