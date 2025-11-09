function y = CheckError_GEV_PDFCDF(mu, sigma, k, ...
                                   K_CP0, K_CP1, ...
                                   EMP_CDF_CP0, EMP_PDF_CP0, EMP_PDF_CP1)

    y = nan(1, 3);                                                         % Construct Space
    
    % CDF at First Connecting Point (CP)
    z = (K_CP0 - mu) / sigma;
    y(1) = - (1 + k * z)^(- 1 / k) - log(EMP_CDF_CP0);
    clear z
    
    % PDF at First Connecting Point (CP)
    z = (K_CP0 - mu) / sigma;
    y(2) = log((1 + k * z)^(- 1 - 1 / k)) - (1 + k * z)^(- 1 / k) - log(sigma) - log(EMP_PDF_CP0);
    clear z
    
    % PDF at Second Connecting Point (CP)
    z = (K_CP1 - mu) / sigma;
    y(3) = log((1 + k * z)^(- 1 - 1 / k)) - (1 + k * z)^(- 1 / k) - log(sigma) - log(EMP_PDF_CP1);
    clear z

end