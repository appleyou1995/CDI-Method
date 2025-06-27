%% Main Function: GMM Theta Estimation

function theta_hat = GMM_theta_estimation_fixed_alpha_beta(...
    Smooth_AllR_train, Smooth_AllR_RND_train, Realized_Return_train,...
    b, min_knot, max_knot, alpha, beta)

    rng(0);
    theta0 = rand(1, b + 1);

    lb = [];  % No lower bound
    ub = [];  % No upper bound

    options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp');

    theta_hat = fmincon(...
        @(theta) GMM_objective_fixed_alpha_beta(theta, Smooth_AllR_train, ...
        Smooth_AllR_RND_train, Realized_Return_train, ...
        b, min_knot, max_knot, alpha, beta), ...
        theta0, [], [], [], [], lb, ub, ...
        @(theta) nonlinear_constraint_theta_only(theta, Smooth_AllR_train, ...
        Realized_Return_train, b, min_knot, max_knot), ...
        options);
end


%% Local Function: GMM Objective Function

function J = GMM_objective_fixed_alpha_beta(theta, Smooth_AllR, Smooth_AllR_RND, ...
    Realized_Return, b, min_knot, max_knot, alpha, beta)

    params = [theta, alpha, beta];
    g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, ...
        Realized_Return, b, min_knot, max_knot);

    W = eye(length(g));
    J = g' * W * g;
end


%% Local Function: GMM Moment Conditions

function g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    theta = params(1:b+1);
    alpha = params(b+2);
    beta  = params(b+3);

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m + 1, 1);

    for j = 0:m
        moment_sum = 0;
        valid_T = 0;

        for t = 1:T
            try
                current_month_realized_ret = Realized_Return{t, 2};
                if isnan(current_month_realized_ret)
                    continue
                end

                current_month_y = Smooth_AllR{1, months{t}}(:);
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

                if isnan(g_theta) || isinf(g_theta) || g_theta <= 0
                    continue
                end

                % distortion function 應用
                g_distorted = distortion_inverse(g_theta, alpha, beta);

                moment_sum = moment_sum + g_distorted^(j + 1);
                valid_T = valid_T + 1;

            catch ME
                warning('Error at t=%d (%s): %s', t, months{t}, ME.message);
                continue
            end
        end

        if valid_T > 0
            g(j + 1) = moment_sum / valid_T - 1 / (j + 2);
        else
            g(j + 1) = NaN;
        end
    end
end


%% Local Function: Distortion Function Inverse

function D_inv = distortion_inverse(x, alpha, beta)

    D_inv = exp(-(-log(x)).^(1/alpha) / beta);

end


%% Local Function: nonlinear_constraint

function [c, ceq] = nonlinear_constraint_theta_only(theta, Smooth_AllR, Realized_Return, b, min_knot, max_knot)

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    c = zeros(T, 1);
    ceq = [];

    epsilon = 1e-6;

    for t = 1:T
        current_month_realized_ret = Realized_Return{t, 2};
        current_month_y = Smooth_AllR{1, months{t}};

        current_month_y_filtered = current_month_y(current_month_y <= current_month_realized_ret);

        if isempty(current_month_y_filtered)
            c(t) = -epsilon;
            continue
        end

        g_theta = zeros(1, length(current_month_y_filtered));

        for i = 1:(b + 1)
            B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
            g_theta  = g_theta + theta(i) * B_values;
        end

        c(t) = -(min(g_theta) - epsilon);
    end
end

