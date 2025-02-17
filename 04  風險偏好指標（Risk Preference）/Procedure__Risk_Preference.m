clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  原始資料處理');
Realized_Return = readtable(fullfile(Path_Data_01, 'Realized_Return.csv'));

% RND
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllR = [];

years_to_merge = 1996:2021;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));
        
    if exist(input_filename, 'file')
        data = load(input_filename);        
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
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

% Specify the month to plot: 20200318
t = 291;

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
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_g(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('g(y)');
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
layout = tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    % Plot g(y)
    nexttile;

    hold on;
    plot(y, store_g(idx, :), '.');
    title(['g(y), b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('g(y)');
    xlim([x_min, x_max]);
    ylim([0, 1.5]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'(y)
    nexttile;

    hold on;
    plot(y, store_g_prime(idx, :), '.');
    title(['g''(y), b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('g''(y)');
    xlim([x_min, x_max]);
    ylim([-1.5, 2]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g''(y)
    nexttile;

    hold on;
    plot(y, store_g_double_prime(idx, :), '.');
    title(['g''''(y), b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('g''''(y)');
    xlim([x_min, x_max]);
    ylim([-2, 7]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'''(y)
    nexttile;

    hold on;
    plot(y, store_g_triple_prime(idx, :), '.');
    title(['g''''''(y), b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('g''''''(y)');
    xlim([x_min, x_max]);
    ylim([-7, -3]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

end

% sgtitle('g Function and Its Derivatives');

set(gcf, 'Position', [100, 100, 1500, 850]);

filename = 'g_Function_and_Its_Derivatives.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Absolute Risk Aversion (ARA)

y_min = 0.5;
y_max = 3.5;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_ARA(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('ARA(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Absolute Risk Aversion (ARA)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Absolute_Risk_Aversion.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Relative Risk Aversion (RRA)

y_min = 0.5;
y_max = 3.5;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_RRA(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('RRA(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Relative Risk Aversion (RRA)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Relative_Risk_Aversion.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Absolute Prudence (AP)

y_min = 2;
y_max = 5.5;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_AP(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('AP(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Absolute Prudence (AP)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Absolute_Prudence.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Relative Prudence (RP)

y_min = 2;
y_max = 5.5;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_RP(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('RP(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Relative Prudence (RP)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Relative_Prudence.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Absolute Temperance (AT)

y_min = 2.5;
y_max = 7;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_AT(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('AT(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Absolute Temperance (AT)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Absolute_Temperance.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Relative Temperance (RT)

y_min = 2.5;
y_max = 7;

figure;
layout = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for idx = 1:3
    nexttile;

    hold on;
    % fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_RT(idx, :), '.');
    title(['b = ', num2str((idx + 1) * 2)]);
    xlabel('y');
    ylabel('RT(y)');
    xlim([x_start, x_end]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
% sgtitle('Relative Temperance (RT)');

set(gcf, 'Position', [100, 100, 1200, 400]);

filename = 'Relative_Temperance.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename
