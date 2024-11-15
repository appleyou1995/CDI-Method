clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
Path_Data = fullfile(Path_MainFolder, 'Data');
Data_RF = load(fullfile(Path_Data, 'RiskFreeRate19962022.txt'));

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  原始資料處理');
Realized_Return = readtable(fullfile(Path_Data_01, 'Realized_Return.csv'));
Risk_Free_Rate = readtable(fullfile(Path_Data_01, 'Risk_Free_Rate.csv'));

% RND
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

% Estimated theta
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');
mat_files = dir(fullfile(Path_Data_03, 'theta_hat (b=*.mat'));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    var_name = ['theta_hat_' b_value];
    assignin('base', var_name, theta_hat);
end

clear b_value var_name k theta_hat


%% Define the knots for the B-spline

n = 3;                                                                     % Order of the B-spline (cubic B-spline)

Aggregate_Smooth_AllR = Smooth_AllR.Variables;
ret_size = size(Smooth_AllK, 2);

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = 3;

clear Aggregate_Smooth_AllR


%% Plot: Setting

% Specify the month to plot
t = 291;

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

TTM = 29 / 365;
RF = Risk_Free_Rate{t, 3};

current_month = months{t};

min_y = min(current_month_y_filtered);
max_y = 3;

% Define Color of Each Line
o = [0.9290 0.6940 0.1250];
p = [0.4940 0.1840 0.5560];
color_All = {'b', 'g', 'm', 'c', 'y', 'k', 'r', o, p};

x_start = 0.8;
x_end = 1.2;
fill_color = [0.9, 0.9, 0.9];

Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - 2021 JBF');
addpath(Path_Data_03);

Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');


%% Plot: (1) Cubic B-Spline with g function value

y_min = 0;
y_max = 1.9;

Cubic_BSpline_Basis_Functions_g_combined = figure;

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    % Create subplot (2 rows, 3 columns)
    subplot(1, 3, b/2-1);

    % Plot cubic B-Spline basis functions
    for i = 1:(b + 1)
        plot(current_month_y_filtered, y_BS(i, :), 'LineStyle', '-', 'LineWidth', 1);
        hold on;
        y_max = max(y_max, max(y_BS(i, :)));
    end

    % Plot g function value
    plot(current_month_y_filtered, g_function_value, 'LineStyle', ':', 'LineWidth', 3, 'Color', 'r');
    y_max = max(y_max, max(g_function_value));

    % Plot vertical lines
    x_vals = [x_start, x_end];
    
    for j = 1:length(x_vals)
        plot([x_vals(j), x_vals(j)], [y_min, 1.2 * y_max], '--', 'LineWidth', 0.8, 'Color', [0.5 0.5 0.5]);
    end
    
    fill([x_start x_end x_end x_start], ...
         [y_min y_min y_max y_max], ...
         fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    % Set limits
    ylim([y_min, y_max]);
    xlim([0, 1.2]);
    grid on;

    % Add title
    title(['b = ', num2str(b)]);

    % Add Legend
    type_legend = cell(1, b + 2);
    for i = 1:(b + 1)
        type_legend{i} = ['$B^{' num2str(3) '}_{' num2str(i - 1) '} (y)$'];
    end
    type_legend{b + 2} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(3) '}_{i} (y)$'];
    legend(type_legend, 'Interpreter', 'Latex', 'Location', 'northwest', 'Box', 'Off', 'FontSize', 10);
    hold off;

end

sgtitle('Cubic B-Spline with g function value for b = 3 to 8');

set(gcf, 'Position', [50, 50, 1500, 850]);
set(gca, 'LooseInset', get(gca, 'TightInset'));

filename = 'Cubic_BSpline_Basis_Functions_g_combined.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename y_min y_max y_BS g_function_value


%% Plot: (2) Cubic B-Spline with g function value (Full)

y_min = -0.2;
y_max = 3;

Cubic_BSpline_Basis_Functions_g_combined_Full = figure;

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    % Create subplot (2 rows, 3 columns)
    subplot(1, 3, b/2-1);

    % Plot cubic B-Spline basis functions
    for i = 1:(b + 1)
        plot(current_month_y, y_BS(i, :), 'LineStyle', '-', 'LineWidth', 1);
        hold on;
        y_max = max(y_max, max(y_BS(i, :)));
    end

    % Plot g function value
    plot(current_month_y, g_function_value, 'LineStyle', ':', 'LineWidth', 3, 'Color', 'r');
    y_max = max(y_max, max(g_function_value));

    % Plot vertical lines
    x_vals = [x_start, x_end];
    
    for j = 1:length(x_vals)
        plot([x_vals(j), x_vals(j)], [y_min, 1.2 * y_max], '--', 'LineWidth', 0.8, 'Color', [0.5 0.5 0.5]);
    end
    
    fill([x_start x_end x_end x_start], ...
         [y_min y_min y_max y_max], ...
         fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    % Set limits
    ylim([y_min, y_max]);
    xlim([0, 3]);
    grid on;

    % Add title
    title(['b = ', num2str(b)]);

    % Add Legend
    type_legend = cell(1, b + 2);
    for i = 1:(b + 1)
        type_legend{i} = ['$B^{' num2str(3) '}_{' num2str(i - 1) '} (y)$'];
    end
    type_legend{b + 2} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(3) '}_{i} (y)$'];
    legend(type_legend, 'Interpreter', 'Latex', 'Location', 'northwest', 'Box', 'Off', 'FontSize', 10, 'NumColumns', 2);
    hold off;

end

sgtitle('Cubic B-Spline with g function value (Full range) for b = 3 to 8');

set(gcf, 'Position', [50, 50, 1500, 400]);
set(gca, 'LooseInset', get(gca, 'TightInset'));

filename = 'Cubic_BSpline_Basis_Functions_g_combined_Full.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename y_min y_max y_BS g_function_value


%% Plot: (3) g Function and SDF

y_min = 0.6;
y_max = 1.5;

g_and_SDF_combined = figure;

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    SDF = exp(- RF .* TTM) .* (1 ./ g_function_value);

    subplot(2, 3, b-2);

    plot(current_month_y_filtered, g_function_value, 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    hold on;

    scatter(current_month_y_filtered, SDF, 'Marker', '.', 'MarkerEdgeColor', 'b');

    % Set limits
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    xticks(x_start:0.02:x_end);
    yticks(y_min:0.1:y_max);
    grid on;

    title(['b = ', num2str(b)]);
    legend({'g Function', 'SDF'}, 'Location', 'northeast', 'Box', 'Off');

end

sgtitle('g Function and SDF for b = 3 to 8');

set(gcf, 'Position', [50, 50, 1500, 850]);
set(gca, 'LooseInset', get(gca, 'TightInset'));

filename = 'g_and_SDF_combined.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename