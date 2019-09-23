classdef experimentData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        data %cell array of labData type (or its subclasses: rawLabData, processedLabData, strideData)
    end
    
    properties (Dependent)
        isRaw
        isProcessed
        isStepped %or strided
        %isTimeNormalized %true if all elements in data share the same timeVector (equal sampling, not just range) 
        fastLeg
    end
    
    methods
        %Constructor
        function this=experimentData(meta,sub,data)

           if nargin>0 && isa(meta,'experimentMetaData')
               this.metaData=meta;
           else
               ME=MException('experimentData:Constructor','Experiment metaData is not an experimentMetaData type object.');
               throw(ME);
           end
           
           if nargin>1 && isa(sub,'subjectData')
               this.subData=sub;
           else
               ME=MException('experimentData:Constructor','Subject data is not a subjectData type object.');
               throw(ME);
           end
           
           if nargin>2 && isa(data,'cell')  % Has to be array of labData type cells. 
               aux=cellfun('isempty',data);
               aux2=find(~aux,1);
               if ~isempty(aux2) && isa(data{aux2},'labData') %This should be changed to test that ALL cells contain labData objects, instead of just the first non-empty one.
                    this.data=data;
               else
                   ME=MException('experimentData:Constructor','Data is not a cell array of labData (or one of its subclasses) objects.');
                   throw(ME);
               end
           else
               ME=MException('experimentData:Constructor','Data is not a cell array.');
               throw(ME);
           end
        end
        
        %Getters for Dependent properties
        function a=get.isProcessed(this)
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1,1); %Not empty
            a=isa(this.data{idx},'processedLabData');
        end
        
        function a=get.isStepped(this)
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1,1);
            a=isa(this.data{idx},'strideData');
        end
        
        function a=get.isRaw(this)
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1,1);
            a=isa(this.data{idx},'rawLabData');
        end
        
        function fastLeg=get.fastLeg(this)
            vR=[];
            vL=[];
            for trial=1:length(this.data)
                if ~this.isStepped
                    if ~isempty(this.data{trial}.beltSpeedReadData)
                        vR(end+1)=nanmean(this.data{trial}.beltSpeedReadData.getDataAsVector('R'));
                        vL(end+1)=nanmean(this.data{trial}.beltSpeedReadData.getDataAsVector('L'));
                    end
                else %Stepped trial
                    for step=1:length(this.data{trial})
                        if ~isempty(this.data{trial}{step}.beltSpeedReadData)
                            vR(end+1)=nanmean(this.data{trial}{step}.beltSpeedReadData.getDataAsVector('R'));
                            vL(end+1)=nanmean(this.data{trial}{step}.beltSpeedReadData.getDataAsVector('L'));
                        end
                    end
                end
            end
            if mean(vR)<mean(vL)
                fastLeg='L';
            else
                fastLeg='R'; %Defaults to this, even if there is no beltSpeedData
            end
        end
        
        %Process full experiment
        function processedThis=process(this)
            for trial=1:length(this.data)
                disp(['Processing trial ' num2str(trial) '...'])
                if ~isempty(this.data{trial})
                    procData{trial}=this.data{trial}.process;
                else
                   procData{trial}=[];
                end
            end
            processedThis=experimentData(this.metaData,this.subData,procData);
        end
        
        %function to make adaptationData object
        function adaptData=makeDataObj(this,filename)
            DATA=[];
            DATA2=[];
            startind=1;
            if ~isempty(this.data)
                for i=1:length(this.data)
                    if ~isempty(this.data{i}) && ~isempty(this.data{i}.adaptParams)
                        labels=this.data{i}.adaptParams.getLabels;
                        dataTS=this.data{i}.adaptParams.getDataAsVector(labels);
                        aux=this.data{i}.experimentalParams;
                        labels2=aux.getLabels;
                        dataTS2=aux.getDataAsVector(labels2);
                        DATA=[DATA; dataTS(this.data{i}.adaptParams.getDataAsVector('good')==true,:)];
                        DATA2=[DATA2; dataTS2(this.data{i}.adaptParams.getDataAsVector('good')==true,:)];
                        indsInTrial{i}= startind:size(DATA,1);
                        startind=size(DATA,1)+1;
                        trialTypes{i}=this.data{i}.metaData.type;
                    end
                end
            end    
            %labels should be the same for all trials with adaptParams
            parameterData=paramData([DATA, DATA2],[labels labels2],indsInTrial,trialTypes);
            adaptData=adaptationData(this.metaData,this.subData,parameterData);  
            if nargin>1 && ~isempty(filename)
                save([filename '.mat'],'adaptData');
            end
        end
        
        function stridedExp=splitIntoStrides(this,refEvent)
            
            if ~this.isStepped && this.isProcessed
                for trial=1:length(this.data)
                    disp(['Splitting trial ' num2str(trial) '...'])
                    trialData=this.data{trial};
                    if ~isempty(trialData)
                        if nargin<2 || isempty(refEvent)
                            refEvent=[trialData.metaData.refLeg,'HS'];
                            %Assuming that the first event of each stride should be
                            %the heel strike of the refLeg! (check c3d2mat -
                            %refleg should be opposite the dominant/fast leg)
                        end
                        aux=trialData.separateIntoStrides(refEvent);
                        strides{trial}=aux;                        
                    else
                        strides{trial}=[];                        
                    end
                end
                stridedExp=stridedExperimentData(this.metaData,this.subData,strides); 
            else
                disp('Cannot stride experiment because it is raw or already strided.');
            end
        end

        function [h,adaptDataObject]=parameterEvolutionPlot(this,field,h)
%             %Check that the field actually exists in the all of
%             %data{i}.adaptParams or experimentalParams
              adaptDataObject=this.makeDataObj; %Creating adaptationData object, to include experimentalParams (which are Dependent and need to be computed each time). Otherwise we could just access this.data{trial}.experimentalParams
              h=adaptDataObject.plotParamByConditions(field);
%             colors={[0,0,0],[1,0,0],[1,1,0],[0,1,0],[0,1,1],[0,0,1],[1,0,1]};
%             
%             %Do the plot
%             if nargin>2 && ~isempty(h)
%                 figure(h)
%             else
%                 h=figure;
%             end
%             hold on
%             counter=0;
%             for condition=1:length(this.metaData.trialsInCondition)
%                for trial=this.metaData.trialsInCondition{condition}
%                    plotData=this.data{trial}.adaptParams.getDataAsVector(field);
%                    if size(plotData,2)~=length(field)
%                        plotData=[plotData, this.data{trial}.experimentalParams.getDataAsVector(field)];
%                    end
%                    plotData=plotData(~isnan(plotData));
%                    newCounter=counter+length(plotData);
%                    plot(counter+1:newCounter,plotData,'o','LineWidth',2,'Color',colors{mod(condition-1,length(colors))+1})
%                    counter=newCounter;
%                end
%             end
%             hold off
        end
        
        function this=recomputeParameters(this)
            trials=cell2mat(this.metaData.trialsInCondition);
            for t=trials
                  this.data{t}.adaptParams=calcParameters(this.data{t}); 
            end
        end
        
    end
    
end

