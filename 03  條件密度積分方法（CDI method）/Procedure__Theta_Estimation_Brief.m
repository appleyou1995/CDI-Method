clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

Path_Data = fullfile(Path_MainFolder, 'Code', '02  輸出資料');

Smooth_AllK = [];
Smooth_AllR = [];
Smooth_AllR_RND = [];

years_to_merge = 1996:2014;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data, sprintf('Output_Tables_%d.mat', year));
        
    if exist(input_filename, 'file')
        data = load(input_filename);
        
        Smooth_AllK = [Smooth_AllK, data.Table_Smooth_AllK];
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
        Smooth_AllR_RND = [Smooth_AllR_RND, data.Table_Smooth_AllR_RND];
    else
        warning('File %s does not exist.', input_filename);
    end
end


%% Define the knots for the B-spline

n = 3;                                                                     % Order of the B-spline (cubic B-spline)
b = 4;                                                                     % Calculate the number of basis functions (b + 1)

Aggregate_Smooth_AllR = Smooth_AllR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = max(Aggregate_Smooth_AllR);                                     % To be modified

clear Aggregate_Smooth_AllR


%% Summarize step 3 - step 7 above with one function

Path_CDI = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method）');
addpath(Path_CDI);

theta_hat = GMM_theta_estimation(Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot);

disp('Estimated parameters:');
disp(theta_hat);


%% Plot

% Specify the month to plot
t = 1;
months = Smooth_AllR.Properties.VariableNames;
current_month_y = Smooth_AllR{1, months{t}};
current_month = months{t};

min_y = min(current_month_y);
max_y = max(current_month_y);

y_BS = nan(b + 1, length(current_month_y));

for i = 1:(b + 1)
    y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, current_month_y);
end
clear i

% Define Color of Each Line
color_All = ['b'; 'g'; 'm'; 'c'; 'y'; 'k'; 'r'];

% Plot Figure: Each Cubic B-Spline Basis Function
for i = 1:(b + 1)
    plot(current_month_y, y_BS(i, :), ...
         'LineStyle', '-', ...
         'LineWidth', 1, ...
         'Color', color_All(i))
    hold on
end
grid on

% Plot Figure: A Cubic B-Spline Curve
y = sum(transpose(theta_hat) .* y_BS, 1);
plot(current_month_y, y, ...
     'LineStyle', ':', ...
     'LineWidth', 3, ...
     'Color', 'r')
hold on

% Add Title
title(['Cubic B-Spline Basis Functions and Curve for ' num2str(current_month)], ...
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

set(h, 'FontSize', 15, ...
       'FontName', 'Times New Roman', ...
       'FontWeight', 'Bold', ...
       'Interpreter', 'Latex', ...
       'Box', 'Off')
clear h 

set(gca, 'Layer', 'Top')
set(gca, 'LooseInset', get(gca, 'TightInset'))
% set(gcf, 'Position', get(0, 'ScreenSize'))

% Clear Variable
clear color_All
clear i 