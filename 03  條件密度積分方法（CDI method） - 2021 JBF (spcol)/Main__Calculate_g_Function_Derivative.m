clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Target_TTM = [30, 60, 90, 180]
Target_TTM = 180;

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
Path_Data = fullfile(Path_MainFolder, 'Data');
Data_RF = load(fullfile(Path_Data, 'RiskFreeRate19962022.txt'));

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
FileName = ['Realized_Return_TTM_', num2str(Target_TTM), '.csv'];
Realized_Return = readtable(fullfile(Path_Data_01, FileName));
clear FileName

% RND
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料 - no dividend');
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
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF - no dividend');
mat_files = dir(fullfile(Path_Data_03, sprintf('TTM_%d_theta_hat (b=*.mat', Target_TTM)));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    S = load(file_path, 'theta_hat');
    theta_hat = S.theta_hat;
    b_value = regexp(mat_files(k).name, '(?<=\(b=)\d+(?=\))', 'match', 'once');
    if isempty(b_value)
        warning('Cannot parse b from file name: %s', mat_files(k).name);
        continue;
    end

    field_name = ['b' b_value];
    theta_struct.(field_name) = theta_hat(:).';
end

clear b_value var_name k theta_hat S
clear field_name input_filename file_path mat_files year years_to_merge data


%% Define the knots for the B-spline

Aggregate_Smooth_AllR = Smooth_AllR.Variables;
ret_size = size(Smooth_AllK, 2);

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = 3;

clear Aggregate_Smooth_AllR


%% Setting

degree = 3;                                                                % cubic B-spline
order  = degree + 1;

% Specify the month to plot
[~, t] = max(Realized_Return.realized_ret);

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month = months{t};

y     = current_month_y(:);
min_y = min(current_month_y);
max_y = 3;

store_g              = nan(3, length(current_month_y));
store_g_prime        = nan(3, length(current_month_y));
store_g_double_prime = nan(3, length(current_month_y));
store_g_triple_prime = nan(3, length(current_month_y));


%% Calculate g function and its derivatives using spcol

b_list = [4, 6, 8];

for b = b_list

    % Retrieve theta_hat for this b
    field_name = ['b' num2str(b)];
    if ~isfield(theta_struct, field_name)
        warning('theta_hat for b = %d not found. Skip.', b);
        continue;
    end
    theta_hat = theta_struct.(field_name);

    % Build open-uniform knot vector on [min_y, max_y]
    num_knots = degree + b + 2;
    knots = linspace(min_y, max_y, num_knots);
    knots(1:(degree+1))     = min_y;                                       % left open-uniform
    knots((end-degree):end) = max_y;                                       % right open-uniform

    % Evaluate all B-splines at once: B_all is N × (b+1)
    B_all = spcol(knots, order, y);

    % g(x) = Σ_i θ_i B_i(x)
    g = (theta_hat * B_all.').';

    % Numerical derivatives
    g_prime         = gradient(g, y);
    g_double_prime  = gradient(g_prime, y);
    g_triple_prime  = gradient(g_double_prime, y);

    % Store in row form for plotting / export
    idx = b / 2 - 1;
    store_g(idx, :)              = g.';
    store_g_prime(idx, :)        = g_prime.';
    store_g_double_prime(idx, :) = g_double_prime.';
    store_g_triple_prime(idx, :) = g_triple_prime.';

end


%% Plot g function and its derivatives

x_min = 0;
x_max = 3;

figure;
tiledlayout(3, 4, 'TileSpacing', 'Compact', 'Padding', 'None');

for idx = 1:3
    b = (idx + 1) * 2;

    % Plot g(x)
    nexttile;
    hold on;
    plot(current_month_y, store_g(idx, :), 'LineStyle', '--', ...
        'LineWidth', 2, 'Color', 'r');
    title(['$g(x), b = ', num2str(b), '$'], ...
        'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-0.1, 2.3]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'(x)
    nexttile;
    hold on;
    plot(current_month_y, store_g_prime(idx, :), '.');
    title(['$g^\prime(x), b = ', num2str(b), '$'], ...
        'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^\prime(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-5, 3]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g''(x)
    nexttile;
    hold on;
    plot(current_month_y, store_g_double_prime(idx, :), '.');
    title(['$g^{\prime\prime}(x), b = ', num2str(b), '$'], ...
        'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-40, 31]);
    grid on;
    set(gca, 'box', 'on');
    hold off;

    % Plot g'''(x)
    nexttile;
    hold on;
    plot(current_month_y, store_g_triple_prime(idx, :), '.');
    title(['$g^{\prime\prime\prime}(x), b = ', num2str(b), '$'], ...
        'Interpreter', 'latex', 'FontSize', 14);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$g^{\prime\prime\prime}(x)$', 'Interpreter', 'latex', 'FontSize', 14);
    xlim([x_min, x_max]);
    ylim([-12, 2]);
    grid on;
    set(gca, 'box', 'on');
    hold off;
end

set(gcf, 'Position', [10, 10, 1500, 900]);

Path_Output = Path_Data_03;
filename = sprintf('TTM_%d_g_Function_and_Its_Derivatives_Full.png', Target_TTM);
saveas(gcf, fullfile(Path_Output, filename));
clear filename


%% Output to xlsx

xlsxFilename = sprintf('TTM_%d_g_Function_and_Its_Derivatives_1996_2021.xlsx', Target_TTM);
outputFile   = fullfile(Path_Output, xlsxFilename);

writematrix(current_month_y.',      outputFile, 'Sheet', 'gross return');
writematrix(store_g.',              outputFile, 'Sheet', 'g');
writematrix(store_g_prime.',        outputFile, 'Sheet', 'g_prime');
writematrix(store_g_double_prime.', outputFile, 'Sheet', 'g_double_prime');
writematrix(store_g_triple_prime.', outputFile, 'Sheet', 'g_triple_prime');