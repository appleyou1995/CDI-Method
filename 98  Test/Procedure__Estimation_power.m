clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  原始資料處理');
Realized_Return = readtable(fullfile(Path_Data_01, 'Realized_Return.csv'));
Risk_Free_Rate = readtable(fullfile(Path_Data_01, 'Risk_Free_Rate.csv'));
RF = Risk_Free_Rate{:, 3};

Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllK = [];
Smooth_AllR = [];
Smooth_AllR_RND = [];

years_to_merge = 1996:2021;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));
        
    if exist(input_filename, 'file')
        data = load(input_filename);
        
        Smooth_AllK = [Smooth_AllK, data.Table_Smooth_AllK];
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
        Smooth_AllR_RND = [Smooth_AllR_RND, data.Table_Smooth_AllR_RND];
    else
        warning('File %s does not exist.', input_filename);
    end
end

clear input_filename year years_to_merge


%% Estimate parameters

Path_Data_98 = fullfile(Path_MainFolder, 'Code', '98  Test');
addpath(Path_Data_98);

Path_Output = fullfile(Path_MainFolder, 'Code', '98  輸出資料');

params_hat = GMM_power(Smooth_AllR, Smooth_AllR_RND, Realized_Return, RF);

disp('Estimated parameters:');
disp(params_hat);

save_filename = 'params_hat_power.mat';
save(fullfile(Path_Output, save_filename), 'params_hat');

