function results = barGroupsSpecial(SMatrix,params,groups,OFFSET, findMaxPerturb,plotFlag,indivFlag)

% Set colors
poster_colors;
% Set colors order
ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; p_gray; p_black;p_red];

catchNumPts = 3; % catch
steadyNumPts = 50; %end of adaptation
transientNumPts = 5;%5; % OG and Washout

if isempty(OFFSET)==1
OFFSET=zeros(1,100)
end


if nargin<3 || isempty(groups)
    groups=fields(SMatrix);          
end
ngroups=length(groups);

results.TMbase.avg=[];
results.TMbase.sd=[];
results.OGbase.avg=[];
results.OGbase.sd=[];
results.TMsteady1.avg=[];
results.TMsteady1.sd=[];
results.catch.avg=[];
results.catch.sd=[];
results.TMsteady2.avg=[];
results.TMsteady2.sd=[];
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


for g=1:ngroups
    %get subjects in group
    subjects=SMatrix.(groups{g}).IDs(:,1);
    
    ogafter_std=[];
    AdaptExtent=[];
    EarlyB1A=[];
    OGbase=[];
    TMbase=[];
    tmsteady1=[];
    tmcatch=[];
    tmsteady2=[];
    ogafter=[];
    tmafter=[];
    transfer=[];
    washout=[];
    transfer2=[];
    washout2=[];
        
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
        
        if nargin>4 && findMaxPerturb==1
            
%             %calculate TM and OG base in same manner as calculating OG post and TM
%             %post to ensure that they are different.
%
%             OGbaselineData=adaptData.getParamInCond(params,'OG base');
%             [newOGbaselineData,~]=bin_dataV1(OGbaselineData,transientNumPts);
%             [~,maxLoc]=max(abs(newOGbaselineData),[],1);
%             ind=sub2ind(size(newOGbaselineData),maxLoc,1:length(params));
%             OGbase=[OGbase; newOGbaselineData(ind)];
% 
            TMbaselineData=adaptData.getParamInCond(params,'TM base');
            if isempty(TMbaselineData)
                TMbaselineData=adaptData.getParamInCond(params,{'slow base','fast base'});
            end
            [newTMbaselineData,~]=bin_dataV1(TMbaselineData,transientNumPts);
            [~,maxLoc]=max(abs(newTMbaselineData),[],1);
            ind=sub2ind(size(newTMbaselineData),maxLoc,1:length(params));
            display('STOP I AM IN A LOOP THAT IS NOT EDITED')
            pause
            TMbase=[TMbase; newTMbaselineData(ind)];
% 
            %calculate catch as mean value during strides which caused a
            %maximum deviation from zero in step length asymmetry during 
            %'catchNumPts' consecutive steps
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','catch');
            tmcatchData=adaptData.getParamInCond(params,'catch');
            if isempty(tmcatchData)
                newtmcatchData=NaN(1,length(params));
                newStepAsymData=NaN;
            elseif size(tmcatchData,1)<3
                newtmcatchData=nanmean(tmcatchData);
                newStepAsymData=nanmean(stepAsymData);
            else
                [newStepAsymData,~]=bin_dataV1(stepAsymData,catchNumPts);
                [newtmcatchData,~]=bin_dataV1(tmcatchData,catchNumPts);
            end        
            [~,maxLoc]=max(abs(newStepAsymData),[],1);
%             ind=sub2ind(size(newtmcatchData),maxLoc*ones(1,length(params)),1:length(params));
            tmcatch=[tmcatch; newtmcatchData(maxLoc,:)];
            
            %calculate OG after as mean values during strides which cause a
            %maximum deviation from zero in step length asymmetry during
            %'transientNumPts' consecutive steps within first 10 strides
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG post');
            transferData=adaptData.getParamInCond(params,'OG post');
            [newStepAsymData,~]=bin_dataV1(stepAsymData(1+OFFSET(s):10+OFFSET(s),:),transientNumPts);
            [newTransferData,~]=bin_dataV1(transferData(1+OFFSET(s):10+OFFSET(s),:),transientNumPts);
            [~,maxLoc]=max(abs(newStepAsymData),[],1);
