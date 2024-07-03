function B = Bspline_basis_functions(k)

    % Generate the matrix M
    M = Bspline_basis_matrix(k);
    
    % Initialize the basis function cell array
    B = cell(1, k);
    
    % Define the symbolic variable y
    syms y
    
    % Generate the matrix_elements as a row vector
    vector_elements = sym('y', [1 k]);    
    for i = 1:k
        vector_elements(i) = y^(k - i);
    end

    % Generate each basis function
    for i = 1:k
        B{i} = (vector_elements * M(:,i)) / factorial(k-1);
    end

end