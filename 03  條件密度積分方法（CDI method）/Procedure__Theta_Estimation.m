clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Step 1: Load the data

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


%% Step 2: Define the knots for the B-spline

n = 3;                                                                     % Order of the B-spline (cubic B-spline)
b = 3;                                                                     % Calculate the number of basis functions (b + 1)

Aggregate_Smooth_AllR = Smooth_AllR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = max(Aggregate_Smooth_AllR);                                     % To be modified

clear Aggregate_Smooth_AllR


%% Step 3: Calculate the value of basis function

function B_value = Bspline_basis_function_value(n, b, min_knot, max_knot, function_index, y)

    num_knots = n + b + 2;
    knots = linspace(min_knot, max_knot, num_knots);
    h = (max_knot - min_knot) / (num_knots - 1);
    i = function_index;

    B_value = zeros(size(y));

    cond1 = (y > knots(i)) & (y <= knots(i+1));
    B_value(cond1) = (1 / (6 * h^3)) * (y(cond1) - knots(i)).^3;

    cond2 = (y > knots(i+1)) & (y <= knots(i+2));
    B_value(cond2) = (2/3) - (1 / (2 * h^3)) * (y(cond2) - knots(i)) .* (knots(i+2) - y(cond2)).^2;

    cond3 = (y > knots(i+2)) & (y <= knots(i+3));
    B_value(cond3) = (2/3) - (1 / (2 * h^3)) * (knots(i+4) - y(cond3)) .* (y(cond3) - knots(i+2)).^2;

    cond4 = (y > knots(i+3)) & (y <= knots(i+4));
    B_value(cond4) = (1 / (6 * h^3)) * (knots(i+4) - y(cond4)).^3;

end


%% Step 4: Define the moment conditions function

function g = GMM_moment_conditions(theta, Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot)

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m + 1, 1);

    for j = 1:(m + 1)
        moment_sum = 0;

        for t = 1:T
            current_month_y = Smooth_AllR{1, months{t}};
            current_month_RND = Smooth_AllR_RND{1, months{t}};

            g_theta = 0;

            for i = 1:(b + 1)
                B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y);
                
                integral = trapz(current_month_y, B_values .* current_month_RND);            
                g_theta = g_theta + theta(i) * integral;
            end

            moment_sum = moment_sum + g_theta ^ j;
        end

        g(j) = moment_sum / T - 1 / (j + 1);
    end
end


%% Step 5: Define the objective function

function J = GMM_objective_function(theta, Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot)

    g = GMM_moment_conditions(theta, Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b + 1);

    % Objective function
    J = g' * W * g;
end


%% Step 6: Initial parameters

% Set the seed for the random number generator
rng(0);

% Initial parameters
theta0 = rand(1, b + 1);


%% Step 7: Minimize the objective function

% Optimization options
options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');

% Minimize the objective function
theta_hat = fminunc(@(theta) GMM_objective_function(theta, Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot), theta0, options);

% Display estimated parameters
disp('Estimated parameters:');
disp(theta_hat);


%% Summarize step 4 - step 7 above with one function

% Path_CDI = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method）');
% addpath(Path_CDI);
% 
% theta_hat = GMM_theta_estimation(Smooth_AllR, Smooth_AllR_RND, b, min_knot, max_knot);
% 
% disp('Estimated parameters:');
% disp(theta_hat);


%% Step 8: Specify the month to plot

t = 139;
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


%% Step 9: Plot

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
theta_test_1 = [1.282249525506515, 0.217086163722610, 0.0296, 0.6797];
theta_test_2 = rand(1, 4);
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