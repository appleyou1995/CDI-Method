clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data    = fullfile(Path_MainFolder, 'Data');
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Path_Data_06 = fullfile(Path_MainFolder, 'Code', '06  輸出資料');
Path_Data_07 = fullfile(Path_MainFolder, 'Code', '07  輸出資料');


%% Load Data: Target_Date

Target_Date_Exdate = readtable(fullfile(Path_Data, 'Target_AllDate.csv'));
Target_Date = Target_Date_Exdate.date;
clear Target_Date_Exdate


%% Load Data: max_gross_return_y & PDF = g_hat * RND (align Smooth_RND with max_gross_return_y)

% (1) Import max_gross_return_y

Smooth_AllR = [];
years_to_merge = 1996:2021;

for year = years_to_merge    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));    
    data = load(input_filename);
    Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];    
end

max_gross_return_y = Smooth_AllR{1, '20200318'};                           % max gross return month: 20200318
clear input_filename data year years_to_merge Smooth_AllR


% (2) Import PDF = g_hat * RND (align Smooth_RND with max_gross_return_y)

load(fullfile(Path_Data_06, 'b_4_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_6_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_8_AllR_PDF.mat')');

AllR_PD_Tables = {b_4_AllR_PDF, b_6_AllR_PDF, b_8_AllR_PDF};
b_values = [4, 6, 8];


%% Load Data: EGARCH PDF & Calculate CDF value

EGARCH_PDF_Files = dir(fullfile(Path_Data_07, '*_EGARCH_PDF.mat'));

EGARCH_PDF_X = [];
EGARCH_PDF_Values = [];
EGARCH_CDF_Values = [];

for k = 1:length(EGARCH_PDF_Files)
    
    FileName = fullfile(Path_Data_07, EGARCH_PDF_Files(k).name);
    Data = load(FileName);

    FieldName = fieldnames(Data);
    Year_Data = Data.(FieldName{1});

    EGARCH_PDF_X = [EGARCH_PDF_X; Year_Data.X];
    EGARCH_PDF_Values = [EGARCH_PDF_Values; Year_Data.Values];

    % Calculate CDF value
    numMonths = size(Year_Data.Values, 1);
    EGARCH_CDF_Month = zeros(size(Year_Data.Values));

    for i = 1:numMonths
        EGARCH_CDF_Month(i, :) = cumtrapz(Year_Data.X(i, :), Year_Data.Values(i, :));
    end

    EGARCH_CDF_Values = [EGARCH_CDF_Values; EGARCH_CDF_Month];

end

clear k Data FieldName Year_Data EGARCH_PDF_Files EGARCH_CDF_Month


%%  Distortion Function

function D = Distortion(F, beta, alpha)

    D = exp(-((-beta * log(F)).^alpha));

end


%% 


