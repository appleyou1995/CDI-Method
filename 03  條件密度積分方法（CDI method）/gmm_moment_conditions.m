function g = gmm_moment_conditions(theta, months, Smooth_ALLR, Smooth_AllR_RND, b)

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