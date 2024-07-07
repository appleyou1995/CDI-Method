%% Main Function: GMM Theta Estimation

function theta_hat = GMM_theta_estimation(Smooth_ALLR, Smooth_AllR_RND, b)

    % Set the seed for the random number generator
    rng(0);

    % Initial parameters
    theta0 = rand(1, b);
    
    % Optimization options
    options = optimoptions('fminunc', 'Display', 'off', 'Algorithm', 'quasi-newton');
    
    % Minimize the objective function
    theta_hat = fminunc(@(theta) GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b), theta0, options);

end


%% Local Function: GMM Objective Function

function J = GMM_objective_function(theta, Smooth_ALLR, Smooth_AllR_RND, b)

    g = GMM_moment_conditions(theta, Smooth_ALLR, Smooth_AllR_RND, b);

    % Use a GMM type optimization with only the first stage optimization
    W = eye(b);

    % Objective function
    J = g' * W * g;

end


%% Local Function: GMM Moment Conditions

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
