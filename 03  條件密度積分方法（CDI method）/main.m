clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Step 1: Load the data

Path_Data = fullfile(Path_MainFolder, 'Code', '02  風險中立密度（RND）');
FileName = 'Output_Tables.mat';
Data_RND = load(fullfile(Path_Data, FileName));

% Extract the variable names (months)
months = Data_RND.Table_Smooth_RND.Properties.VariableNames;

% Extract the data from the tables
Smooth_ret = Data_RND.Table_Smooth_ret;
Smooth_RND = Data_RND.Table_Smooth_RND;


%% Step 2: Define the knots for the B-spline

order = 3;                                                                 % Order of the B-spline (cubic B-spline)
b = 4;                                                                     % Calculate the number of basis functions (b)

All_Smooth_ret = Smooth_ret.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_value = min(All_Smooth_ret(All_Smooth_ret > 0));

% Find the maximum realized return within the sample
max_value = max(All_Smooth_ret);

num_knots = order + b + 1;
knots = linspace(min_value, max_value, num_knots);

clear All_Smooth_ret


%% Step 3: Create the B-spline basis matrix

B = spmak(knots, eye(b));                                                  % Spline basis matrix

% Evaluate the basis functions at the data points
B_data = fnval(B, knots);


%% Step 4: Define the moment conditions function

function g = moment_conditions(theta, data, B, b, F_Q)
    T = length(data);
    m = b; % Number of moment conditions
    g = zeros(m, 1);
    
    for j = 1:m
        moment_sum = 0;
        for t = 1:T
            g_t = sum(theta .* arrayfun(@(i) integral(@(y) B{i}(y), -Inf, data(t)) * F_Q(data(t)), 1:length(theta)));
            moment_sum = moment_sum + (g_t)^j;
        end
        g(j) = moment_sum / T - 1 / (j + 1);
    end
end


%% Step 5: Define the objective function

function J = gmm_objective(theta, data, B, F_Q, W)
    g = moment_conditions(theta, data, B, F_Q);
    J = g' * W * g; % Objective function
end


%% Step 6: Initial parameters

theta0 = rand(length(B_data), 1); % Initial parameters

% Initial weighting matrix
W = eye(length(theta0)); % Weighting matrix


%% Step 7: Minimize the objective function

options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');
[theta_hat, fval] = fminunc(@(theta) gmm_objective(theta, Smooth_ret.("19960117"), B, @(y) normcdf(y, mean(Smooth_ret.("19960117")), std(Smooth_ret.("19960117"))), W), theta0, options);

% Display estimated parameters
disp('Estimated parameters:')
disp(theta_hat)