%             ind=sub2ind(size(newTransferData),maxLoc*ones(1,length(params)),1:length(params));
            ogafter=[ogafter; newTransferData(maxLoc,:)];
        
            %calculate TM after-effects same as transfer
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','TM post');
            tmafterData=adaptData.getParamInCond(params,'TM post');
            [newStepAsymData,~]=bin_dataV1(stepAsymData(1+OFFSET(s):10+OFFSET(s),:),transientNumPts);
            [newtmafterData,~]=bin_dataV1(tmafterData(1+OFFSET(s):10+OFFSET(s),:),transientNumPts);
            [~,maxLoc]=max(abs(newStepAsymData),[],1);
%             ind=sub2ind(size(newtmafterData),maxLoc*ones(1,length(params)),1:length(params));
            tmafter=[tmafter; newtmafterData(maxLoc,:)];
            
        else
            %calculate catch
            tmcatchData=adaptData.getParamInCond(params,'catch');
            if isempty(tmcatchData)
                newtmcatchData=NaN(1,length(params));
            elseif size(tmcatchData,1)<3
                newtmcatchData=nanmean(tmcatchData);
            else
                newtmcatchData=nanmean(tmcatchData(1:catchNumPts,:));
            end
            tmcatch=[tmcatch; newtmcatchData];  
            
            %calculate Transfer
            transferData=adaptData.getParamInCond(params,'OG post');
            ogafter=[ogafter; nanmean(transferData(1+OFFSET(s):transientNumPts+OFFSET(s),:))];
            ogafter_std=[ogafter_std; nanstd(transferData(1+OFFSET(s):transientNumPts+OFFSET(s),:))];
            
            %calculate TM after-effects
            tmafterData=adaptData.getParamInCond(params,'TM post');
            tmafter=[tmafter; nanmean(transferData(1+OFFSET(s):transientNumPts+OFFSET(s),:))];  
            
            %Calculate baseline
            TMbaselineData=adaptData.getParamInCond(params,'TM base');
%             if isempty(TMbaselineData)
%                 TMbaselineData=adaptData.getParamInCond(params,{'slow base','fast base'});
%             end
            [newTMbaselineData,~]=bin_dataV1(TMbaselineData,transientNumPts);%running average funciton
            [~,maxLoc]=max(abs(newTMbaselineData),[],1);
            %TMbase=[TMbase; nanmean(newTMbaselineData)]; %OLD
            
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if size(newTMbaselineData,1)>50
                N=40;
                base=nanmean(newTMbaselineData(end-N+1:end-5,:));
            else
                base=nanmean(newTMbaselineData(10:end,:));
            end
            TMbase=[TMbase; base];%NEW
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
%             ind=sub2ind(size(newTMbaselineData),maxLoc,1:length(params));
%             TMbase=[TMbase; newTMbaselineData(ind)];
            
            %calculate TM and OG base in same manner as calculating OG post and TM
            %post to ensure that they are different.
            OGbaselineData=adaptData.getParamInCond(params,'OG base');
            [newOGbaselineData,~]=bin_dataV1(OGbaselineData,transientNumPts);
            [~,maxLoc]=max(abs(newOGbaselineData),[],1);
            OGbase=[OGbase; nanmean(newOGbaselineData)];
%             ind=sub2ind(size(newOGbaselineData),maxLoc,1:length(params));
%             OGbase=[OGbase; newOGbaselineData(ind)];
        end
        
