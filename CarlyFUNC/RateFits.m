%close all
%clear all
%clc

cd('/Users/carlysombric/Desktop/NewOGProcessing/newMethod/paramFiles')

Smatrix=makeSMatrix;

%subs=[subFileList(Smatrix.YA)];
subs=[{subFileList(Smatrix.OA)} {subFileList(Smatrix.YA)}];

conds={'adaptation', 're-adaptation'}

params={'stepTimeContribution', 'spatialContribution'};

%[avg, indiv]=adaptationData.plotAvgTimeCourse(subs, params, conds, 5, 1) %Bias automatically
[avg, indiv]=adaptationData.plotAvgTimeCourseBlocksONTOP(subs,params,conds,5)


% Results=barGroups(Smatrix, params, {'OA', 'YA'});
% 
% % subs=[subFileList(Smatrix.OA) subFileList(Smatrix.OASV)];
% % OAResults=barGroups(Smatrix, params, {'OA', 'OASV'}); %Transfer is the % catch, and Transfer 2 is 	the % of steady state
% 
% [Oavg, Oindiv]=adaptationData.plotAvgTimeCourse(subFileList(Smatrix.OA), params, conds, 5, 1) %Bias automatically
% [Yavg, Yindiv]=adaptationData.plotAvgTimeCourse(subFileList(Smatrix.YA), params, conds, 5, 1) %Bias automatically

%% 1.) Do the rates for the first 4 blocks of adaptation

%First 4 blocks of adaptation
blockALL=avg.stepTimeContribution.adaptation;
blockALLx=[1:length(blockALL)];

blockALLs=avg.spatialContribution.adaptation;
blockALLxs=[1:length(blockALLs)];


%% 2.) Do the rates for individual blocks

for i=1:size(subs,2)
    load(char(subs(i)))
    test=adaptData.metaData.conditionName;
    test(cellfun(@isempty,test))={''}
    epoch=find(ismember(test, 'adaptation')==1);
    trial=adaptData.metaData.trialsInCondition{epoch};
    
    temp1=adaptData.getParamInTrial({'stepTimeContribution'}, trial(1));
    temp1s=adaptData.getParamInTrial({'spatialContribution'}, trial(1));
    if exist('block1')==0 || length(temp1) == size(block1, 2)
    elseif length(temp1) < size(block1, 1)%new is too short
        temp1=[temp1; NaN*ones(size(block1, 1)-length(temp1), 1)];
        temp1s=[temp1s; NaN*ones(size(block1s, 1)-length(temp1s), 1)];
    elseif  size(block1, 1) < length(temp1) %new is too long
        block1=[block1; NaN.*ones(length(temp1)-size(block1, 1), size(block1, 2) )];
        block1s=[block1s; NaN.*ones(length(temp1s)-size(block1s, 1), size(block1s, 2) )];
    end
    
    temp2=adaptData.getParamInTrial({'stepTimeContribution'}, trial(2));
    temp2s=adaptData.getParamInTrial({'spatialContribution'}, trial(2));
    if exist('block2')==0 || length(temp2) == size(block2, 2)
    elseif length(temp2) < size(block2, 1)%new is too short
        temp2=[temp2; NaN*ones(size(block2, 1)-length(temp2), 1)];
        temp2s=[temp2s; NaN*ones(size(block2s, 1)-length(temp2s), 1)];
    elseif  size(block2, 1) < length(temp2) %new is too long
        block2=[block2; NaN.*ones(length(temp2)-size(block2, 1), size(block2, 2) )];
        block2s=[block2s; NaN.*ones(length(temp2s)-size(block2s, 1), size(block2s, 2) )];
    end
    
    
    temp3=adaptData.getParamInTrial({'stepTimeContribution'}, trial(3));
    temp3s=adaptData.getParamInTrial({'spatialContribution'}, trial(3));
    if exist('block3')==0 || length(temp3) == size(block3, 2)
    elseif length(temp3) < size(block3, 1)%new is too short
        temp3=[temp3; NaN*ones(size(block3, 1)-length(temp3), 1)];
        temp3s=[temp3s; NaN*ones(size(block3s, 1)-length(temp3s), 1)];
    elseif  size(block3, 1) < length(temp3) %new is too long
        block3=[block3; NaN.*ones(length(temp3)-size(block3, 1), size(block3, 2) )];
        block3s=[block3s; NaN.*ones(length(temp3s)-size(block3s, 1), size(block3s, 2) )];
    end
    
    
    temp4=adaptData.getParamInTrial({'stepTimeContribution'}, trial(4));
    temp4s=adaptData.getParamInTrial({'spatialContribution'}, trial(4));
    if exist('block4')==0|| length(temp4) == size(block4, 2)
    elseif length(temp4) < size(block4, 1)%new is too short
        temp4=[temp4; NaN*ones(size(block4, 1)-length(temp4), 1)];
        temp4s=[temp4s; NaN*ones(size(block4s, 1)-length(temp4s), 1)];
    elseif  size(block4, 1) < length(temp4) %new is too long
        block4=[block4; NaN.*ones(length(temp4)-size(block4, 1), size(block4, 2) )];
        block4s=[block4s; NaN.*ones(length(temp4s)-size(block4s, 1), size(block4s, 2) )];
    end
    
    
    block1(:,i)=temp1;
    block2(:,i)=temp2;
    block3(:,i)=temp3;
    block4(:,i)=temp4;
    
    block1s(:,i)=temp1s;
    block2s(:,i)=temp2s;
    block3s(:,i)=temp3s;
    block4s(:,i)=temp4s;

    epochSS=find(ismember(test, 're-adaptation')==1);
    trialSS=adaptData.metaData.trialsInCondition{epoch};
    tempSS=adaptData.getParamInTrial({'stepTimeContribution'}, trial(end));
    SteadyState(1,i)=mean(tempSS(end-39:end));
    SteadyStateSTD(1,i)=std(tempSS(end-39:end));
    clear trial epoch temp1 temp2 temp3 temp4 adaptData test tempSS trialSS epochSS
