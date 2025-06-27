clear; clc;
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

Target_TTM = 30;

Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));

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

clear FileName year


%% Define knots

Aggregate_Smooth_AllR = Smooth_AllR.Variables;
min_knot = min(Aggregate_Smooth_AllR);
max_knot = 3;


%% Add paths

Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - Split-Sample Estimation');
addpath(Path_Data_03);

Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - Split-Sample Estimation');


%% Grid search on alpha

alphas = 0.5:0.1:2.0;
beta = 1;

n_months = size(Smooth_AllR, 2);
idx_split = floor(n_months / 2);

Smooth_AllR_train = Smooth_AllR(:, 1:idx_split);
Smooth_AllR_RND_train = Smooth_AllR_RND(:, 1:idx_split);
Realized_Return_train = Realized_Return(1:idx_split, :);

Smooth_AllR_valid = Smooth_AllR(:, idx_split+1:end);
Smooth_AllR_RND_valid = Smooth_AllR_RND(:, idx_split+1:end);
Realized_Return_valid = Realized_Return(idx_split+1:end, :);


%% Step 1

for b = [4, 6, 8]
    all_theta = cell(length(alphas), 1);
    validation_loss = zeros(length(alphas), 1);

    for i = 1:length(alphas)
        alpha = alphas(i);
        fprintf('--- Estimating: b = %d, alpha = %.1f ---\n', b, alpha);

        % Estimate theta for this alpha
        theta_hat = GMM_theta_estimation_fixed_alpha_beta(...
            Smooth_AllR_train, Smooth_AllR_RND_train, Realized_Return_train,...
            b, min_knot, max_knot, alpha, beta);

        all_theta{i} = theta_hat;
        disp(['b = ' num2str(b) '  Estimated parameters:']);
        disp(theta_hat);
    
        save_filename = ['theta_hat (b=' num2str(b) '_alpha=' num2str(alpha) ').mat'];
        save(fullfile(Path_Output, save_filename), 'theta_hat');

        % % Evaluate validation loss
        % params = [theta_hat, alpha, beta];
        % g_valid = GMM_moment_conditions(params, ...
        %     Smooth_AllR_valid, Smooth_AllR_RND_valid, Realized_Return_valid, ...
        %     b, min_knot, max_knot);
        % 
        % validation_loss(i) = g_valid' * eye(length(g_valid)) * g_valid;
        % 
        % fprintf('b = %d, alpha = %.1f, validation loss = %.4f\n', b, alpha, validation_loss(i));
    end

    % % Find the best alpha
    % [~, best_idx] = min(validation_loss);
    % alpha_star = alphas(best_idx);
    % theta_star = all_theta{best_idx};
    % 
    % disp(['==== Best Result for b = ' num2str(b) ' ====']);
    % disp(['Best alpha = ' num2str(alpha_star)]);
    % disp('Estimated theta:');
    % disp(theta_star);
    % 
    % % Save result
    % save_filename = sprintf('TTM_%d_theta_hat_split (b=%d).mat', Target_TTM, b);
    % save(fullfile(Path_Output, save_filename), ...
    %     'theta_star', 'alpha_star', 'all_theta', 'alphas', 'validation_loss');
end