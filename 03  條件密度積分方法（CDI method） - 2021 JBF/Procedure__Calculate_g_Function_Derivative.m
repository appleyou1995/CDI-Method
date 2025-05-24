clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 90;

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
Path_Data = fullfile(Path_MainFolder, 'Data');
Data_RF = load(fullfile(Path_Data, 'RiskFreeRate19962022.txt'));

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName

% RND
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


%% Setting

% Specify the month to plot
[~, t] = max(Realized_Return.realized_ret);

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month = months{t};

min_y = min(current_month_y);
max_y = 3;

store_g              = nan(3, length(current_month_y));
store_g_prime        = nan(3, length(current_month_y));
store_g_double_prime = nan(3, length(current_month_y));
store_g_triple_prime = nan(3, length(current_month_y));


%% Calculate g function and its derivatives

for b = [4, 6, 8]

    Path_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - 2021 JBF');
    addpath(Path_03);

    % Calculation
    y_BS = nan(b + 1, length(current_month_y));

    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
    end
    clear i

    % Calculate the value of g function
    theta_hat_var_name = ['theta_hat_', num2str(b)];
    g_function_value = sum(transpose(eval(theta_hat_var_name)) .* y_BS, 1);

    % Specific folder
    Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');

    y = current_month_y;
    g = g_function_value;

    g_prime = gradient(g, y);
    g_double_prime = gradient(g_prime, y);
    g_triple_prime = gradient(g_double_prime, y);

    idx = b / 2 - 1;
    store_g(idx, :)              = g;
    store_g_prime(idx, :)        = g_prime;
    store_g_double_prime(idx, :) = g_double_prime;
    store_g_triple_prime(idx, :) = g_triple_prime;

    clear g g_prime g_double_prime g_triple_prime
end


%%  Plot g function and its derivatives

x_min = 0;
x_max = 3;

figure;
layout = tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'None');

for idx = 1:3
    % Plot g(x)
    nexttile;

    hold on;
    plot(y, store_g(idx, :), 'LineStyle', '--', 'LineWidth', 2, 'Color', 'r');
    title(['$g(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-0.1, 2.1]);
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
    ylim([-3, 2.5]);
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
    ylim([-4.5, 8]);
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
    ylim([-9, 3]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

end

% sgtitle('g Function and Its Derivatives');

set(gcf, 'Position', [10, 10, 1500, 900]);

filename = sprintf('TTM_%d_g_Function_and_Its_Derivatives_Full.png', Target_TTM);
% saveas(gcf, fullfile(Path_Output, filename));
clear filename


%%  Plot g function and its derivatives (Beamer)

x_min = 0;
x_max = 3;

% Define Color (LaTeX Beamer Theme - Metropolis)
mBackground = '#FAFAFA';

figure;
layout = tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'None');
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
    ylim([-0.1, 2.1]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 12);
    hold off;

    % Plot g'(x)
    nexttile;

    hold on;
    plot(y, store_g_prime(idx, :), '.');
    title(['$g^\prime(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^\prime(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-3, 2.5]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 12);
    hold off;

    % Plot g''(x)
    nexttile;

    hold on;
    plot(y, store_g_double_prime(idx, :), '.');
    title(['$g^{\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-4.5, 8]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 12);
    hold off;

    % Plot g'''(x)
    nexttile;

    hold on;
    plot(y, store_g_triple_prime(idx, :), '.');
    title(['$g^{\prime\prime\prime}(x), b = ', num2str((idx + 1) * 2), '$'], 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-9, 3]);
    grid on;
    set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 12);
    hold off;

end

% sgtitle('g Function and Its Derivatives');

set(gcf, 'Position', [10, 10, 1500, 900]);

filename = sprintf('Slide_TTM_%d_g_Function_and_Its_Derivatives_Full.png', Target_TTM);
exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', mBackground);
clear filename


%% Output to xlsx

xlsxFilename = sprintf('TTM_%d_g_Function_and_Its_Derivatives_1996_2021.xlsx', Target_TTM);
outputFile = fullfile(Path_Output, xlsxFilename);

writematrix(y.',                   outputFile, 'Sheet', 'gross return');
writematrix(store_g.',             outputFile, 'Sheet', 'g');
writematrix(store_g_prime.',       outputFile, 'Sheet', 'g_prime');
writematrix(store_g_double_prime.',outputFile, 'Sheet', 'g_double_prime');
writematrix(store_g_triple_prime.',outputFile, 'Sheet', 'g_triple_prime');
