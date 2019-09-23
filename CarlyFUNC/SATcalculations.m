%SATcalculations

cd('/Users/carlysombric/Desktop/OG Paper')


% Will need to do the following for a subset of subjects

% Will need to somehow sort people into different groups

% Will need to somehow store this data in some way to interface with the
% cog corrleaiton function


[num,txt,raw] =xlsread('BetterShiftingAttention.xlsx');

%Start by removing the colum heading rows
raw(1, :)=[];
txt(1, :)=[];
num=[ones(1, 9); num]; %To make eveyrthing the sam dimentions

%need to remove every other row since it is blank anyway
[r, c]=size(num);
d = 2; % rows in each data set 
n = 2;  % remove first n rows in each data set
raw(mod(1:r,d)<=n & mod(1:r,d)>0,:) = [];
txt(mod(1:r,d)<=n & mod(1:r,d)>0,:) = [];
num(mod(1:r,d)<=n & mod(1:r,d)>0,:) = [];

%Need to split the data up into different subjects, don't need to worry
%about the groups now.  Output =cells with subs and underlying data
[r, c]=size(num);

%Start off with first subject
eval(['SATdataALL.' raw{1,1} '=[num(1, 2) txt(1, 3:7) num(1, 8) num(1, 9)];']);

for w=2:r
    if strcmp(raw{w-1, 1}, raw{w, 1}) || isequal(raw{w-1, 1}, raw{w, 1}) && w~=2 %Same subjectmean(raw{w-1, 1}==raw{w, 1})==1 %
        %SATdataALL{1,1}(:)=[SATdataALL{1,1}(:); num(w, 2) txt(w, 3:7) num(w, 8:9)];
       % eval(['SATdataALL.' raw{w,1} '=[SATdataALL.' raw{w,1} '; num(w, 2) txt(w, 3:7) num(w, 8:9)]']);
        
        if isnumeric(raw{w,1})
            eval(['SATdataALL.OG' num2str(raw{w,1}) '=[SATdataALL.OG' num2str(raw{w,1}) '(:,:) ; num(w, 2) txt(w, 3:7) num(w, 8) num(w, 9)]']);
        else
            eval(['SATdataALL.' raw{w,1} '=[SATdataALL.' raw{w,1} ';num(w, 2) txt(w, 3:7) num(w, 8) num(w, 9)]']);
        end
    else %New Subject
        %         SATdataALL{1,1}=raw(w-1, 1);%Make them a header in my cell
        %         SATdataALL{1,1}(1,:)=[num(w, 2) txt(w, 3:7) num(w, 8:9)];%Put their first row of data in my cell
        if isnumeric(raw{w,1})
            eval(['SATdataALL.OG' num2str(raw{w,1}) '=[num(w, 2) txt(w, 3:7) num(w, 8) num(w, 9)]']);
        else
            eval(['SATdataALL.' raw{w,1} '=[num(w, 2) txt(w, 3:7) num(w, 8) num(w, 9)]']);
        end
    end
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SATresults=[];

subs= (fields(SATdataALL));

%Little gerry rigging to get rid of OG12 first cog test, where he didn't
%walk on the treadmill that day...
subs(56)=[];

for q=1:length(subs)
    SwticthTrial(1)=0;
    Correct(1)=eval(['SATdataALL.' subs{q} '{1, 7}']);
    %Need to identify switch trials
    for i=2:eval(['length(SATdataALL.' subs{q} ')'])
        if strcmp(eval(['SATdataALL.' subs{q} '(i-1, 3)']), eval(['SATdataALL.' subs{q} '(i, 3)']))==1% Same trial
            SwticthTrial(i)=0;
        else %The trial type has switched
            SwticthTrial(i)=1;
        end
        
        %Need to identify correct answers
        Correct(i)=eval(['SATdataALL.' subs{q} '{i, 7}']);
    end

    %Need to calculate Accuracy
    correctSwitch=length(find((SwticthTrial+Correct)==2));
    numSwitch=length(find(SwticthTrial==1));
    
    correctSame=length(find((SwticthTrial-Correct)==-1));
    numSame=length(find(SwticthTrial==0));
    
    Accuracy_Switch= correctSwitch/numSwitch;
    Accuracy_Same= correctSame/numSame;
    Accuracy_Diff=Accuracy_Same-Accuracy_Switch;
    
    %Need to calculate speed
    speed_Switch=mean(num(find((SwticthTrial+Correct)==2), 8)); %Average speed of correct trial when the rule has switched
    speed_Same=mean(num(find((SwticthTrial-Correct)==-1), 8));
    speed_Diff=speed_Same-speed_Switch;
    
    if isempty(regexp(subs{q}(3:end),'B'))==0 
        WhoIS=eval(['2' (subs{q}(3:end-1))]); 
        SATresults=[SATresults; WhoIS ...
         Accuracy_Switch Accuracy_Same Accuracy_Diff...
         speed_Switch speed_Same speed_Diff]; 
    elseif  isempty(regexp(subs{q}(3:end),'A'))==0
        WhoIS=eval([(subs{q}(3:end-1))]); 
        SATresults=[SATresults; WhoIS ...
         Accuracy_Switch Accuracy_Same Accuracy_Diff...
         speed_Switch speed_Same speed_Diff]; 
    else
            SATresults=[SATresults; str2num(subs{q}(3:end)) ...
         Accuracy_Switch Accuracy_Same Accuracy_Diff...
         speed_Switch speed_Same speed_Diff];
    end
    
    clear SwticthTrial Correct

    
    %person Accuracy_Switch Accuracy_Same Accuracy_Diff speed_Switch speed_Same speed_Diff

end


