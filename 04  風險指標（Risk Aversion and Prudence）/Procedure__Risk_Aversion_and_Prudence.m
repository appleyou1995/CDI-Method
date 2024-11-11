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
mat_files = dir(fullfile(Path_Data_03, 'ceil_theta_hat (b=*.mat'));

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


%% Calculate Risk Aversion and Prudence

store_g              = nan(6, length(current_month_y_filtered));
store_g_prime        = nan(6, length(current_month_y_filtered));
store_g_double_prime = nan(6, length(current_month_y_filtered));
store_ARA            = nan(6, length(current_month_y_filtered));
store_RRA            = nan(6, length(current_month_y_filtered));
store_AP             = nan(6, length(current_month_y_filtered));
store_RP             = nan(6, length(current_month_y_filtered));

for b = 3:8

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
    Path_04 = fullfile(Path_MainFolder, 'Code', '04  風險指標（Risk Aversion and Prudence）');
    addpath(Path_04);

    y = current_month_y_filtered;
    g = g_function_value;

    g_prime = gradient(g, y);
    g_double_prime = gradient(g_prime, y);

    % Risk Aversion
    ARA = g_prime ./ g;
    RRA = y .* (g_prime ./ g);
    
    % Prudence
    AP = (2 * (g_prime ./ g)) - (g_double_prime ./ g_prime);
    RP = y .* AP;

    idx = b - 2;
    store_g(idx, :)              = g;
    store_g_prime(idx, :)        = g_prime;
    store_g_double_prime(idx, :) = g_double_prime;
    store_ARA(idx, :)            = ARA;
    store_RRA(idx, :)            = RRA;
    store_AP(idx, :)             = AP;
    store_RP(idx, :)             = RP;

end


%% Plot Setting

x_min = 0;
x_max = 1.3;

x_start = 0.9;
x_end = 1.06;

fill_color = [0.9, 0.9, 0.9];


%% g function

y_min = -0.1;
y_max = 1.6;

figure;
for idx = 1:6
    subplot(2,3,idx);

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_g(idx, :), '.');
    title(['b = ', num2str(idx + 2)]);
    xlabel('y');
    ylabel('g(y)');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
sgtitle('g Function for b = 3 to 8');

set(gcf, 'Position', [100, 100, 1500, 800]);
set(gca, 'LooseInset', get(gca,'TightInset'));

filename = 'ceil_g_function.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Absolute Risk Aversion (ARA)

y_min = 0;
y_max = 300;

figure;
for idx = 1:6
    subplot(2,3,idx);

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_ARA(idx, :), '.');
    title(['b = ', num2str(idx + 2)]);
    xlabel('y');
    ylabel('ARA(y)');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
sgtitle('Absolute Risk Aversion (ARA) for b = 3 to 8');

set(gcf, 'Position', [100, 100, 1500, 800]);
set(gca, 'LooseInset', get(gca,'TightInset'));

filename = 'ceil_Absolute_Risk_Aversion.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Relative Risk Aversion (RRA)

y_min = 2;
y_max = 15;

figure;
for idx = 1:6
    subplot(2,3,idx);

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_RRA(idx, :), '.');
    title(['b = ', num2str(idx + 2)]);
    xlabel('y');
    ylabel('RRA(y)');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
sgtitle('Relative Risk Aversion (RRA) for b = 3 to 8');

set(gcf, 'Position', [100, 100, 1500, 800]);
set(gca, 'LooseInset', get(gca,'TightInset'));

filename = 'ceil_Relative_Risk_Aversion.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Absolute Prudence (AP)

y_min = 0;
y_max = 100;

figure;
for idx = 1:6
    subplot(2,3,idx);

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_AP(idx, :), '.');
    title(['b = ', num2str(idx + 2)]);
    xlabel('y');
    ylabel('AP(y)');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
sgtitle('Absolute Prudence (AP) for b = 3 to 8');

set(gcf, 'Position', [100, 100, 1500, 800]);
set(gca, 'LooseInset', get(gca,'TightInset'));

filename = 'ceil_Absolute_Prudence.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Relative Prudence (RP)

y_min = 2;
y_max = 15;

figure;
for idx = 1:6
    subplot(2,3,idx);

    hold on;
    fill([x_start x_end x_end x_start], [y_min y_min y_max y_max], fill_color, 'FaceAlpha', 0.5, 'EdgeColor', 'none');

    plot(y, store_RP(idx, :), '.');
    title(['b = ', num2str(idx + 2)]);
    xlabel('y');
    ylabel('RP(y)');
    xlim([x_min, x_max]);
    ylim([y_min, y_max]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end
sgtitle('Relative Prudence (RP) for b = 3 to 8');

set(gcf, 'Position', [100, 100, 1500, 800]);
set(gca, 'LooseInset', get(gca,'TightInset'));

filename = 'ceil_Relative_Prudence.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename
