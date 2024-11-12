clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');


%% Estimated theta: floor

mat_files = dir(fullfile(Path_Data_03, 'floor_theta_hat (b=*.mat'));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    
    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    
    % Print b value and theta_hat in one line
    fprintf('[floor][b = %s] ', b_value);
    fprintf('%g ', theta_hat);
    fprintf('\n');
end


%% Estimated theta: ceil

mat_files = dir(fullfile(Path_Data_03, 'ceil_theta_hat (b=*.mat'));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    
    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    
    % Print b value and theta_hat in one line
    fprintf(' [ceil][b = %s] ', b_value);
    fprintf('%g ', theta_hat);
    fprintf('\n');
end