clear; clc

warning('off', 'all');

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data     = fullfile(Path_MainFolder, 'Data');
Path_Data_inc = fullfile(Path_MainFolder, 'Data', 'IndexOptions19962022_SP500');
Path_Data_01  = fullfile(Path_MainFolder, 'Code', '01  輸出資料');


%% Specific Time-to-Maturity

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 90;

FileName = ['Hsieh_TTM_', num2str(Target_TTM), '.csv'];
Target_Date_Exdate = readtable(fullfile(Path_Data_01, FileName));
Target_AllDate = Target_Date_Exdate.date;

clear FileName


%% Load Data

% Dividend Yield  [1. SecID | 2. Date (YYYYMMDD) | 3. Dividend Yield (Annualized)]
FileName = 'IndexDivYield19962022.txt';
Data_DY = load(fullfile(Path_Data, FileName));
clear FileName

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
FileName = 'RiskFreeRate19962022.txt';
Data_RF = load(fullfile(Path_Data, FileName));
clear FileName


%% Set up years and paths

years = unique(floor(Target_AllDate / 10000));

Path_Output  = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  風險中立密度（RND）');
addpath(Path_Data_02);


%% Main loop: Process each year

for y = 1:length(years)

    year = years(y);
    disp(['Processing year: ', num2str(year)]);
    
    Table_Smooth_AllK = table();
    Table_Smooth_AllR = table();
    Table_Smooth_AllR_RND = table();
    
    month_in_year = Target_AllDate(floor(Target_AllDate / 10000) == year);
    
    for i = 1:length(month_in_year)

        tic;
        
        TTM = Target_TTM - 4;

        Target_Date = month_in_year(i);
        disp(['Processing date: ', num2str(Target_Date)]);
        
        FileName = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
        Data_inc = load(fullfile(Path_Data_inc, FileName));
        clear FileName

        Index_Date = 2;
        Index_TTM = 3;
        
        % Find the options data with the nearest TTM to the target TTM for the given Target_Date
        TTM_Candidates = Data_inc(Data_inc(:, Index_Date) == Target_Date, Index_TTM);        
        TTM_Min = min(TTM_Candidates(TTM_Candidates >= TTM));
        Data = Data_inc(Data_inc(:, Index_Date) == Target_Date & Data_inc(:, Index_TTM) == TTM_Min, :);
        
        % Calculate RND
        [Smooth_AllK, Smooth_AllR, Smooth_AllR_RND] = Calculate_RND(Data, Data_DY, Data_RF, Target_Date);
        
        columnName = num2str(Target_Date);
        Table_Smooth_AllK.(columnName) = Smooth_AllK;
        Table_Smooth_AllR.(columnName) = Smooth_AllR;
        Table_Smooth_AllR_RND.(columnName) = Smooth_AllR_RND;

        elapsed_time = toc;
        disp(['     Spend Time: ', num2str(elapsed_time), ' Seconds']);
    end
    
    % Save
    output_filename = fullfile(Path_Output, ['TTM_', num2str(Target_TTM), '_RND_Tables_', num2str(year), '.mat']);
    save(output_filename, 'Table_Smooth_AllK', 'Table_Smooth_AllR', 'Table_Smooth_AllR_RND');
    
end