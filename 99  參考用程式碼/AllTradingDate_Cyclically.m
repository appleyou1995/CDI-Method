%*************************************************************************%
% Line 69: Be Careful when Setting the Days in A Month.
%*************************************************************************%
clear; clc

% Specific Time-to-Maturity (Calendar Days) 
% Target_AllTTM = 30;
% Target_AllTTM = 60;
Target_AllTTM = 90;
% Target_AllTTM = 180;
% Target_AllTTM = 360;                                                       

% Data Period
Year_Begin = 1996;
Year_End = 2022;

%% Setting
% WRDS Data
RootName_WRDS = ['D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Data\IndexOptions19962022_SP500\'];

%% Maturity of Standard SPX Options
Target_AllExDate = nan(12 * ((Year_End + 2) - Year_Begin + 1), 1);         % Construct Space

for y = Year_Begin:(Year_End + 2)
    for m = 1:12
        % General Case (Third Friday)
        FRI = nweekdate(3, 6, y, m);                                       

        % Special Case (Third Friday - 1)
        if ((y==2019) & (m==4)) | ((y==2022) & (m==4))
            FRI = FRI - 1;                                                 
        else
        end
        
        % Record
        Target_AllExDate(12 * (y - Year_Begin) + m, 1) = FRI;              % Based on Date Number 
        clear FRI
    end
end
clear y m

%% Selecting Target Date
Target_AllDate = nan(12 * (Year_End - Year_Begin + 1), 3);                 % Construct Space
Record_NUMData = nan(12 * (Year_End - Year_Begin + 1), 1);                 % Construct Space

for y = Year_Begin:Year_End
    for m = 1:12
        [y m] 
        
        % Load Data
        FileName = ['OP' num2str(y) '_' num2str(m) '.txt'];
        Data = load([RootName_WRDS FileName]);   
        clear FileName
        
        % Index of Data
        Index_ID = 1;
        Index_Date = 2;
        Index_TTM = 3;

        %*****************************************************************%
        % Correct Expiration Date: Saturday to Friday
        Date_EXP_WeekDay = weekday(datenum(num2str(Data(:, Index_Date)), 'yyyymmdd') ...
                                   + Data(:, Index_TTM));      
        Data(Date_EXP_WeekDay==7, Index_TTM) = Data(Date_EXP_WeekDay==7, Index_TTM) - 1;   % Update: Data    
        clear Date_EXP_WeekDay        
        
        %*****************************************************************%        
        % Find Target Expiration Date
        MM = m + fix(Target_AllTTM / 28);
        if MM <= 12
            YYYY = y;
        else
            YYYY = y + max(MM - m, 12) / 12;
            MM = rem(MM, 12);                                              % Update: MM
            
            if MM==0
                MM = 12;                                                   % Update: MM
            else
            end            
        end
                
        Index = find((year(Target_AllExDate)==YYYY) & ...
                     (month(Target_AllExDate)==MM));       
        Target_ExDate = Target_AllExDate(Index);
        Target_ExDate = str2num(datestr(Target_ExDate, 'yyyymmdd'));       % Update: Target_ExDate (Date Number to Date)
        clear Index YYYY MM
        
        %*****************************************************************%        
        % Find the Closest Target Date (Given the Target Expiration Date)
        AllDate = Data(:, Index_Date);
        AllDate_TTM = Data(:, Index_TTM);
        
        AllDate_ExDate = datenum(num2str(AllDate), 'yyyymmdd') + AllDate_TTM;
        AllDate_ExDate = str2num(datestr(AllDate_ExDate, 'yyyymmdd'));     % Update: AllDate_ExDate (Date Number to Date)

        % Choose the Closest to 'Target_AllTTM' 
        Index = find(AllDate_ExDate==Target_ExDate);
        if length(Index) > 0
            DIFF = AllDate_TTM(Index) - Target_AllTTM;                     % Days
        
            [~, Index_Min] = min(abs(DIFF));
            Target_Date = AllDate(Index(Index_Min));
            clear Index_Min DIFF
            
            % Record
            TTM = datenum(num2str(Target_ExDate), 'yyyymmdd') - datenum(num2str(Target_Date), 'yyyymmdd');
            Target_AllDate(12 * (y - Year_Begin) + m, :) = [Target_Date Target_ExDate TTM];   
            clear TTM
            
            % Record
            Index = find((AllDate==Target_Date) & ...
                         (AllDate_ExDate==Target_ExDate));                 % Update: Index
            Record_NUMData(12 * (y - Year_Begin) + m, 1) = length(Index);
            clear Target_Date 
        else
        end
        clear Index Target_ExDate

        % Clear Variable
        clear AllDate AllDate_ExDate AllDate_TTM
        clear Data Index_ID Index_Date Index_TTM
    end
end
clear Target_AllExDate
clear y m

% % Drop NaN
% Index_Drop = find(sum(isnan(Target_AllDate), 2) > 0);
% Target_AllDate(Index_Drop, :) = [];                                        % Update: Target_AllDate
% clear Index_Drop

%% Output
FileName = ['AllTradingDate' num2str(Year_Begin) num2str(Year_End) '_Cyclically'];
save(FileName, ...
     'Target_AllDate', ...
     'Record_NUMData');
clear FileName

% Clear Variable
clear Year_Begin Year_End 
clear RootName_WRDS
