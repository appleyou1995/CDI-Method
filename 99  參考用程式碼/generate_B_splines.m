function B_splines = generate_B_splines(degree)

    % Check if the input degree is valid
    if degree < 1
        error('The degree must be greater than or equal to 1');
    end
    
    % Define symbolic variable
    syms y
    
    % Initialize the knot vector
    t = 0:(degree+1); % Assume uniform knot vector for simplicity
    
    % Initialize the B-spline basis functions
    B_splines = cell(degree + 1, 1);
    for i = 1:(degree + 1)
        B_splines{i} = piecewise(t(i) <= y < t(i+1), 1, 0);
    end
    
    % Recursive algorithm to generate B-spline basis functions
    for k = 1:degree
        B_new = cell(degree - k + 1, 1);
        for i = 1:(degree - k + 1)
            B_new{i} = ((y - t(i)) / (t(i+k) - t(i))) * B_splines{i} + ...
                       ((t(i+k+1) - y) / (t(i+k+1) - t(i+1))) * B_splines{i+1};
        end
        B_splines = B_new;
    end
    
    % Normalize the B-spline basis functions
    for i = 1:length(B_splines)
        B_splines{i} = simplify(B_splines{i});
    end
end