%% Main Function: GMM Joint Estimation

function params_hat = GMM_joint_estimation(Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    % Set the seed for the random number generator
    rng(0);

    % Define parameter vector (b+1 for theta, plus 2 for alpha and beta)
    params0 = rand(1, b + 3);                                              % First b+1 are theta, last two are alpha and beta

    % Optimization options
    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');

    % Define lower and upper bounds for parameters
    lb = [];
    ub = [];

    % Minimize the objective function with nonlinear constraints
    params_hat = fmincon(...
        @(params) GMM_objective_function(params, Smooth_AllR, Smooth_AllR_RND, ...
        Realized_Return, b, min_knot, max_knot), ...
        params0, [], [], [], [], lb, ub, ...
        @(params) nonlinear_constraint(params, Smooth_AllR, Realized_Return, b, min_knot, max_knot), ...
        options);
end


%% Local Function: GMM Objective Function

function J = GMM_objective_function(params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b + 3);

    % Objective function
    J = g' * W * g;
end


%% Local Function: GMM Moment Conditions

function g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    % Extract parameters
    theta = params(1:b+1);
    alpha = params(b+2);
    beta  = params(b+3);

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    m = b + 2;                                                             % Modify m to include the two extra parameters
    g = zeros(m + 1, 1);                                                   % Adjust moment conditions vector size

    for j = 0:m
        moment_sum = 0;

        for t = 1:T
            current_month_realized_ret = Realized_Return{t, 2};

            current_month_y = Smooth_AllR{1, months{t}};
            current_month_RND = Smooth_AllR_RND{1, months{t}};

            current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);
            filtered_size = length(current_month_y_filtered);
            current_month_RND_filtered = current_month_RND(1:filtered_size);

            g_theta = 0;

            for i = 1:(b + 1)
                B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
                integral = trapz(current_month_y_filtered, B_values .* current_month_RND_filtered);            
                g_theta = g_theta + theta(i) * integral;
            end

            % Apply inverse distortion function
            g_theta_inverse_distort = distortion_inverse(g_theta, alpha, beta);

            moment_sum = moment_sum + g_theta_inverse_distort ^ (j+1);
        end

        g(j+1) = moment_sum / T - 1 / (j + 2);
    end
end


%% Local Function: Distortion Function Inverse

function D_inv = distortion_inverse(x, alpha, beta)

    D_inv = exp(-(-log(x)).^(1/alpha) / beta);

end


%% Local Function: nonlinear_constraint

function [c, ceq] = nonlinear_constraint(params, Smooth_AllR, Realized_Return, b, min_knot, max_knot)
    
    % Extract parameters
    theta = params(1:b+1);
    
    % Initialize the constraint output
    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    c = zeros(T, 1);                                                       % Initialize empty inequality constraints
    ceq = [];                                                              % No equality constraints

    % Loop through each month to calculate g_theta and set constraints
    for t = 1:T
        current_month_realized_ret = Realized_Return{t, 2};
        current_month_y = Smooth_AllR{1, months{t}};

        % Filter values based on current month realized return
        current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

        % Initialize g_theta as a zero vector with the same length as B_values
        g_theta = zeros(1, length(current_month_y_filtered));

        % Calculate g_theta as a linear combination of B-spline basis values
        for i = 1:(b + 1)
            B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
            g_theta  = g_theta + theta(i) * B_values;
        end

        % Add the constraint  g_theta >= 0 
        % rewrite as          min(g_theta) >= epsilon      to avoid strict zero constraints
        % rewrite as          min(g_theta) - epsilon >= 0
        % rewrite as        -(min(g_theta) - epsilon) =< 0
        epsilon = 1e-6;                                                    % Small tolerance to ensure numerical stability
        c(t) = -(min(g_theta) - epsilon);                                  % Store constraint for month t
    end
end

