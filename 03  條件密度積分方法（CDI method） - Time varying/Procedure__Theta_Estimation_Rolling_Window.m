clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 30;

Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName

Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
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


%% Rolling window settings

Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - Time varying');
addpath(Path_Data_03);

Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - Time varying');

window_size = 60;
months = Smooth_AllR.Properties.VariableNames;
T = length(months);


%% Estimate theta

for t = window_size:T
    % Extract the current rolling window's month names
    current_window = months((t - window_size + 1):t);

    % Subset the tables for the current window
    window_Smooth_AllR = Smooth_AllR(:, current_window);
    window_Smooth_AllR_RND = Smooth_AllR_RND(:, current_window);
    window_Realized_Return = Realized_Return((t - window_size + 1):t, :);

    % Use the most recent month in the window as a tag
    rolling_tag = current_window{end};

    for b = [4, 6, 8]
        theta_hat = GMM_theta_estimation(...
            window_Smooth_AllR, window_Smooth_AllR_RND, ...
            window_Realized_Return, b, min_knot, max_knot);

        disp(['Month = ' rolling_tag '  b = ' num2str(b) '  Estimated theta:']);
        disp(theta_hat);

        save_filename = sprintf('Rolling_theta_TTM=%d_b=%d_%s.mat', Target_TTM, b, rolling_tag);
        save(fullfile(Path_Output, save_filename), 'theta_hat');
    end
end
