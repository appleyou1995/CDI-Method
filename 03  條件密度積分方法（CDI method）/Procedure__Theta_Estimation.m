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

n = 3;                                                                     % Order of the B-spline (cubic B-spline)
b = 3;                                                                     % Calculate the number of basis functions (b + 1)

Aggregate_Smooth_ALLR = Smooth_ALLR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_ALLR);

% Find the maximum realized return within the sample
max_knot = max(Aggregate_Smooth_ALLR);                                     % To be modified

clear Aggregate_Smooth_ALLR


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

function g = GMM_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b, min_knot, max_knot)

    months = Smooth_ALLR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m + 1, 1);

    for j = 1:(m + 1)
        moment_sum = 0;

        for t = 1:T
            current_month_y = Smooth_ALLR{1, months{t}};
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

function J = GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b, min_knot, max_knot)

    g = GMM_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b, min_knot, max_knot);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b + 1);

    % Objective function
    J = g' * W * g;
end


%% Step 6: Initial parameters

theta0 = rand(1, b + 1);                                                       % Initial parameters


%% Step 7: Minimize the objective function

% Optimization options
options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');

% Minimize the objective function
theta_hat = fminunc(@(theta) GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b, min_knot, max_knot), theta0, options);

% Display estimated parameters
disp('Estimated parameters:');
disp(theta_hat);


%% Summarize step 4 - step 7 above with one function

theta_hat = GMM_theta_estimation(months, Smooth_ALLR, Smooth_AllR_RND, b, min_knot, max_knot);

disp('Estimated parameters:');
disp(theta_hat);