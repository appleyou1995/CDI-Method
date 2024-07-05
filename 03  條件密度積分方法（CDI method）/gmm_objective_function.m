function J = gmm_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b)

    g = gmm_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b);

    % Objective function
    J = g' * W * g;

end