end

% Blocks
b1a=nanmean(block1, 2);
b2a=nanmean(block2, 2);
b3a=nanmean(block3, 2);
b4a=nanmean(block4, 2);

figure(100)
subplot(1,4,1)
plot(b1a, '.')
axis([0 160 0 120])
title('A-Block 1', 'FontSize', 16)
ylabel('stepTimeContribution', 'FontSize', 16)
xlabel('Stride#', 'FontSize', 16)
subplot(1,4,2)
plot(b2a, '.')
axis([0 160 0 120])
title('A-Block 2', 'FontSize', 16)
subplot(1,4,3)
plot(b3a, '.')
axis([0 160 0 120])
title('A-Block 3', 'FontSize', 16)
subplot(1,4,4)
plot(b4a, '.')
axis([0 160 0 120])
title('A-Block 4', 'FontSize', 16)

b1as=nanmean(block1s, 2);
b2as=nanmean(block2s, 2);
b3as=nanmean(block3s, 2);
b4as=nanmean(block4s, 2);

b1ax=[1:length(b1a)];
b2ax=[1:length(b2a)];
b3ax=[1:length(b3a)];
b4ax=[1:length(b4a)];

b1axs=[1:length(b1as)];
b2axs=[1:length(b2as)];
b3axs=[1:length(b3as)];
b4axs=[1:length(b4as)];

