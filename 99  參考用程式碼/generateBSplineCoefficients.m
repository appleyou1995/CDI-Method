function B = generateBSplineCoefficients(b)
    % Generate the coefficient matrix for (b-1)-order B-spline basis functions
    % b is the order plus one
    
    % Initialize the coefficient matrix
    B = zeros(b, b);
    
    % Generate basis functions
    for j = 1:b
        for k = 0:(j-1)
            B(j, b - k) = nchoosek(j - 1, k) * (-1)^k;
        end
    end
    
    % Calculate coefficients
    for j = 1:b
        B(j, :) = B(j, :) * nchoosek(b - 1, j - 1);
    end
    
    % Adjust factor
    % B = B / factorial(b - 1);
end
