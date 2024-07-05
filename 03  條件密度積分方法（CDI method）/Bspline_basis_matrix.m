function M = Bspline_basis_matrix(k)

    % Initialize the matrix M with zeros
    M = zeros(k, k);
    
    % Fill in the matrix
    for i = 0:k-1
        for j = 0:k-1
            M(k-i, j+1) = Bspline_basis_matrix_mij(i, j, k);
        end
    end
    
end


%% Elements in B-spline basis matrix

function mij = Bspline_basis_matrix_mij(i, j, k)

    sum_term = 0;
    for s = j:k-1
        sum_term = sum_term + (-1)^(s - j) * nchoosek(k, s - j) * (k - s - 1)^(k - 1 - i);
    end
    mij = nchoosek(k - 1, k - 1 - i) * sum_term;

end