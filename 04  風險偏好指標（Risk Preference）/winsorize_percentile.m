function X_winsor = winsorize_percentile(X, lower_pct, upper_pct)

    bounds = prctile(X(:), [lower_pct, upper_pct]);
    X_winsor = min(max(X, bounds(1)), bounds(2));
    
end
