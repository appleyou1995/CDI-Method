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