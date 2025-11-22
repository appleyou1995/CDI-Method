clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 30;

Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName

Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料 - no dividend');
Smooth_AllK = [];
Smooth_AllR = [];
Smooth_AllR_RND = [];

years_to_merge = 1996:2021;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data_02, sprintf('TTM_%d_RND_Tables_%d.mat', Target_TTM, year));
        
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


%% Define the knots for the B-spline

Aggregate_Smooth_AllR = Smooth_AllR.Variables;
ret_size = size(Smooth_AllK, 2);

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = 3;

clear Aggregate_Smooth_AllR


%% Estimate theta

Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - 2021 JBF (spcol)');
addpath(Path_Data_03);

Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF - no dividend');

for b = [4, 6, 8]
    theta_hat = GMM_theta_estimation(Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot);
    
    disp(['b = ' num2str(b) '  Estimated parameters:']);
    disp(theta_hat);
    
    save_filename = ['TTM_' num2str(Target_TTM) '_theta_hat (b=' num2str(b) ').mat'];
    save(fullfile(Path_Output, save_filename), 'theta_hat');
end
