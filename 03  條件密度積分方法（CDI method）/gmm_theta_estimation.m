function theta_hat = gmm_theta_estimation(months, Smooth_ALLR, Smooth_AllR_RND, b)
    
    % Set the seed for the random number generator
    rng(0);

    % Initial parameters
    theta0 = rand(1, b);
    
    % Optimization options
    options = optimoptions('fminunc', 'Display', 'off', 'Algorithm', 'quasi-newton');
    
    % Minimize the objective function
    theta_hat = fminunc(@(theta) gmm_objective_function(theta, months, Smooth_ALLR, Smooth_AllR_RND, b), theta0, options);

end