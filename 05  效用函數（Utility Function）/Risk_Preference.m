function [ARA, RRA, AP, RP, AT, RT] = Risk_Preference(u_func, w)
        
    % Symbolic computation of derivatives
    syms ws
    u_sym             = u_func(ws); % Convert function handle to symbolic expression
    u_prime           = diff(u_sym, ws);
    u_double_prime    = diff(u_prime, ws);
    u_triple_prime    = diff(u_double_prime, ws);
    u_quadruple_prime = diff(u_triple_prime, ws);

    % Convert symbolic derivatives back to MATLAB function handles
    u_prime_func           = matlabFunction(u_prime);
    u_double_prime_func    = matlabFunction(u_double_prime);
    u_triple_prime_func    = matlabFunction(u_triple_prime);
    u_quadruple_prime_func = matlabFunction(u_quadruple_prime);

    % Calculate risk preference functions
    ARA = -u_double_prime_func(w) ./ u_prime_func(w);                      % Absolute Risk Aversion
    RRA = ARA .* w;                                                        % Relative Risk Aversion
    AP  = -u_triple_prime_func(w) ./ u_double_prime_func(w);               % Absolute Prudence
    RP  = AP .* w;                                                         % Relative Prudence
    AT  = -u_quadruple_prime_func(w) ./ u_triple_prime_func(w);            % Absolute Temperance
    RT  = AT .* w;                                                         % Relative Temperance
    
end
