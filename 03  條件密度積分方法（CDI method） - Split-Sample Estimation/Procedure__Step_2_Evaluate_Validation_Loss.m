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

clear FileName year data input_filename year years_to_merge


%% Define knots

Aggregate_Smooth_AllR = Smooth_AllR.Variables;
min_knot = min(Aggregate_Smooth_AllR);
max_knot = 3;


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


%% Read the result of theta estimation

Path_Output = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method\Code\03  輸出資料 - Split-Sample Estimation';
files = dir(fullfile(Path_Output, '*.mat'));

theta_tables = struct();

for b = [4, 6, 8]
    theta_table = table();

    for i = 1:length(files)
        file = files(i).name;

        if contains(file, ['b=' num2str(b)])
            alpha_token = regexp(file, 'alpha=([\d.]+)', 'tokens', 'once');
            if isempty(alpha_token)
                continue;
            end
            alpha = str2double(alpha_token{1});

            data = load(fullfile(Path_Output, file), 'theta_hat');
            theta_hat = data.theta_hat;

            t = array2table(theta_hat, 'RowNames', {num2str(alpha)});
            theta_table = [theta_table; t];
        end
    end

    switch b
        case 4
            var_names = {'theta1', 'theta2', 'theta3', 'theta4', 'theta5'};
        case 6
            var_names = {'theta1', 'theta2', 'theta3', 'theta4', 'theta5', 'theta6', 'theta7'};
        case 8
            var_names = {'theta1', 'theta2', 'theta3', 'theta4', 'theta5', 'theta6', 'theta7', 'theta8', 'theta9'};
    end

    theta_table.Properties.VariableNames = var_names;
    theta_tables.(['b' num2str(b)]) = theta_table;
end

clear b theta_table theta_hat var_names alpha alpha_token t i file files data


%% Plot: Setting

% Specify the month to plot
t = 291;

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

TTM = 29 / 365;

current_month = months{t};

min_y = min(current_month_y_filtered);
max_y = 3;


%% 

x_start = 0.8;
x_end = 1.2;
fill_color = [0.9, 0.9, 0.9];

for b = [4, 6, 8]
    theta_table = theta_tables.(['b' num2str(b)]);
    all_alphas = str2double(theta_table.Properties.RowNames);
    
    y_min = -0.2;
    y_max = 3;
    figure;
    hold on;

    % basis functions
    y_BS = nan(b + 1, length(current_month_y));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
    end

    colors = lines(height(theta_table));
    for i = 1:height(theta_table)
        theta = table2array(theta_table(i, :));
        theta_col = theta(:);
        g_value = theta_col' * y_BS;
        plot(current_month_y, g_value, 'LineWidth', 1.5, 'Color', colors(i, :));
        y_max = max(y_max, max(g_value));
    end

    x_vals = [x_start, x_end];
    for j = 1:length(x_vals)
        plot([x_vals(j), x_vals(j)], [y_min, 1.2 * y_max], '--', 'LineWidth', 0.8, 'Color', [0.5 0.5 0.5]);
    end
    fill([x_start x_end x_end x_start], ...
         [y_min y_min y_max y_max], ...
         fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    title(['Cubic B-Spline with g function for b = ', num2str(b)]);
    xlabel('y');
    ylabel('g(y)');
    ylim([y_min, 8]);
    xlim([0, 3]);
    grid on;

    legendLabels = strcat('\alpha = ', string(all_alphas));
    legend(legendLabels, 'Location', 'northeastoutside', 'Box', 'off');

    % filename = ['Cubic_BSpline_g_function_b' num2str(b) '.png'];
    % saveas(gcf, fullfile(Path_Output, filename));

    hold off;
end


%% Add paths

Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - Split-Sample Estimation');
addpath(Path_Data_03);


%% 

best_result = struct();

for b = [4, 6, 8]
    theta_table = theta_tables.(['b' num2str(b)]);
    all_alphas = str2double(theta_table.Properties.RowNames);

    min_J = Inf;
    best_alpha = NaN;
    best_theta = NaN;
    validation_loss_list = zeros(height(theta_table), 1);

    for i = 1:height(theta_table)
        theta = table2array(theta_table(i, :));
        alpha = all_alphas(i);

        J = GMM_objective_fixed_alpha_beta(theta, ...
            Smooth_AllR_valid, Smooth_AllR_RND_valid, Realized_Return_valid, ...
            b, min_knot, max_knot, alpha, 1);

        validation_loss_list(i) = J;

        if ~isnan(J) && J < min_J
            min_J = J;
            best_alpha = alpha;
            best_theta = theta;
        end
    end

    best_result.(['b' num2str(b)]).alpha = best_alpha;
    best_result.(['b' num2str(b)]).theta = best_theta;
    best_result.(['b' num2str(b)]).J = min_J;
    best_result.(['b' num2str(b)]).all_alphas = all_alphas;
    best_result.(['b' num2str(b)]).validation_losses = validation_loss_list;

    fprintf('[b = %d] Best alpha = %.2f, Validation GMM = %.4f\n', b, best_alpha, min_J);
end