% % % % %Plotting
% % % % figure
% % % % subplot(2, 1, 1)
% % % % plot(blockALLx, blockALL, '.k')
% % % % xlabel('Stride')
% % % % ylabel('Temporal Contribution')
% % % %
% % % % subplot(2, 1, 2)
% % % % plot(blockALLxs, blockALLs, '.k')
% % % % xlabel('Stride')
% % % % ylabel('Spatial Contribution')
% 
% 
% 
% % %spatially
% %
% xO=[1:1000];xY=xO;
% %
% % % % block 1-4: Fit Data
% y_overallY=-90.06*exp(-.007453*xO)+115.7;
% y_overallO=-122.6*exp(-.006264*xO)+105.7;
% %
% % % % block 1: Fit Data
% % % y_overallY=-104.9*exp(-.02096*xO)+108.9;
% % % y_overallO=-591*exp(-.001143*xO)+592.8;
% %
% % % % block 2: Fit Data
% % % y_overallY=-17.56*exp(-.006498*xO)+116.4;
% % % y_overallO=-86.61*exp(-.022*xO)+124.1;
% %
% % % % block 3: Fit Data
% % % y_overallY=-5.699*exp(-.02974*xO)+121.2;
% % % y_overallO=-55.49*exp(-.02294*xO)+129.6;
% %
% % % block 4: Fit Data
% % y_overallY=-.8303*exp(-.0009896*xO)+130.9;
% % y_overallO=-33.81*exp(-.02414*xO)+126.5;
% %
% % % % block 1: Raw Data
% % % %y_overallY=b1as; xY=[1:length(y_overallY)];
% % %  %y_overallY=b2as; xY=[1:length(y_overallY)];
% % % % y_overallY=b3as; xY=[1:length(y_overallY)];
% % % % y_overallY=b4as; xY=[1:length(y_overallY)];
% %
% % % % block 1-4: Raw Data
% % % y_overallY=Oavg.spatialContribution.adaptation; xY=[1:length(Oavg.spatialContribution.adaptation)];
% % % y_overallO=Yavg.spatialContribution.adaptation; xO=[1:length(Yavg.spatialContribution.adaptation)];
% %
% %
% oldss_sp=mean(Oavg.spatialContribution.adaptation(end-39:end)).*ones(1, length(y_overallO));
% youngss_sp=mean(Yavg.spatialContribution.adaptation(end-39:end)).*ones(1, length(y_overallY));
% %
% % [old,~] = intersections(xO,oldss_sp,xO,y_overallO,1)
% % [young,~] = intersections(xY,youngss_sp,xY,y_overallY,1)
% %
% %
% % % %temporally
% % % oldss_t=0.088678;
% % % youngss_t=0.10098;
% oldss_t=mean(Oavg.stepTimeContribution.adaptation(end-39:end));
% youngss_t=mean(Yavg.stepTimeContribution.adaptation(end-39:end));
% 
% %
% 
% ssold=mean(Oavg.spatialContribution.adaptation(end-39:end));
% ssyoung=mean(Yavg.spatialContribution.adaptation(end-39:end));
% 
% figure
% subplot(2, 1, 1)
% plot(Oavg.stepTimeContribution.adaptation, '.b'); hold on
% plot(Yavg.stepTimeContribution.adaptation, '.r'); hold on
% line([0 600],  [oldss_t oldss_t], 'Color', 'b', 'LineStyle','--'); hold on
% line([0 600],  [youngss_t youngss_t], 'Color', 'r', 'LineStyle','--'); hold on
% % area()
% xlabel('Strides')
% ylabel('Temporal Contribution')
% legend('OLD', 'YOUNG', 'OLD SS', 'YOUNG SS')
% title('Temporal Contribution', 'FontSize', 18)
% 
% subplot(2, 1, 2)
% plot(Oavg.spatialContribution.adaptation, '.b'); hold on
% plot(Yavg.spatialContribution.adaptation, '.r'); hold on
% line([0 600],  [ssold ssold], 'Color', 'b', 'LineStyle','--'); hold on
% line([0 600],  [ssyoung ssyoung], 'Color', 'r', 'LineStyle','--'); hold on
% xlabel('Strides')
% xlabel('Stride')
% ylabel('Spatial Contribution')
% legend('OLD', 'YOUNG', 'OLD SS', 'YOUNG SS')
% title('Spatial Contribution', 'FontSize', 18)
% 
% %want to be able to make bar plots
% % %need to blocks for each individual subject
% %         block1s(:,i)=temp1s; x1=[1: size(block1s,1)];
% %         block2s(:,i)=temp2s; x2=[1: size(block2s,1)];
% %         block3s(:,i)=temp3s; x3=[1: size(block3s,1)];
% %         block4s(:,i)=temp4s; x4=[1: size(block4s,1)];
% 
% % %And the steady state that they reach
% % SteadyState(1,i)=mean(tempSS(end-39:end));
% 
% x1=[1: size(block1s,1)];
% x2=[1: size(block2s,1)];
% x3=[1: size(block3s,1)];
% x4=[1: size(block4s,1)];
% 
% %% where I actually calculate the strides to steady state and forgetting amount
% numsteps=4;
% 
% for w=1:size(block1s,2)
%     [temp1,~]= intersections(x1,block1s(:,w),x1,(SteadyState(1,w)-2*SteadyStateSTD(1,w)).*ones(1, length(x1)),1);
%     [temp2,~]= intersections(x2,block2s(:,w),x2,(SteadyState(1,w)-2*SteadyStateSTD(1,w)).*ones(1, length(x2)),1);
%     [temp3,~]= intersections(x3,block3s(:,w),x3,(SteadyState(1,w)-2*SteadyStateSTD(1,w)).*ones(1, length(x3)),1);
%     [temp4,~]= intersections(x4,block4s(:,w),x4,(SteadyState(1,w)-2*SteadyStateSTD(1,w)).*ones(1, length(x4)),1);
%     
%     t1=find(diff([0; diff(ceil(temp1)); 0] == 1) == -1) - find(diff([0; diff(ceil(temp1)); 0] == 1) == 1);
%     t2=find(diff([0; diff(ceil(temp2)); 0] == 1) == -1) - find(diff([0; diff(ceil(temp2)); 0] == 1) == 1);
%     t3=find(diff([0; diff(ceil(temp3)); 0] == 1) == -1) - find(diff([0; diff(ceil(temp3)); 0] == 1) == 1);
%     t4=find(diff([0; diff(ceil(temp4)); 0] == 1) == -1) - find(diff([0; diff(ceil(temp4)); 0] == 1) == 1);
%     
%     
%     if isempty(temp1)==1
%         if mean(double(block1s(:,w)>SteadyState(1,w)-SteadyStateSTD(1,w)))>=.9
%             temp1=NaN;%temp1=0;
%         else
%             temp1=NaN;%
%         end
%     elseif isempty(t1)==1 || max(t1)+1< numsteps
%         temp1=NaN;
%     else
%         t=find(diff([0; diff(ceil(temp1)); 0] == 1) == 1);
%         temp1(1)=ceil(temp1(t(find(t1==max(t1), 1, 'first'))));
%         clear t
%     end
%     
%     if isempty(temp2)==1
%         if mean(double(block2s(:,w)>SteadyState(1,w)-SteadyStateSTD(1,w)))>=.9
%             temp2=NaN;%temp2=0;
%         else
%             temp2=NaN;
%         end
%     elseif isempty(t2)==1 || max(t2)+1< numsteps
%         temp2=NaN;
%     else
%         t=find(diff([0; diff(ceil(temp2)); 0] == 1) == 1);
%         temp2(1)=ceil(temp2(t(find(t2==max(t2), 1, 'first'))));
%         clear t
%     end
%     
%     if isempty(temp3)==1
%         if mean(double(block3s(:,w)>SteadyState(1,w)-SteadyStateSTD(1,w)))>=.9
%             temp3=NaN;%temp3=0;
%         else
%             temp3=NaN;
%         end
%     elseif isempty(t3)==1 || max(t3)+1< numsteps
%         temp3=NaN;
%     else
%         
%         t=find(diff([0; diff(ceil(temp3)); 0] == 1) == 1);
%         temp3(1)=ceil(temp3(t(find(t3==max(t3), 1, 'first'))));
%         clear t
%     end
%     
%     if isempty(temp4)==1
%         if mean(double(block4s(:,w)>SteadyState(1,w)-SteadyStateSTD(1,w)))>=.9
%             temp4=NaN;%temp4=0;
%         else
%             temp4=NaN;
%         end
%     elseif isempty(t4)==1 || max(t4)+1< numsteps
%         temp4=NaN;
%     else
%         t=find(diff([0; diff(ceil(temp4)); 0] == 1) == 1);
%         temp4(1)=ceil(temp4(t(find(t4==max(t4), 1, 'first'))));
%         clear t
%     end
%     old(1:4,w)=[temp1(1); temp2(1); temp3(1); temp4(1)];
%     forgetting(1:3,w)=[block1s(2,w)-block1s(1,w); block1s(3,w)-block1s(4,w); block1s(4,w)-block1s(3,w)]
%     clear temp1 temp2 temp3 temp4
% end
