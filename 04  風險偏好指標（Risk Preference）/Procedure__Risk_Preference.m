clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 90;

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName

% RND
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllR = [];

years_to_merge = 1996:2021;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data_02, sprintf('TTM_%d_RND_Tables_%d.mat', Target_TTM, year));
        
    if exist(input_filename, 'file')
        data = load(input_filename);        
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
    else
        warning('File %s does not exist.', input_filename);
    end
end

% Estimated theta
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');
mat_files = dir(fullfile(Path_Data_03, sprintf('TTM_%d_theta_hat (b=*.mat', Target_TTM)));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    var_name = ['theta_hat_' b_value];
    assignin('base', var_name, theta_hat);
end

clear b_value var_name k theta_hat year
clear Path_Data_01 Path_Data_02 Path_Data_03 file_path input_filename


%% Define the knots for the B-spline

n = 3;                                                                     % Order of the B-spline (cubic B-spline)

Aggregate_Smooth_AllR = Smooth_AllR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = 3;

clear Aggregate_Smooth_AllR


%% Setting

% Specify the month to plot
[~, t] = max(Realized_Return.realized_ret);

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

current_month = months{t};

min_y = min(current_month_y_filtered);
max_y = 3;


%% Calculate Risk Aversion, Prudence and Temperance

store_g              = nan(3, length(current_month_y_filtered));
store_g_prime        = nan(3, length(current_month_y_filtered));
store_g_double_prime = nan(3, length(current_month_y_filtered));
store_g_triple_prime = nan(3, length(current_month_y_filtered));
store_ARA            = nan(3, length(current_month_y_filtered));
store_RRA            = nan(3, length(current_month_y_filtered));
store_AP             = nan(3, length(current_month_y_filtered));
store_RP             = nan(3, length(current_month_y_filtered));
store_AT             = nan(3, length(current_month_y_filtered));
store_RT             = nan(3, length(current_month_y_filtered));

for b = [4, 6, 8]

    Path_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - 2021 JBF');
    addpath(Path_03);

    % Calculation
    y_BS = nan(b + 1, length(current_month_y_filtered));

    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    clear i

    % Calculate the value of g function
    theta_hat_var_name = ['theta_hat_', num2str(b)];
    g_function_value = sum(transpose(eval(theta_hat_var_name)) .* y_BS, 1);

    % Specific folder
    Path_Output = fullfile(Path_MainFolder, 'Code', '04  輸出資料 - 2021 JBF');
    Path_04 = fullfile(Path_MainFolder, 'Code', '04  風險偏好指標（Risk Preference）');
    addpath(Path_04);

    y = current_month_y_filtered;
    g = g_function_value;

    g_prime = gradient(g, y);
    g_double_prime = gradient(g_prime, y);
    g_triple_prime = gradient(g_double_prime, y);

    % Derivative of Utility
    u_1_prime = 1 ./ g;
    u_2_prime = -1 ./ (g.^2) .* g_prime;
    u_3_prime = 2 ./ (g.^3) .* (g_prime.^2) - 1 ./ (g.^2) .* g_double_prime;
    u_4_prime = -6 ./ (g.^4) .* (g_prime.^3) + ...
                6 ./ (g.^3) .* g_prime .* g_double_prime - ...
                1 ./ (g.^2) .* g_triple_prime;

    % Risk Aversion
    ARA = -u_2_prime ./ u_1_prime;
    RRA = y .* ARA;
    
    % Prudence
    AP = -u_3_prime ./ u_2_prime;
    RP = y .* AP;

    % Temperance
    AT = -u_4_prime ./ u_3_prime;
    RT = y .* AT;

    idx = b / 2 - 1;
    store_g(idx, :)              = g;
    store_g_prime(idx, :)        = g_prime;
    store_g_double_prime(idx, :) = g_double_prime;
    store_g_triple_prime(idx, :) = g_triple_prime;
    store_ARA(idx, :)            = ARA;
    store_RRA(idx, :)            = RRA;
    store_AP(idx, :)             = AP;
    store_RP(idx, :)             = RP;
    store_AT(idx, :)             = AT;
    store_RT(idx, :)             = RT;

    clear g g_prime g_double_prime g_triple_prime
    clear u_1_prime u_2_prime u_3_prime u_4_prime
    clear ARA RRA AP RP AT RT
end


%% Plot Setting

x_min = 0;
x_max = 1.21;

x_start = 0.8;
x_end = 1.2;

fill_color = [0.9, 0.9, 0.9];


%% g function

y_min = -0.1;
y_max = 1.6;

figure;
tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

for idx = 1:3
    nexttile;

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_g(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('$x$', 'Interpreter', 'latex');
    ylabel('$g(x)$', 'Interpreter', 'latex');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('g Function');

set(gcf, 'Position', [100, 100, 1200, 400]);

% filename = 'g_function.png';
% saveas(gcf, fullfile(Path_Output, filename));
% clear filename


%%  g function and its derivatives

figure;
tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'None');

