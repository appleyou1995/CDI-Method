function M = generate_matrix(k)
    % Initialize the matrix M with zeros
    M = zeros(k, k);
    
    % Fill in the matrix
    for i = 0:k-1
        for j = 0:k-1
            M(k-i, j+1) = calculate_mij(i, j, k);
        end
    end
end

function mij = calculate_mij(i, j, k)

    sum_term = 0;
    for s = j:k-1
        sum_term = sum_term + (-1)^(s - j) * nchoosek(k, s - j) * (k - s - 1)^(k - 1 - i);
    end
    mij = nchoosek(k - 1, k - 1 - i) * sum_term;

    % mij = (1 / factorial(k - 1)) * nchoosek(k - 1 - i, k - 1) * sum_term;

end


%% Generate matrix M

k = 4;
M = generate_matrix(k);
disp(M);