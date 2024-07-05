function mij = Bspline_basis_matrix_mij(i, j, k)

    sum_term = 0;
    for s = j:k-1
        sum_term = sum_term + (-1)^(s - j) * nchoosek(k, s - j) * (k - s - 1)^(k - 1 - i);
    end
    mij = nchoosek(k - 1, k - 1 - i) * sum_term;

end