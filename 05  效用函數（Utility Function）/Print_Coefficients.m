function Print_Coefficients(coefficients, names)
    
    for i = 1:length(coefficients)

        if coefficients(i) > 0
            result = '> 0';

        elseif coefficients(i) < 0
            result = '< 0';

        else
            result = '= 0';

        end
        fprintf('%s %s\n', names{i}, result);

    end

end
