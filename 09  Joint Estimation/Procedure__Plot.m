clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load data

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


%% Estimated theta

Path_Data_09 = fullfile(Path_MainFolder, 'Code', '09  輸出資料');
mat_files = dir(fullfile(Path_Data_09, 'params_hat (b=*.mat'));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_09, mat_files(k).name);
    load(file_path, 'params_hat');

    % Extract theta (excluding the last two parameters: alpha and beta)
    theta_hat = params_hat(1:end-2);
    
    % Extract 'b' value from the filename
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');

    % Create variable name dynamically
    var_name = ['theta_hat_' b_value];

    % Assign theta_hat to workspace
    assignin('base', var_name, theta_hat);
end

clear b_value var_name k params_hat theta_hat


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

Path_Data_09 = fullfile(Path_MainFolder, 'Code', '09  Joint Estimation');
addpath(Path_Data_09);

Path_Output = fullfile(Path_MainFolder, 'Code', '09  輸出資料');


%% Plot: (1) Cubic B-Spline with g function value

y_min = 0;
y_max = 1.9;

Cubic_BSpline_Basis_Functions_g_combined = figure;

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    nexttile;

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

% sgtitle('Cubic B-Spline with g function value');

set(gcf, 'Position', [50, 50, 1200, 400]);

filename = 'Cubic_BSpline_Basis_Functions_g_combined.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename y_min y_max y_BS g_function_value


%% Plot: (2) Cubic B-Spline with g function value (Full)

y_min = -0.2;
y_max = 3;

Cubic_BSpline_Basis_Functions_g_combined_Full = figure;

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    nexttile;

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

% sgtitle('Cubic B-Spline with g function (Full range)');

set(gcf, 'Position', [50, 50, 1200, 400]);

filename = 'Cubic_BSpline_Basis_Functions_g_combined_Full.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename y_min y_max y_BS g_function_value


%% Plot: (3) g Function and SDF

y_min = 0.6;
y_max = 1.5;

g_and_SDF_combined = figure;

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    SDF = exp(- RF .* TTM) .* (1 ./ g_function_value);

    nexttile;

    plot(current_month_y_filtered, g_function_value, 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    hold on;

    scatter(current_month_y_filtered, SDF, 'Marker', '.', 'MarkerEdgeColor', 'b');

    % Set limits
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    xticks(x_start:0.05:x_end);
    yticks(y_min:0.1:y_max);
    grid on;

    title(['b = ', num2str(b)]);
    legend({'g Function', 'SDF'}, 'Location', 'northeast', 'Box', 'Off');

end

% sgtitle('g Function and SDF');

set(gcf, 'Position', [50, 50, 1200, 400]);

filename = 'g_and_SDF_combined.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Plot - Beamer

% Define Color (LaTeX Beamer Theme - Metropolis)

mRed        = '#e74c3c';
mDarkRed    = '#b22222';
mLightBlue  = '#3279a8';
mDarkBlue   = '#2c3e50';
mDarkGreen  = '#4b8b3b';
mOrange     = '#f39c12';
mBackground = '#FAFAFA';


%% Plot - Beamer: (1) Cubic B-Spline with g function value

y_min = 0;
y_max = 1.9;

Cubic_BSpline_Basis_Functions_g_combined = figure;
set(gcf, 'Color', mBackground);

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    nexttile;

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
    title(['b = ', num2str(b)], 'FontName', 'Fira Sans', 'FontSize', 12);

    % Add Legend
    type_legend = cell(1, b + 2);
    for i = 1:(b + 1)
        type_legend{i} = ['$B^{' num2str(3) '}_{' num2str(i - 1) '} (y)$'];
    end
    type_legend{b + 2} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(3) '}_{i} (y)$'];
    legend(type_legend, 'Interpreter', 'Latex', ...
                        'Location', 'northwest', ...
                        'Box', 'Off', ...
                        'FontSize', 12, ...
                        'NumColumns', 2);
    hold off;

end

% sgtitle('Cubic B-Spline with g function value');

set(gcf, 'Position', [50, 50, 1200, 400], 'Color', mBackground);

filename = 'Slide_Cubic_BSpline_Basis_Functions_g_combined.png';
exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', 'current');
clear filename y_min y_max y_BS g_function_value


%% Plot - Beamer: (2) Cubic B-Spline with g function value (Full)

y_min = -0.2;
y_max = 3;

Cubic_BSpline_Basis_Functions_g_combined_Full = figure;
set(gcf, 'Color', mBackground);

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    nexttile;

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
    title(['b = ', num2str(b)], 'FontName', 'Fira Sans', 'FontSize', 12);

    % Add Legend
    type_legend = cell(1, b + 2);
    for i = 1:(b + 1)
        type_legend{i} = ['$B^{' num2str(3) '}_{' num2str(i - 1) '} (y)$'];
    end
    type_legend{b + 2} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(3) '}_{i} (y)$'];
    legend(type_legend, 'Interpreter', 'Latex', ...
                        'Location', 'northwest', ...
                        'Box', 'Off', ...
                        'FontSize', 12, ...
                        'NumColumns', 2);
    hold off;

end

% sgtitle('Cubic B-Spline with g function (Full range)');

set(gcf, 'Position', [50, 50, 1200, 400], 'Color', mBackground);

filename = 'Slide_Cubic_BSpline_Basis_Functions_g_combined_Full.png';
exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', 'current');
clear filename y_min y_max y_BS g_function_value


%% Plot - Beamer: (3) g Function and SDF

y_min = 0.6;
y_max = 1.5;

g_and_SDF_combined = figure;
set(gcf, 'Color', mBackground);

layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for b = [4, 6, 8]

    y_BS = nan(b + 1, length(current_month_y_filtered));
    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    g_function_value = sum(transpose(eval(['theta_hat_', num2str(b)])) .* y_BS, 1);

    SDF = exp(- RF .* TTM) .* (1 ./ g_function_value);

    nexttile;

    plot(current_month_y_filtered, g_function_value, 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    hold on;

    scatter(current_month_y_filtered, SDF, 'Marker', '.', 'MarkerEdgeColor', 'b');

    % Set limits
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    xticks(x_start:0.05:x_end);
    yticks(y_min:0.1:y_max);
    grid on;

    title(['b = ', num2str(b)], 'FontName', 'Fira Sans', 'FontSize', 12);
    legend({'g Function', 'SDF'}, 'Location', 'northeast', 'Box', 'Off', 'FontSize', 12);

end

% sgtitle('g Function and SDF');

set(gcf, 'Position', [50, 50, 1200, 400], 'Color', mBackground);

filename = 'Slide_g_and_SDF_combined.png';
exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', 'current');
clear filename