% %Early AB1 behavior
%         EarlyB1AData=adaptData.getParamInCond(params,'adaptation');
%         EarlyB1A=[EarlyB1A;nanmean(EarlyB1AData(1:5,:))];
        
        %calculate TM steady state #1
        tmsteady1Data=adaptData.getParamInCond(params,'adaptation');
        tmsteady1=[tmsteady1;nanmean(tmsteady1Data((end-5)-steadyNumPts+1:(end-5),:))];             
        
        %calculate TM steady state #2
        tmsteady2Data=adaptData.getParamInCond(params,'re-adaptation');
        tmsteady2=[tmsteady2;nanmean(tmsteady2Data((end-5)-steadyNumPts+1:(end-5),:))];       
        
        
        adapt2Sasym=adaptData.getParamInCond('netContribution','re-adaptation');
        adapt2Velocity=adaptData.getParamInCond('velocityContribution','re-adaptation');
        
        AdaptExtent=[AdaptExtent; nanmean(adapt2Sasym((end-5)-steadyNumPts+1:(end-5),:)-adapt2Velocity((end-5)-steadyNumPts+1:(end-5),:))];
        
        if strcmp(groups{g}, 'OA')==1
            TempTM=[0.133260439601791;0.264262815528979;0.270954600503630;0.232559310763997;0.272167427847111;0.258885239250101;0.371202830537235;0.329968622625190;0.286322713662362;0.155804463282275;0.392077997738293];
            TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.160339835773354,0.160339835773354,0.160339835773354,0.160339835773354;0.249322992547148,0.249322992547148,0.249322992547148,0.249322992547148;0.211078285810512,0.211078285810512,0.211078285810512,0.211078285810512;0.205532937989818,0.205532937989818,0.205532937989818,0.205532937989818;0.257340544734380,0.257340544734380,0.257340544734380,0.257340544734380;0.175976327967538,0.175976327967538,0.175976327967538,0.175976327967538;0.190263614046683,0.190263614046683,0.190263614046683,0.190263614046683;0.243721334959154,0.243721334959154,0.243721334959154,0.243721334959154;0.274190734546374,0.274190734546374,0.274190734546374,0.274190734546374;0.204183372769696,0.204183372769696,0.204183372769696,0.204183372769696;0.193724492735135,0.193724492735135,0.193724492735135,0.193724492735135];
        elseif strcmp(groups{g}, 'YA')==1
            TempTM=[[0.279516778950570,0.279516778950570,0.279516778950570,0.279516778950570;0.192298366835098,0.192298366835098,0.192298366835098,0.192298366835098;0.323923392840122,0.323923392840122,0.323923392840122,0.323923392840122;0.358500825965512,0.358500825965512,0.358500825965512,0.358500825965512;0.208594489243970,0.208594489243970,0.208594489243970,0.208594489243970;0.438429838146457,0.438429838146457,0.438429838146457,0.438429838146457;0.209597622046027,0.209597622046027,0.209597622046027,0.209597622046027;0.228252367268301,0.228252367268301,0.228252367268301,0.228252367268301;0.398664710822185,0.398664710822185,0.398664710822185,0.398664710822185;0.348774635805920,0.348774635805920,0.348774635805920,0.348774635805920;0.299516591045705,0.299516591045705,0.299516591045705,0.299516591045705]];
            %TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.261978085786794,0.261978085786794,0.261978085786794,0.261978085786794;0.239068679589291,0.239068679589291,0.239068679589291,0.239068679589291;0.250739682398584,0.250739682398584,0.250739682398584,0.250739682398584;0.339349164554652,0.339349164554652,0.339349164554652,0.339349164554652;0.233219217437480,0.233219217437480,0.233219217437480,0.233219217437480;0.200418255962934,0.200418255962934,0.200418255962934,0.200418255962934;0.217298631866235,0.217298631866235,0.217298631866235,0.217298631866235;0.232160883348121,0.232160883348121,0.232160883348121,0.232160883348121;0.212380989542890,0.212380989542890,0.212380989542890,0.212380989542890;0.206685544922131,0.206685544922131,0.206685544922131,0.206685544922131;0.243082719831555,0.243082719831555,0.243082719831555,0.243082719831555];
        elseif strcmp(groups{g}, 'OASV')==1
            TempTM=[[0.169267873440147;0.325903711305213;0.322871486313800;0.178460389689225;0.231949816538597;0.195546372835415;0.423510938065962;0.379756841456521]];
            TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.252235956160341,0.252235956160341,0.252235956160341,0.252235956160341;0.209878061164294,0.209878061164294,0.209878061164294,0.209878061164294;0.230185530738426,0.230185530738426,0.230185530738426,0.230185530738426;0.186914834039948,0.186914834039948,0.186914834039948,0.186914834039948;0.218414383850720,0.218414383850720,0.218414383850720,0.218414383850720;0.220239926485326,0.220239926485326,0.220239926485326,0.220239926485326;0.205662315462975,0.205662315462975,0.205662315462975,0.205662315462975;0.246380931949871,0.246380931949871,0.246380931949871,0.246380931949871];
        elseif strcmp(groups{g}, 'YASV')==1
            TempTM=[0.214700576	0.214700576	0.214700576	0.214700576; 0.241866162	0.241866162	0.241866162	0.241866162; 0.228612381	0.228612381	0.228612381	0.228612381; 0.441094175	0.441094175	0.441094175	0.441094175; 0.23127038	0.23127038	0.23127038	0.23127038; 0.140259443	0.140259443	0.140259443	0.140259443; 0.320805071	0.320805071	0.320805071	0.320805071; 0.190278968	0.190278968	0.190278968	0.190278968; 0.298121755	0.298121755	0.298121755	0.298121755];%Everyone
           % TempTM = (repmat(TempTM,1,size(params, 2)));
            extenter=[0.229791913399877,0.229791913399877,0.229791913399877,0.229791913399877;0.316525637059800,0.316525637059800,0.316525637059800,0.316525637059800;0.258265091035979,0.258265091035979,0.258265091035979,0.258265091035979;0.204661699710303,0.204661699710303,0.204661699710303,0.204661699710303;0.256188484020453,0.256188484020453,0.256188484020453,0.256188484020453;0.163120217794659,0.163120217794659,0.163120217794659,0.163120217794659;0.249808504784376,0.249808504784376,0.249808504784376,0.249808504784376;0.243510427017890,0.243510427017890,0.243510427017890,0.243510427017890];
        end
        
        %calculate relative after-effects
        transfer=[transfer; 100*(ogafter(s,:)./TempTM(s,:))];
        washout=[washout; 100*(tmafter(s,:)./TempTM(s,:))];

        
