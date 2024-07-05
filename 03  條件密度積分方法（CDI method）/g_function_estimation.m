function All_g_hat = g_function_estimation(theta_hat, Smooth_ALLR, b)
    
    months = Smooth_ALLR.Properties.VariableNames;
    T = length(months);
    B = Bspline_basis_functions(b);
    All_g_hat = table();

    for t = 1:T

        current_month_y = Smooth_ALLR{1, months{t}};
        B_matrix = zeros(length(current_month_y), b);
        
        for i = 1:b
            B_function = matlabFunction(B{i});
            B_matrix(:, i) = B_function(current_month_y);
        end
        
        g_hat = (B_matrix * theta_hat(:)).';

        columnName = num2str(months{t});
        All_g_hat.(columnName) = g_hat;

    end

end