clear; clc


%% Setting

warning('off', 'all');

% Specific Time-to-Maturity (LB)
Target_TTM = 29;


%% Load Data

Target_Date_Exdate = readtable('D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Data\Target_AllDate.csv');
Target_AllDate = Target_Date_Exdate.date;

% Dividend Yield  [1. SecID | 2. Date (YYYYMMDD) | 3. Dividend Yield (Annualized)]
FileName = ['IndexDivYield19962019.txt'];
Data_DY = load(['D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Data\99 姿穎學姊提供\20240417\' FileName]);
clear FileName

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
FileName = ['RiskFreeRate19962019.txt'];
Data_RF = load(['D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Data\99 姿穎學姊提供\20240417\' FileName]);
clear FileName


%% Generate All RND

Table_Smooth_AllK = table();
Table_Smooth_RND = table();

tic;

for i = 1:3 % length(Target_AllDate)

    Target_Date = Target_AllDate(i);
    disp(['Processing date: ', num2str(Target_Date)]);

    FileName = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
    Data = load(['D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Data\99 姿穎學姊提供\20240417\IndexOptions19962019_SP500\' FileName]);
    clear FileName

    [Smooth_AllK, Smooth_RND] = RND(Data, Data_DY, Data_RF, Target_Date, Target_TTM);

    columnName = num2str(Target_Date);
    Table_Smooth_AllK.(columnName) = Smooth_AllK;
    Table_Smooth_RND.(columnName) = Smooth_RND;

end

elapsed_time = toc;
disp(['Spend Time：', num2str(elapsed_time), ' Seconds']);

%%  Read data in the table

tttTable = Table_Smooth_AllK{1, '19960717'};
disp(tttTable);

