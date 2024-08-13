clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Risk-Free Rate  [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
Path_Data_99 = fullfile(Path_MainFolder, 'Data', '99 姿穎學姊提供', '20240417');
Data_RF = load(fullfile(Path_Data_99, 'RiskFreeRate19962019.txt'));

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  原始資料處理');
Realized_Return = readtable(fullfile(Path_Data_01, 'Realized_Return.csv'));
Risk_Free_Rate = readtable(fullfile(Path_Data_01, 'Risk_Free_Rate.csv'));

% RND
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllK = [];
Smooth_AllR = [];
Smooth_AllR_RND = [];

years_to_merge = 1996:2014;

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
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料');
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
max_knot = max(Realized_Return.realized_ret(1:ret_size));

clear Aggregate_Smooth_AllR


%% Plot: Setting

% Specify the month to plot
t = 63;

months = Smooth_AllR.Properties.VariableNames;

current_month_realized_ret = Realized_Return{t, 2};
current_month_y = Smooth_AllR{1, months{t}};
current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

TTM = 29 / 365;
RF = Risk_Free_Rate{t, 3};

current_month = months{t};

min_y = min(current_month_y_filtered);
max_y = max(current_month_y_filtered);

% Define Color of Each Line
o = [0.9290 0.6940 0.1250];
p = [0.4940 0.1840 0.5560];
color_All = {'b', 'g', 'm', 'c', 'y', 'k', 'r', o, p};


%% Plot: (1) Cubic B-Spline with g function value (2) Plot: g Function and SDF

for b = 3:8

    % Calculation
    y_BS = nan(b + 1, length(current_month_y_filtered));

    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y_filtered);
    end
    clear i

    % Calculate the value of g function
    theta_hat_var_name = ['theta_hat_', num2str(b)];
    g_function_value = sum(transpose(eval(theta_hat_var_name)) .* y_BS, 1);

    % Calculate the value of SDF
    SDF = exp(- RF .* TTM) .* (1 ./ g_function_value);

    % Specific folder
    Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料');
    Path_CDI = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method）');
    addpath(Path_CDI);


    % - - - - - Plot: Cubic B-Spline with g function value - - - - -

    Cubic_BSpline_Basis_Functions_g = figure;

    % Plot Figure: Each Cubic B-Spline Basis Function
    max_y_value = -Inf;  % Initialize a variable to keep track of the maximum y value
    for i = 1:(b + 1)
        plot(current_month_y_filtered, y_BS(i, :), ...
             'LineStyle', '-', ...
             'LineWidth', 1, ...
             'Color', color_All{i})
        hold on
        max_y_value = max(max_y_value, max(y_BS(i, :)));  % Update the max y value if needed
    end
    grid on

    % Plot Figure: g function value
    plot(current_month_y_filtered, g_function_value, ...
         'LineStyle', ':', ...
         'LineWidth', 3, ...
         'Color', 'r')
    hold on
    max_y_value = max(max_y_value, max(g_function_value));  % Include the g function in the max y value calculation
    min_y_value = min(ylim);

    % Set the ylim to 120% of the maximum y value
    ylim([min(ylim), 1.5 * max_y_value])


    % Add vertical lines at x = 0.9 and x = 1.06
    x_vals = [0.9, 1.06];
    for j = 1:length(x_vals)    
        plot([x_vals(j), x_vals(j)], [min_y_value, 1.2 * max_y_value], '--', 'LineWidth', 0.8, 'Color', [0.5 0.5 0.5])
        text(x_vals(j), 1.21 * max_y_value, [num2str(x_vals(j))], ...
             'VerticalAlignment', 'bottom', ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 11, ...
             'FontName', 'Times New Roman', ...
             'FontWeight', 'Bold', ...
             'Color', [0.5 0.5 0.5])
    end

    % Add Title
    title(['Cubic B-Spline Basis Functions and g for ' num2str(current_month) ' (b = ' num2str(b) ')'], ...
          'FontSize', 15, ...
          'FontName', 'Times New Roman', ...
          'FontWeight', 'Bold')

    % Legend Setting
    for i = 1:(b + 2)
        if i < (b + 2)
            type_legend{i} = ['$B^{' num2str(n) '}_{' num2str(i - 1) '} (y)$'];
        else
            type_legend{i} = ['$\sum_{i=0}^{' num2str(b) '} \theta_{i} B^{' num2str(n) '}_{i} (y)$'];
        end
    end
    h = legend(type_legend);
    clear type_legend

    set(h, 'FontSize', 12, ...
           'FontName', 'Times New Roman', ...
           'FontWeight', 'Bold', ...
           'Interpreter', 'Latex', ...
           'Box', 'Off', ...
           'Location', 'northwest', ...
           'NumColumns', 2)
    clear h

    set(gca, 'Layer', 'Top')
    set(gca, 'LooseInset', get(gca, 'TightInset'))
    % set(gcf, 'Position', get(0, 'ScreenSize'))

    % Clear Variable
    clear i

    filename = ['Cubic_BSpline_Basis_Functions_g (' num2str(current_month) ') (b=' num2str(b) ').png'];
    saveas(Cubic_BSpline_Basis_Functions_g, fullfile(Path_Output, filename));
    clear filename


    % - - - - - Plot: g Function and SDF - - - - -

    g_and_SDF = figure;

    % Plot Figure: g function value
    plot(current_month_y_filtered, g_function_value, ...
         'LineStyle', '--', ...
         'LineWidth', 2, ...
         'Color', 'r')
    hold on

    % Plot Figure: SDF as a scatter plot
    scatter(current_month_y_filtered, SDF, ...
            'Marker', '.', ...
            'MarkerEdgeColor', 'b', ...
            'LineWidth', 0.2)
    hold on

    % Set x-axis limits
    xlim([0.9, 1.06])
    ylim([0, 3])

    % Add Title
    title(['g Function and SDF for ' num2str(current_month) ' (b = ' num2str(b) ')'], ...
          'FontSize', 15, ...
          'FontName', 'Times New Roman', ...
          'FontWeight', 'Bold')

    set(gca, 'Layer', 'Top')
    set(gca, 'LooseInset', get(gca, 'TightInset'))
    % set(gcf, 'Position', get(0, 'ScreenSize'))

    grid on

    legend({'g Function', 'SDF'}, ...
           'Location', 'best', ...
           'Box', 'Off', ...
           'FontSize', 11, ...
           'FontName', 'Times New Roman')

    % Clear Variable
    clear i

    filename = ['g_and_SDF (' num2str(current_month) ') (b=' num2str(b) ').png'];
    saveas(g_and_SDF, fullfile(Path_Output, filename));
    clear filename

end
