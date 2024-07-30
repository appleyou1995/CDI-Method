function B_splines = generate_bspline_basis(b)
    % generate_bspline_basis - Generate B-spline basis functions of order 3, 4, or 5
    %
    % Syntax: B_splines = generate_bspline_basis(b)
    %
    % Inputs:
    %    b - Order of the B-spline (3, 4, or 5)
    %
    % Outputs:
    %    B_splines - Cell array of symbolic B-spline basis functions

    syms y;
    
    switch b
        case 3
            B_splines = {
                (1/6) * (-y^3 + 3*y^2 - 3*y + 1);
                (1/6) * (3*y^3 - 6*y^2 + 4);
                (1/6) * (-3*y^3 + 3*y^2 + 3*y + 1);
                (1/6) * (y^3)
            };
        case 4
            B_splines = {
                (1/24) * (-y^4 + 4*y^3 - 6*y^2 + 4*y - 1);
                (1/24) * (4*y^4 - 12*y^3 + 12*y^2 - 4);
                (1/24) * (-6*y^4 + 12*y^3 + 6*y - 4);
                (1/24) * (4*y^4 + 4*y^3 + 4*y + 1);
                (1/24) * (y^4)
            };
        case 5
            B_splines = {
                (1/120) * (-y^5 + 5*y^4 - 10*y^3 + 10*y^2 - 5*y + 1);
                (1/120) * (5*y^5 - 20*y^4 + 30*y^3 - 20*y + 5);
                (1/120) * (-10*y^5 + 30*y^4 - 30*y^3 + 10);
                (1/120) * (10*y^5 - 20*y^4 + 30*y^3 + 20*y + 10);
                (1/120) * (-5*y^5 + 5*y^4 + 10*y^3 + 10*y^2 + 5*y + 1);
                (1/120) * (y^5)
            };
        otherwise
            error('Invalid order. Please enter 3, 4, or 5.');
    end
    
    % Display the basis functions
    for i = 1:length(B_splines)
        fprintf('B_%d(y) = %s\n', i, B_splines{i});
    end
end
