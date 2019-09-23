classdef paramData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties %(SetAccess=private)
        labels={''};
        Data;       
        indsInTrial={};
        trialTypes={};
    end
    properties(Dependent)
        %could include things here like 'learning' or 'transfer'...
    end
    
    %%
    methods
        
        %Constructor:
        function this=paramData(data,labels,inds,types)
            if (length(labels)==size(data,2)) && isa(labels,'cell')
                this.labels=labels;
                this.Data=data;
            else
                ME=MException('paramData:ConstructorInconsistentArguments','The size of the labels array is inconsistent with the data being provided.');
                throw(ME)
            end
            if nargin>2 && isa(inds,'cell')
                this.indsInTrial=inds;
            else
                ME=MException('paramData:Constructor','Check that trial indices are entered correctly.');
                throw(ME)
            end
            if nargin>3 && isa(types,'cell')
                this.trialTypes=types;            
            end
        end
        
        %-------------------
        
        %Other I/O functions:
        function [data,auxLabel]=getParameter(this,label)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end            
            [boolFlag,labelIdx]=this.isaParameter(auxLabel);                      
            data=this.Data(:,labelIdx(boolFlag==1));
            auxLabel=this.labels(labelIdx(boolFlag==1));
        end        
        
        function [boolFlag,labelIdx]=isaParameter(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            end            
            N=length(auxLabel);
            boolFlag=zeros(1,N);
            labelIdx=zeros(1,N);
            for j=1:N
                for i=1:length(this.labels)
                     if strcmp(lower(auxLabel{j}),lower(this.labels{i}))
                       boolFlag(j)=true;
                       labelIdx(j)=i;
                       break;
                     end
                end
            end
             for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a parameter in this dataset.'])
                end
            end 
        end          
        
    end    
        
end

