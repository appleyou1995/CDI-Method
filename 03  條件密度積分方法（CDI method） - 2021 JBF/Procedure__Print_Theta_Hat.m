clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF', 'non-negative theta');


%% Estimated theta: floor

mat_files = dir(fullfile(Path_Data_03, 'floor_theta_hat (b=*.mat'));
all_theta_hat = {};

max_length = 0;
for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    max_length = max(max_length, length(theta_hat));
end

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    
    padded_theta_hat = NaN(1, max_length);
    padded_theta_hat(1:length(theta_hat)) = theta_hat;
    all_theta_hat{k} = padded_theta_hat;

    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    
    % Print b value and theta_hat in one line
    fprintf('[floor][b = %s] ', b_value);
    fprintf('%g ', theta_hat);
    fprintf('\n');
end

theta_hat_matrix_floor = cell2mat(all_theta_hat');


%% Estimated theta: ceil

mat_files = dir(fullfile(Path_Data_03, 'ceil_theta_hat (b=*.mat'));
all_theta_hat = {};

max_length = 0;
for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    max_length = max(max_length, length(theta_hat));
end

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    
    padded_theta_hat = NaN(1, max_length);
    padded_theta_hat(1:length(theta_hat)) = theta_hat;
    all_theta_hat{k} = padded_theta_hat;
    
    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    
    % Print b value and theta_hat in one line
    fprintf(' [ceil][b = %s] ', b_value);
    fprintf('%g ', theta_hat);
    fprintf('\n');
end

theta_hat_matrix_ceil = cell2mat(all_theta_hat');