function theta_hat = gmm_theta_estimation(months, Smooth_ALLR, Smooth_AllR_RND, b)

    theta0 = rand(1, b);                                                   % Initial parameters
    
    % Optimization options
    options = optimoptions('fminunc', 'Display', 'iter', 'Algorithm', 'quasi-newton');
    
    % Minimize the objective function
    [theta_hat, ~] = fminunc(@(theta) gmm_objective_function(theta, months, Smooth_ALLR, Smooth_AllR_RND, b), ...
        theta0,...
        options);

end