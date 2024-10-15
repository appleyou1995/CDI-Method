function B_value = Bspline_basis_function_value(n, b, min_knot, max_knot, function_index, y)

    num_knots = n + b + 2;
    knots = linspace(min_knot, max_knot, num_knots);
    h = (max_knot - min_knot) / (num_knots - 1);
    i = function_index;

    B_value = zeros(size(y));

    cond1 = (y > knots(i)) & (y <= knots(i+1));
    B_value(cond1) = (1 / (6 * h^3)) * (y(cond1) - knots(i)).^3;

    cond2 = (y > knots(i+1)) & (y <= knots(i+2));
    B_value(cond2) = (2/3) - (1 / (2 * h^3)) * (y(cond2) - knots(i)) .* (knots(i+2) - y(cond2)).^2;

    cond3 = (y > knots(i+2)) & (y <= knots(i+3));
    B_value(cond3) = (2/3) - (1 / (2 * h^3)) * (knots(i+4) - y(cond3)) .* (y(cond3) - knots(i+2)).^2;

    cond4 = (y > knots(i+3)) & (y <= knots(i+4));
    B_value(cond4) = (1 / (6 * h^3)) * (knots(i+4) - y(cond4)).^3;

end