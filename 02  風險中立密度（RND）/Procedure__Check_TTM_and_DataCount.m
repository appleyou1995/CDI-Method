clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data     = fullfile(Path_MainFolder, 'Data');
Path_Data_inc = fullfile(Path_MainFolder, 'Data', 'IndexOptions19962022_SP500');
Path_Data_01  = fullfile(Path_MainFolder, 'Code', '01  輸出資料');


%% Specific Time-to-Maturity

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 30;

FileName = ['Hsieh_TTM_', num2str(Target_TTM), '.csv'];
Target_Date_Exdate = readtable(fullfile(Path_Data_01, FileName));
Target_AllDate = Target_Date_Exdate.date;

years = unique(floor(Target_AllDate / 10000));

clear FileName


%% 

clc

Summary_Table = table();

for y = 1:length(years)

    year = years(y);
    disp(['Processing year: ', num2str(year)]);
    
    month_in_year = Target_AllDate(floor(Target_AllDate / 10000) == year);
    
    for i = 1:length(month_in_year)

        TTM = Target_TTM - 4;

        Target_Date = month_in_year(i);
        
        FileName = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
        Data_inc = load(fullfile(Path_Data_inc, FileName));
        clear FileName

        Index_Date = 2;
        Index_TTM = 3;

        TTM_Candidates = Data_inc(Data_inc(:, Index_Date) == Target_Date, Index_TTM);        
        TTM_Min = min(TTM_Candidates(TTM_Candidates >= TTM));
        Data = Data_inc(Data_inc(:, Index_Date) == Target_Date & Data_inc(:, Index_TTM) == TTM_Min, :);

        Summary_Table = [Summary_Table;
                         table(Target_Date, TTM_Min, height(Data))];

        disp([' Date: ', num2str(Target_Date), ...
              '  TTM: ', num2str(TTM_Min), ...
              '  Num: ', num2str(height(Data))]);
    end
    
end