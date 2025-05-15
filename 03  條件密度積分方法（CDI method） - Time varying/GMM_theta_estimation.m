%% Main Function: GMM Theta Estimation

function theta_hat = GMM_theta_estimation(Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    % Set the seed for the random number generator
    rng(0);

    % Initial parameters
    theta0 = rand(1, b + 1);

    % Optimization options
    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');

    % --------------------------------Way 1--------------------------------
    % % Lower bound (non-negative constraints)
    % lb = zeros(1, b + 1);  % Lower bound set to 0 (non-negative)
    % 
    % % No upper bound (can set this if needed)
    % ub = [];  % No upper bound
    % 
    % % Minimize the objective function
    % theta_hat = fmincon(...
    %     @(theta) GMM_objective_function(theta, Smooth_AllR, Smooth_AllR_RND, ...
    %     Realized_Return, b, min_knot, max_knot), ...
    %     theta0, [], [], [], [], lb, ub, [], options);

    % --------------------------------Way 2--------------------------------
    lb = [];  % No lower bound
    ub = [];  % No upper bound
    
    % Minimize the objective function with nonlinear constraints
    theta_hat = fmincon(...
        @(theta) GMM_objective_function(theta, Smooth_AllR, Smooth_AllR_RND, ...
        Realized_Return, b, min_knot, max_knot), ...
        theta0, [], [], [], [], lb, ub, ...
        @(theta) nonlinear_constraint(theta, Smooth_AllR, Realized_Return, b, min_knot, max_knot), ...
        options);

end


%% Local Function: GMM Objective Function

function J = GMM_objective_function(theta, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    g = GMM_moment_conditions(theta, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b + 1);

    % Objective function
    J = g' * W * g;
end


%% Local Function: GMM Moment Conditions

function g = GMM_moment_conditions(theta, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m + 1, 1);

    for j = 1:(m + 1)
        moment_sum = 0;
        valid_T = 0;  % 記錄有效月份數

        for t = 1:T
            try
                current_month_realized_ret = Realized_Return{t, 2};
                if isnan(current_month_realized_ret)
                    continue
                end

                current_month_y = Smooth_AllR{1, months{t}}(:);  % 強制轉 column vector
                current_month_RND = Smooth_AllR_RND{1, months{t}}(:);

                idx = current_month_y <= current_month_realized_ret;
                if sum(idx) == 0
                    continue
                end

                current_month_y_filtered = current_month_y(idx);
                current_month_RND_filtered = current_month_RND(idx);

                if length(current_month_y_filtered) ~= length(current_month_RND_filtered)
                    continue
                end

                g_theta = 0;

                for i = 1:(b + 1)
                    B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
                    if any(isnan(B_values))
                        warning('NaN in B_values at t=%d, month=%s', t, months{t});
                        g_theta = NaN;
                        break
                    end
                    integral = trapz(current_month_y_filtered, B_values .* current_month_RND_filtered);
                    if isnan(integral) || isinf(integral)
                        g_theta = NaN;
                        break
                    end
                    g_theta = g_theta + theta(i) * integral;
                end

                if isnan(g_theta) || isinf(g_theta)
                    continue
                end

                moment_sum = moment_sum + g_theta^j;
                valid_T = valid_T + 1;

            catch ME
                warning('Error at t=%d (%s): %s', t, months{t}, ME.message);
                continue
            end
        end

        if valid_T > 0
            g(j) = moment_sum / valid_T - 1 / (j + 1);
        else
            g(j) = NaN;  % 若完全沒有有效月份，就直接報 NaN
        end
    end
end


%% Local Function: nonlinear_constraint

function [c, ceq] = nonlinear_constraint(theta, Smooth_AllR, Realized_Return, b, min_knot, max_knot)

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    c = zeros(T, 1);
    ceq = [];

    epsilon = 1e-6;

    for t = 1:T
        try
            current_month_realized_ret = Realized_Return{t, 2};
            if isnan(current_month_realized_ret)
                c(t) = 0;  % 不加入限制
                continue
            end

            current_month_y = Smooth_AllR{1, months{t}}(:);  % 強制 column vector
            idx = current_month_y <= current_month_realized_ret;
            if sum(idx) == 0
                c(t) = 0;  % 無資料，略過
                continue
            end

            current_month_y_filtered = current_month_y(idx);

            g_theta = zeros(length(current_month_y_filtered), 1);

            for i = 1:(b + 1)
                B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
                if any(isnan(B_values))
                    warning('NaN in B_values at t=%d, month=%s', t, months{t});
                    g_theta = NaN;
                    break
                end
                g_theta = g_theta + theta(i) * B_values;
            end

            if any(isnan(g_theta)) || any(isinf(g_theta))
                c(t) = 0;  % 不加限制
                continue
            end

            % Constraint: g_theta ≥ ε  →  min(g_theta) - ε ≥ 0
            c(t) = -(min(g_theta) - epsilon);

        catch ME
            warning('Error in constraint at t=%d (%s): %s', t, months{t}, ME.message);
            c(t) = 0;  % 出錯時略過該限制
            continue
        end
    end
end


