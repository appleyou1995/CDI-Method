clear; clc
Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Step 1: Load the data

Path_Data = fullfile(Path_MainFolder, 'Code', '02  風險中立密度（RND）');
FileName = 'Output_Tables.mat';
Data_RND = load(fullfile(Path_Data, FileName));

% Extract the variable names (months)
months = Data_RND.Table_Smooth_AllR_RND.Properties.VariableNames;

% Extract the data from the tables
Smooth_ALLR     = Data_RND.Table_Smooth_AllR;
Smooth_AllR_RND = Data_RND.Table_Smooth_AllR_RND;


%% Step 2: Define the knots for the B-spline

order = 3;                                                                 % Order of the B-spline (cubic B-spline)
b = 4;                                                                     % Calculate the number of basis functions (b)

Aggregate_Smooth_ALLR = Smooth_ALLR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_value = min(Aggregate_Smooth_ALLR);

% Find the maximum realized return within the sample
max_value = max(Aggregate_Smooth_ALLR);                                    % To be modified

num_knots = order + b + 1;                                                 % To be modified
knots = linspace(min_value, max_value, num_knots);                         % To be modified

clear Aggregate_Smooth_ALLR


%% Step 3: Create the B-spline basis matrix

Path_CDI = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method）');
addpath(Path_CDI);

B = Bspline_basis_functions(b);


%% Step 4: Define the moment conditions function

function g = GMM_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b)

    months = Smooth_ALLR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m, 1);
    B = Bspline_basis_functions(b);

    for j = 1:m
        moment_sum = 0;

        for t = 1:T
            current_month_y = Smooth_ALLR{1, months{t}};
            current_month_RND = Smooth_AllR_RND{1, months{t}};

            g_theta = 0;

            for i = 1:b        
                B_function = matlabFunction(B{i});
                B_values = B_function(current_month_y);
                
                integral = trapz(current_month_y, B_values .* current_month_RND);            
                g_theta = g_theta + theta(i) * integral;
            end

            moment_sum = moment_sum + g_theta ^ j;
        end

        g(j) = moment_sum / T - 1 / (j + 1);
    end
end


%% Step 5: Define the objective function

function J = GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b)

    g = GMM_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b);

    % Objective function
    J = g' * W * g;
end


%% Step 6: Initial parameters

theta0 = rand(1, b);                                                       % Initial parameters


%% Step 7: Minimize the objective function

% Optimization options
options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');

% Minimize the objective function
theta_hat = fminunc(@(theta) GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b), theta0, options);

% Display estimated parameters
disp('Estimated parameters:');
disp(theta_hat);


%% Summarize step 4 - step 7 above with one function

theta_hat = GMM_theta_estimation(months, Smooth_ALLR, Smooth_AllR_RND, b);

disp('Estimated parameters:');
disp(theta_hat);