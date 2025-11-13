%% Main Function: GMM Theta Estimation

function theta_hat = GMM_theta_estimation(Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    % Fix random seed
    rng(0);

    % Initial parameter vector
    theta0 = rand(1, b + 1);

    % Precompute all quantities independent of theta (including B-splines)
    pre = precompute_GMM_inputs_bspline(Smooth_AllR, Smooth_AllR_RND, ...
        Realized_Return, b, min_knot, max_knot);

    % Optimization options
    options = optimoptions('fmincon', ...
        'Display', 'iter', ...
        'Algorithm', 'sqp');

    lb = [];
    ub = [];
    
    % Minimize the objective function with nonlinear constraints
    theta_hat = fmincon( ...
        @(theta) GMM_objective_fast(theta, pre), ...
        theta0, [], [], [], [], lb, ub, ...
        @(theta) nonlinear_constraint_fast(theta, pre), ...
        options);

end


%% Local Function: GMM Objective Function

function J = GMM_objective_fast(theta, pre)

    % Ensure column vector
    theta = theta(:);

    % Compute g_theta_t = Σ_i θ_i * I_{t,i}  (matrix multiplication)
    g_theta_vec = pre.I * theta;                                           % T × 1

    valid = pre.validI & ~isnan(g_theta_vec) & ~isinf(g_theta_vec);
    vals  = g_theta_vec(valid);

    m = pre.b;                                                             % Moment order m = b
    g = zeros(m + 1, 1);

    if ~isempty(vals)
        for j = 1:(m + 1)
            g(j) = mean(vals.^j) - 1/(j + 1);
        end
    else
        g(:) = NaN;
    end
    
    % First-stage GMM with identity weighting matrix
    J = g' * g;
end


%% Local Function: Precompute B-splines and integrals using spcol

function pre = precompute_GMM_inputs_bspline(Smooth_AllR, Smooth_AllR_RND, ...
    Realized_Return, b, min_knot, max_knot)

    months = Smooth_AllR.Properties.VariableNames;
    T      = length(months);

    % B-spline setting
    n = 3;                                                                 % degree = 3
    k = n + 1;                                                             % order = 4
    num_knots = n + b + 2;

    % Open uniform knot vector
    knots = linspace(min_knot, max_knot, num_knots);
    knots(1:(n+1))       = min_knot;                                       % left-side open uniform
    knots((end-n):end)   = max_knot;                                       % right-side open uniform

    % Preallocate
    I      = nan(T, b + 1);
    validI = false(T, 1);
    Bmat   = cell(T, 1);

    for t = 1:T
        try
            current_month_realized_ret = Realized_Return{t, 2};
            if isnan(current_month_realized_ret)
                continue
            end

            y_all = Smooth_AllR{1, months{t}}(:);
            f_all = Smooth_AllR_RND{1, months{t}}(:);

            % Keep only values y <= realized return
            idx = y_all <= current_month_realized_ret;
            if ~any(idx)
                continue
            end

            y  = y_all(idx);
            fq = f_all(idx);

            % Ensure sorted (trapz more stable)
            [y, order] = sort(y);
            fq = fq(order);

            % Compute all B-splines at once: (#y × (b+1))
            B = spcol(knots, k, y);

            if size(B, 2) ~= (b + 1)
                warning('spcol returned inconsistent basis count: size(B,2)=%d, expected=%d', ...
                    size(B,2), b+1);
            end

            % Compute integrals ∫ B_i(y) f^Q(y) dy
            for i = 1:(b + 1)
                Ii = trapz(y, B(:, i) .* fq);
                if isnan(Ii) || isinf(Ii)
                    I(t, i) = NaN;
                else
                    I(t, i) = Ii;
                end
            end

            if any(isnan(I(t,:))) || any(isinf(I(t,:)))
                continue
            end

            validI(t) = true;
            Bmat{t}   = B;

        catch ME
            warning('Error in precompute at t=%d (%s): %s', ...
                t, months{t}, ME.message);
            continue
        end
    end

    pre.I       = I;
    pre.validI  = validI;
    pre.Bmat    = Bmat;
    pre.T       = T;
    pre.b       = b;
    pre.epsilon = 1e-6;
end


%% Local Function: nonlinear_constraint

function [c, ceq] = nonlinear_constraint_fast(theta, pre)

    theta = theta(:);
    T     = pre.T;
    c     = zeros(T, 1);
    ceq   = [];
    eps0  = pre.epsilon;

    for t = 1:T
        B = pre.Bmat{t};                                                   % (#grid_t × (b+1))
        if isempty(B)
            c(t) = 0;                                                      % Skip constraints for this month
            continue
        end

        g_vals = B * theta;                                                % (#grid_t × 1)
        if any(isnan(g_vals)) || any(isinf(g_vals))
            c(t) = 0;
        else
            % Constraint: min(g_theta) >= eps0 → c(t) = -(min - eps0)
            c(t) = -(min(g_vals) - eps0);
        end
    end
end