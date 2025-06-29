%% GMM Objective Function

function J = GMM_objective_fixed_alpha_beta(theta, Smooth_AllR, Smooth_AllR_RND, ...
    Realized_Return, b, min_knot, max_knot, alpha, beta)

    params = [theta, alpha, beta];
    g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, ...
        Realized_Return, b, min_knot, max_knot);

    W = eye(length(g));
    J = g' * W * g;
end