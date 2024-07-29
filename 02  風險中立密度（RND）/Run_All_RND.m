clear; clc


%% Setting

warning('off', 'all');

% Specific Time-to-Maturity (LB)
Target_TTM = 29;


%% Load Data

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data     = fullfile(Path_MainFolder, 'Data');
Path_Data_Sub = fullfile(Path_MainFolder, 'Data', '99 姿穎學姊提供', '20240417');

Target_Date_Exdate = readtable(fullfile(Path_Data, 'Target_AllDate.csv'));
Target_AllDate = Target_Date_Exdate.date;

% Dividend Yield  [1. SecID | 2. Date (YYYYMMDD) | 3. Dividend Yield (Annualized)]
FileName = 'IndexDivYield19962019.txt';
Data_DY = load(fullfile(Path_Data_Sub, FileName));
clear FileName

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
FileName = 'RiskFreeRate19962019.txt';
Data_RF = load(fullfile(Path_Data_Sub, FileName));
clear FileName


%% Generate All RND

years = unique(floor(Target_AllDate / 10000));
    
Path_Output = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Path_RND = fullfile(Path_MainFolder, 'Code', '02  風險中立密度（RND）');
addpath(Path_RND);

for y = 1:length(years)
    year = years(y);
    disp(['Processing year: ', num2str(year)]);
    
    Table_Smooth_AllK = table();
    Table_Smooth_AllR = table();
    Table_Smooth_AllR_RND = table();
    
    month_in_year = Target_AllDate(floor(Target_AllDate / 10000) == year);
    
    for i = 1:length(month_in_year)
        tic;
        
        Target_Date = month_in_year(i);
        disp(['Processing date: ', num2str(Target_Date)]);
        
        FileName = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
        Data = load(fullfile(Path_Data_Sub, 'IndexOptions19962019_SP500', FileName));
        clear FileName
        
        [Smooth_AllK, Smooth_AllR, Smooth_AllR_RND] = Calculate_RND(Data, Data_DY, Data_RF, Target_Date, Target_TTM);
        
        columnName = num2str(Target_Date);
        Table_Smooth_AllK.(columnName) = Smooth_AllK;
        Table_Smooth_AllR.(columnName) = Smooth_AllR;
        Table_Smooth_AllR_RND.(columnName) = Smooth_AllR_RND;
        
        elapsed_time = toc;
        disp(['     Spend Time: ', num2str(elapsed_time), ' Seconds']);
    end
    
    % Save
    output_filename = fullfile(Path_Output, ['Output_Tables_', num2str(year), '.mat']);
    save(output_filename, 'Table_Smooth_AllK', 'Table_Smooth_AllR', 'Table_Smooth_AllR_RND');
end

rmpath(Path_Output);


%%  Read data in the table

Table_AllR_19960117 = Table_Smooth_AllR{1, '19960117'};
disp(Table_AllR_19960117);