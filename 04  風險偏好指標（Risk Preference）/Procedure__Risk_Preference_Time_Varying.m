clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_04 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - Time varying');


%% General Setting

Target_TTM = 30;
Target_b = 4;


%% Load data: (1) Realized Return

Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName


%% Load data: (2) RND

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

clear years_to_merge year input_filename data


%% Load data: (3) Estimated theta

pattern = sprintf('Rolling_theta_TTM=%d_b=%d_(\\d{8})\\.mat', Target_TTM, Target_b);
file_list = dir(fullfile(Path_Data_04, '*.mat'));

% Initialize storage
theta_hat = {};

% Filter files and load data
row = 1;
for k = 1:length(file_list)
    tokens = regexp(file_list(k).name, pattern, 'tokens');
    if ~isempty(tokens)
        % Extract date string from file name
        date_str = tokens{1}{1};
        % Convert to numeric format (optional)
        date_val = str2double(date_str);

        % Load .mat file
        data = load(fullfile(Path_Data_04, file_list(k).name));

        % Store in cell array: first column is date, second column is theta_hat vector
        theta_hat{row, 1} = date_val;
        theta_hat{row, 2} = data.theta_hat;

        row = row + 1;
    end
end

% Optionally convert to table for easier manipulation
theta_hat_table = cell2table(theta_hat, 'VariableNames', {'Date', 'Theta_Hat'});

clear data date_val date_str k row tokens pattern file_list


%% Setting

% Order of the B-spline (cubic B-spline)
n = 3;

% Find the month with the maximum realized return across all months
[~, t] = max(Realized_Return.realized_ret);

months = Smooth_AllR.Properties.VariableNames;

max_month_realized_ret = Realized_Return{t, 2};
max_month_y = Smooth_AllR{1, months{t}};
max_month = months{t};

min_y = min(max_month_y);
max_y = 3;


%% Calculate g function

Path_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - Time varying');
addpath(Path_03);

% Calculate basis function
b = Target_b;
y_BS = nan(b + 1, length(max_month_y));

for i = 1:(b + 1)
    y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, max_month_y);
end
clear i

% Initialize storage for g(x) results
n_obs = height(theta_hat_table);
g_function_matrix = nan(n_obs, length(max_month_y));

% For each theta_hat, compute corresponding g(x)
for t = 1:n_obs
    theta_hat = theta_hat_table.Theta_Hat(t, :);
    theta_hat_col = theta_hat';
    g_function_matrix(t, :) = sum(theta_hat_col .* y_BS, 1);
end

% Convert to table and add date column
g_function_table = array2table(g_function_matrix);
g_function_table = addvars(g_function_table, theta_hat_table.Date, 'Before', 1);
g_function_table.Properties.VariableNames{1} = 'Date';

clear t theta_hat theta_hat_col


%% Plot

x_values = max_month_y;  % 1×30000 vector
g_values = g_function_table{:, 2:end};  % Drop the Date column, retain g(x) only

% Plot
figure;
hold on;
plot(x_values, g_values', 'Color', [0.2, 0.5, 0.8, 0.5]);
plot(x_values, mean(g_values, 1), 'k-', 'LineWidth', 3);   % Add mean g(x) line (black)
hold off;

% Formatting
title(['$g(x)$ Functions over Time (TTM = ', num2str(Target_TTM), ', b = ', num2str(Target_b), ')'], ...
    'Interpreter', 'latex', 'FontSize', 16);
xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('$g(x)$', 'Interpreter', 'latex', 'FontSize', 14);

% xlim([min(x_values), max(x_values)]);
% ylim([-0.2, 2.5]);

xlim([0.8, 1.2]);
ylim([0.4, 1.8]);

grid on;
set(gca, 'box', 'on', 'FontName', 'Times New Roman', 'FontSize', 12);

% Figure size and export (optional)
set(gcf, 'Position', [100, 100, 1000, 700]);
filename = sprintf('TTM_%d_b_%d_All_g_Functions.png', Target_TTM, Target_b);
% saveas(gcf, fullfile(Path_Output, filename));


%% Calculate First, Second, and Third Derivatives of g(x)

% Extract the x-axis values
x_values = max_month_y;

% Initialize matrices to store derivatives
g_prime_matrix        = nan(n_obs, length(x_values));
g_double_prime_matrix = nan(n_obs, length(x_values));
g_triple_prime_matrix = nan(n_obs, length(x_values));

% Compute derivatives for each g(x)
for t = 1:n_obs
    g = g_function_matrix(t, :);

    g_prime        = gradient(g, x_values);
    g_double_prime = gradient(g_prime, x_values);
    g_triple_prime = gradient(g_double_prime, x_values);

    g_prime_matrix(t, :)        = g_prime;
    g_double_prime_matrix(t, :) = g_double_prime;
    g_triple_prime_matrix(t, :) = g_triple_prime;
end

clear t g g_prime g_double_prime g_triple_prime


%% Calculate Risk Aversion, Prudence and Temperance

x_matrix = repmat(x_values, n_obs, 1);

% Step 1: Utility derivatives
u_1 = 1 ./ g_function_matrix;
u_2 = -1 ./ (g_function_matrix.^2) .* g_prime_matrix;
u_3 =  2 ./ (g_function_matrix.^3) .* (g_prime_matrix.^2) - ...
       1 ./ (g_function_matrix.^2) .* g_double_prime_matrix;
u_4 = -6 ./ (g_function_matrix.^4) .* (g_prime_matrix.^3) + ...
       6 ./ (g_function_matrix.^3) .* g_prime_matrix .* g_double_prime_matrix - ...
       1 ./ (g_function_matrix.^2) .* g_triple_prime_matrix;

% Step 2: Risk measures
ARA = -u_2 ./ u_1;
RRA = x_matrix .* ARA;

AP  = -u_3 ./ u_2;
RP  = x_matrix .* AP;

AT  = -u_4 ./ u_3;
RT  = x_matrix .* AT;

clear u_1 u_2 u_3 u_4 x_matrix


%% 

Path_Data_04 = fullfile(Path_MainFolder, 'Code', '04  風險偏好指標（Risk Preference）');
addpath(Path_Data_04);

date_vec = theta_hat_table.Date;

xmin = 0.8;
xmax = 1.2;

ARA_w = winsorize_percentile(ARA, 5, 95);
RRA_w = winsorize_percentile(RRA, 5, 95);
AP_w = winsorize_percentile(AP, 10, 90);
RP_w = winsorize_percentile(RP, 10, 90);
AT_w = winsorize_percentile(AT, 10, 90);
RT_w = winsorize_percentile(RT, 10, 90);


%% 
plot_risk_preference_surface(x_values, date_vec, ARA_w, xmin, xmax, 'Absolute Risk Aversion (ARA)', 'ARA');
%% 
plot_risk_preference_surface(x_values, date_vec, RRA_w, xmin, xmax, 'Relative Risk Aversion (RRA)', 'RRA');
%% 
plot_risk_preference_surface(x_values, date_vec, AP_w,  xmin, xmax, 'Absolute Prudence (AP)',       'AP');
%% 
plot_risk_preference_surface(x_values, date_vec, RP_w,  xmin, xmax, 'Relative Prudence (RP)',       'RP');
%% 
plot_risk_preference_surface(x_values, date_vec, AT_w,  xmin, xmax, 'Absolute Temperance (AT)',     'AT');
%% 
plot_risk_preference_surface(x_values, date_vec, RT_w,  xmin, xmax, 'Relative Temperance (RT)',     'RT');