% %         %>> Harrison's new way
% %             %calculate relative after-effects    
% %     idx = find(strcmpi(params, 'stepLengthAsym'));
% %     if isempty(idx)
% %         idx = find(strcmpi(params, 'netContributionNorm2'));
% %     end
% %     if ~isempty(idx)
% %         Transfer= 100*(OGafter./(Catch(:,idx)*ones(1,nParams)));
% %         Washout= 100*(1-(TMafter./(Catch(:,idx)*ones(1,nParams))));
% %     else
% %         Transfer= 100*(OGafter./Catch);
% %         Washout = 100*(1-(TMafter./Catch));
% %     end

%         transfer2=[transfer2; 100*(ogafter./tmsteady2)];
%         washout2=[washout2; 100*(tmafter./tmsteady2)];
        
    end   
    
%      transfer2=[transfer2; 100*(ogafter./(AdaptExtent*ones(1,length(params))))];
%      washout2=[washout2; 100-(100*(tmafter./(AdaptExtent*ones(1,length(params)))))];
%     


transfer2=[transfer2; 100*(ogafter./extenter)];
washout2=[washout2; 100-(100*(tmafter./extenter))];
        
    nSubs=length(subjects);
    
    results.OGbase.avg(end+1,:)=nanmean(OGbase,1);
    results.OGbase.sd(end+1,:)=nanstd(OGbase,1);
    results.OGbase.indiv.(groups{g})=OGbase;
    
    results.TMbase.avg(end+1,:)=nanmean(TMbase,1);
    results.TMbase.sd(end+1,:)=nanstd(TMbase,1);
    results.TMbase.indiv.(groups{g})=TMbase;
    
