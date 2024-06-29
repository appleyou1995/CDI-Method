function B_splines = generate_B_splines(degree)
    
    % Check if the input degree is valid
    if degree < 1
        error('The degree must be greater than or equal to 1');
    end
    
    % Define symbolic variable
    syms y
    
    % Initial B-spline basis functions
    B_splines = cell(degree + 1, 1);
    for i = 1:(degree + 1)
        B_splines{i} = piecewise(y >= (i-2) & y < (i-1), 1, 0);
    end
    
    % Recursive algorithm to generate B-spline basis functions
    for k = 1:degree
        B_new = cell(degree - k + 1, 1);
        for i = 1:(degree - k + 1)
            B_new{i} = ((y - (i-2)) / k) * B_splines{i} + (((i + k - 1) - y) / k) * B_splines{i+1};
        end
        B_splines = B_new;
    end
end
