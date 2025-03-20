clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_09 = fullfile(Path_MainFolder, 'Code', '09  輸出資料');


%% Get List of Parameter Files

mat_files = dir(fullfile(Path_Data_09, 'params_hat (b=*.mat'));
all_params_hat = {};

max_length = 0;


%% Find Maximum Parameter Length

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_09, mat_files(k).name);
    load(file_path, 'params_hat');
    max_length = max(max_length, length(params_hat));
end


%% Load and Pad Parameter Vectors

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_09, mat_files(k).name);
    load(file_path, 'params_hat');
    
    padded_theta_hat = NaN(1, max_length);
    padded_theta_hat(1:length(params_hat)) = params_hat;
    all_params_hat{k} = padded_theta_hat;
    
    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    
    % Print b value and theta_hat in one line
    fprintf('[b = %s] ', b_value);
    fprintf('%g ', params_hat);
    fprintf('\n');
end


%% Convert to Matrix Format

params_hat_matrix = cell2mat(all_params_hat');