for idx = 1:3
    % Plot g(x)
    nexttile;

    hold on;
    plot(y, store_g(idx, :), 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    title(['$g(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([0, 1.5]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'(x)
    nexttile;

    hold on;
    plot(y, store_g_prime(idx, :), '.');
    title(['$g^\prime(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^\prime(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-1.5, 2]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g''(x)
    nexttile;

    hold on;
    plot(y, store_g_double_prime(idx, :), '.');
    title(['$g^{\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-2, 7]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'''(x)
    nexttile;

    hold on;
    plot(y, store_g_triple_prime(idx, :), '.');
    title(['$g^{\prime\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-7, -3]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

end

% sgtitle('g Function and Its Derivatives');

set(gcf, 'Position', [10, 10, 1500, 900]);

filename = sprintf('TTM_%d_g_Function_and_Its_Derivatives.png', Target_TTM);
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Plot risk figure

plot_risk_figure(y, store_ARA, '$\mathrm{ARA}(x)$', 0.5, 3.5, 'Absolute_Risk_Aversion', Target_TTM, Path_Output, x_start, x_end);
plot_risk_figure(y, store_RRA, '$\mathrm{RRA}(x)$', 0.5, 3.5, 'Relative_Risk_Aversion', Target_TTM, Path_Output, x_start, x_end);
plot_risk_figure(y, store_AP,  '$\mathrm{AP}(x)$',  2.0, 5.5, 'Absolute_Prudence',      Target_TTM, Path_Output, x_start, x_end);
plot_risk_figure(y, store_RP,  '$\mathrm{RP}(x)$',  2.0, 5.5, 'Relative_Prudence',      Target_TTM, Path_Output, x_start, x_end);
plot_risk_figure(y, store_AT,  '$\mathrm{AT}(x)$',  2.5, 7.0, 'Absolute_Temperance',    Target_TTM, Path_Output, x_start, x_end);
plot_risk_figure(y, store_RT,  '$\mathrm{RT}(x)$',  2.5, 7.0, 'Relative_Temperance',    Target_TTM, Path_Output, x_start, x_end);


%% Plot - Beamer

% Define Color (LaTeX Beamer Theme - Metropolis)
mRed        = '#e74c3c';
mDarkRed    = '#b22222';
mLightBlue  = '#3279a8';
mDarkBlue   = '#2c3e50';
mDarkGreen  = '#4b8b3b';
mOrange     = '#f39c12';
mBackground = '#FAFAFA';


%%  Beamer - g function and its derivatives

figure;
tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'None');
set(gcf, 'Color', mBackground);

for idx = 1:3
    % Plot g(x)
    nexttile;

    hold on;
    plot(y, store_g(idx, :), 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    title(['$g(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([0, 1.5]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 11);
    hold off;

    % Plot g'(x)
    nexttile;

    hold on;
    plot(y, store_g_prime(idx, :), '.');
    title(['$g^\prime(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^\prime(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-1.5, 2]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 11);
    hold off;

    % Plot g''(x)
    nexttile;

    hold on;
    plot(y, store_g_double_prime(idx, :), '.');
    title(['$g^{\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-2, 7]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 11);
    hold off;

    % Plot g'''(x)
    nexttile;

    hold on;
    plot(y, store_g_triple_prime(idx, :), '.');
    title(['$g^{\prime\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-7, -3]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 11);
    hold off;

end

% sgtitle('g Function and Its Derivatives');

set(gcf, 'Position', [10, 10, 1500, 900]);

filename = sprintf('Slide_TTM_%d_g_Function_and_Its_Derivatives.png', Target_TTM);
exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', 'current');
clear filename


%% Beamer - Plot risk figure

% ARA
plot_risk_figure_beamer(y, store_ARA, '$\mathrm{ARA}(x)$', 0.5, 3.5, ...
    'Absolute_Risk_Aversion', Target_TTM, Path_Output, x_start, x_end);

% RRA
plot_risk_figure_beamer(y, store_RRA, '$\mathrm{RRA}(x)$', 0.5, 3.5, ...
    'Relative_Risk_Aversion', Target_TTM, Path_Output, x_start, x_end);

% AP
plot_risk_figure_beamer(y, store_AP, '$\mathrm{AP}(x)$', 2.0, 5.5, ...
    'Absolute_Prudence', Target_TTM, Path_Output, x_start, x_end);

% RP
plot_risk_figure_beamer(y, store_RP, '$\mathrm{RP}(x)$', 2.0, 5.5, ...
    'Relative_Prudence', Target_TTM, Path_Output, x_start, x_end);

% AT
plot_risk_figure_beamer(y, store_AT, '$\mathrm{AT}(x)$', 2.5, 7.0, ...
    'Absolute_Temperance', Target_TTM, Path_Output, x_start, x_end);

% RT
plot_risk_figure_beamer(y, store_RT, '$\mathrm{RT}(x)$', 2.5, 7.0, ...
    'Relative_Temperance', Target_TTM, Path_Output, x_start, x_end);