%     results.EarlyB1A.avg(end+1,:)=nanmean(EarlyB1A,1);
%     results.EarlyB1A.sd(end+1,:)=nanstd(EarlyB1A,1);
%     results.EarlyB1A.indiv.(groups{g})=EarlyB1A;
% 
%     
    results.TMsteady1.avg(end+1,:)=nanmean(tmsteady1,1);
    results.TMsteady1.sd(end+1,:)=nanstd(tmsteady1,1)./sqrt(nSubs);
    results.TMsteady1.indiv.(groups{g})=tmsteady1;
    
    results.catch.avg(end+1,:)=nanmean(tmcatch,1);
    results.catch.sd(end+1,:)=nanstd(tmcatch,1)./sqrt(nSubs);
    results.catch.indiv.(groups{g})=tmcatch;
    
    results.TMsteady2.avg(end+1,:)=nanmean(tmsteady2,1);
    results.TMsteady2.sd(end+1,:)=nanstd(tmsteady2,1)./sqrt(nSubs);
    results.TMsteady2.indiv.(groups{g})=tmsteady2;
    
    results.OGafter.avg(end+1,:)=nanmean(ogafter,1);
    results.OGafter.sd(end+1,:)=nanstd(ogafter,1)./sqrt(nSubs);
    results.OGafter.indiv.(groups{g})=ogafter;
    results.OGafter.indivSTD.(groups{g})=ogafter_std
    
    results.TMafter.avg(end+1,:)=nanmean(tmafter,1);
    results.TMafter.sd(end+1,:)=nanstd(tmafter,1)./sqrt(nSubs);
    results.TMafter.indiv.(groups{g})=tmafter;    
    
    results.Transfer.avg(end+1,:)=nanmean(transfer,1);
    results.Transfer.sd(end+1,:)=nanstd(transfer,1)./sqrt(nSubs);
    results.Transfer.indiv.(groups{g})=transfer;
    
    results.Washout.avg(end+1,:)=nanmean(washout,1);
    results.Washout.sd(end+1,:)=nanstd(washout,1)./sqrt(nSubs);
    results.Washout.indiv.(groups{g})=washout;
    
    results.Transfer2.avg(end+1,:)=nanmean(transfer2,1);
    results.Transfer2.sd(end+1,:)=nanstd(transfer2,1)./sqrt(nSubs);
    results.Transfer2.indiv.(groups{g})=transfer2;
    
    results.Washout2.avg(end+1,:)=nanmean(washout2,1);
    results.Washout2.sd(end+1,:)=nanstd(washout2,1)./sqrt(nSubs);
    results.Washout2.indiv.(groups{g})=washout2;
end

%plot stuff
if nargin>4 && ~isempty(plotFlag)
    epochs=fields(results);

    %plot first five epochs
    numPlots=4*length(params); 
    ah=optimizedSubPlot(numPlots,length(params),5,'ltr');
    i=1;
    for p=1:length(params)
        limy=[];
        for t=1:4    
            axes(ah(i))
            hold on        
            for b=1:ngroups
                bar(b,results.(epochs{t}).avg(b,p),'facecolor',ColorOrder(b,:));
                if nargin>6 && ~isempty(indivFlag)
                    plot(b,results.(epochs{t}).indiv.(groups{b})(:,p),'k*')
                end
            end
            errorbar(results.(epochs{t}).avg(:,p),results.(epochs{t}).sd(:,p),'.','LineWidth',2,'Color','k')
            set(gca,'Xtick',1:ngroups,'XTickLabel',groups,'fontSize',12)
            axis tight
            limy=[limy get(gca,'Ylim')];
            ylabel(params{p})
            title(epochs{t})
            i=i+1;

        end
        set(ah(p*4-3:p*4),'Ylim',[min(limy) max(limy)])
    end


    %plot last four epochs
    numPlots=4*length(params);
    ah=optimizedSubPlot(numPlots,length(params),4,'ltr');
    i=1;
    for p=1:length(params)
        %limy=[];
        for t=6:9
            axes(ah(i))
            hold on        
            for b=1:ngroups
                bar(b,results.(epochs{t}).avg(b,p),'facecolor',ColorOrder(b,:));  
                if nargin>6 && ~isempty(indivFlag)
                    plot(b,results.(epochs{t}).indiv.(groups{b})(:,p),'k*')
                end
            end
            errorbar(results.(epochs{t}).avg(:,p),results.(epochs{t}).sd(:,p),'.','LineWidth',2,'Color','k')
            set(gca,'Xtick',1:ngroups,'XTickLabel',groups,'fontSize',12)
            axis tight
            %limy=[limy get(gca,'Ylim')];
            ylabel(params{p})
            title(epochs{t})
            i=i+1;
        end
        %set(ah(p*4-3:p*4),'Ylim',[min(limy) max(limy)])
    end
end


