function g_hat = g_function_estimation(theta_hat, current_month_y, b, B)
    
    B_matrix = zeros(length(current_month_y), b);
    
    for i = 1:b
        B_function = matlabFunction(B{i});
        B_matrix(:, i) = B_function(current_month_y);
    end
    
    g_hat = (B_matrix * theta_hat(:)).';

end