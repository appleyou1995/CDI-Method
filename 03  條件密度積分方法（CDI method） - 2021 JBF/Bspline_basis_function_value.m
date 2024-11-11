function B_value = Bspline_basis_function_value(n, b, min_knot, max_knot, function_index, y)

    num_knots = n + b + 2;

    % Initialize knots
    knots = linspace(min_knot, max_knot, num_knots);

    % Find the index of inner knot points
    middle_index = ceil((num_knots + 1) / 2);                                    % Way 1
    % middle_index = floor((num_knots + 1) / 2);                                   % Way 2
    
    % Set the open uniform (left side)
    knots(1:(middle_index - 1)) = knots(1);

    % Set the open uniform (right side)
    knots((middle_index + 1):end) = knots(end);

    i = function_index;
    % B_value = zeros(size(y));
    B_value = OBJ_BS_D3(y, i, knots);

end


%% Degree = 3

function BS_D3 = OBJ_BS_D3(y, i, knots)

    FCN1 = power(y - knots(i), 1)   .* power(knots(i+3) - knots(i), -1)   .* OBJ_BS_D2(y, i, knots);    
    FCN2 = power(knots(i+4) - y, 1) .* power(knots(i+4) - knots(i+1), -1) .* OBJ_BS_D2(y, i+1, knots);
    
    BS_D3 = FCN1 + FCN2;
    
    if (knots(i) < knots(i+3)) && (knots(i+1) == knots(i+4))
        BS_D3 = FCN1;
    elseif (knots(i) == knots(i+3)) && (knots(i+1) < knots(i+4))
        BS_D3 = FCN2;
    elseif (knots(i) == knots(i+4))
        BS_D3 = zeros(size(y));
    end
    
    clear FCN1 FCN2

end


%% Degree = 2

function BS_D2 = OBJ_BS_D2(y, i, knots)

    FCN1 = power(y - knots(i), 1)   .* power(knots(i+2) - knots(i), -1)   .* OBJ_BS_D1(y, i, knots);    
    FCN2 = power(knots(i+3) - y, 1) .* power(knots(i+3) - knots(i+1), -1) .* OBJ_BS_D1(y, i+1, knots);    
    
    BS_D2 = FCN1 + FCN2;

    if (knots(i) < knots(i+2)) && (knots(i+1) == knots(i+3))
        BS_D2 = FCN1;
    elseif (knots(i) == knots(i+2)) && (knots(i+1) < knots(i+3))
        BS_D2 = FCN2;
    elseif (knots(i) == knots(i+3))
        BS_D2 = zeros(size(y));
    end
    
    clear FCN1 FCN2

end


%% Degree = 1

function BS_D1 = OBJ_BS_D1(y, i, knots)
    
    FCN1 = power(y - knots(i), 1)   .* power(knots(i+1) - knots(i), -1)   .* OBJ_BS_D0(y, i, knots);    
    FCN2 = power(knots(i+2) - y, 1) .* power(knots(i+2) - knots(i+1), -1) .* OBJ_BS_D0(y, i+1, knots);    
    
    BS_D1 = FCN1 + FCN2;

    if (knots(i) < knots(i+1)) && (knots(i+1) == knots(i+2))
        BS_D1 = FCN1;
    elseif (knots(i) == knots(i+1)) && (knots(i+1) < knots(i+2))
        BS_D1 = FCN2;
    elseif (knots(i) == knots(i+2))
        BS_D1 = zeros(size(y));
    end
    
    clear FCN1 FCN2

end


%% Degree = 0

function BS_D0 = OBJ_BS_D0(y, i, knots)

    BS_D0 = zeros(size(y));
    BS_D0(y >= knots(i) & y <= knots(i+1)) = 1;

end