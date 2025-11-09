function [EST_mu EST_sigma EST_k] = Fit_GEV_PDF(K0, K1, ...
                                                EMP_CDF_K0, EMP_PDF_K0, EMP_PDF_K1)
%% Closed-Form Solutions (In terms of k)
% PDF at K0
FCN_sigma = @(k) exp((1 + k) .* log(- log(EMP_CDF_K0)) - (- log(EMP_CDF_K0)) - log(EMP_PDF_K0));

% CDF at K0
FCN_mu = @(k) (K0 - (FCN_sigma(k) ./ k) .* (exp(- k .* log(- log(EMP_CDF_K0))) - 1)); 

% PDF at K1
FCN_t1 = @(k) (exp(- k .* log(- log(EMP_CDF_K0))) + k .* ((K1 - K0) ./ FCN_sigma(k)));
OBJ = @(k) ((- (1 + 1 ./ k) .* log(FCN_t1(k)) - FCN_t1(k).^(- 1 ./ k) - log(FCN_sigma(k))) - log(EMP_PDF_K1));

%% Find the Parameters of Generalized Extreme Value (GEV) Funciton
is_valid_k = @(k) ((- log(EMP_CDF_K0)) > 0) & isfinite(k) & (FCN_sigma(k) > 0) & (exp(- k .* log(- log(EMP_CDF_K0))) > 0) & (FCN_t1(k) > 0);

LBUB = [(- 0.4) (- 1e-3); ...
        1e-3 0.6];    
        
OBJ_Root = [];                                                             % Construct Space
OBJ_Value = [];                                                            % Construct Space
for i = 1:size(LBUB, 1)
    k_LB = LBUB(i, 1);                                                     % Initial Interval
    k_UB = LBUB(i, 2);                                                     % Initial Interval
    
    if ~is_valid_k(k_LB) || ~is_valid_k(k_UB)
        continue
    end
    
    if sign(OBJ(k_LB)) * sign(OBJ(k_UB)) > 0
        if is_valid_k(1.5 * k_LB) && is_valid_k(1.5 * k_UB)
            k_LB = 1.5 * k_LB;                                             % Update: k_LB
            k_UB = 1.5 * k_UB;                                             % Update: k_UB
        end
    end
    
    % Find the Root of 'OBJ': Based on 'fzero' 
    try
        k_try = fzero(@(x) OBJ(x), [k_LB k_UB]);
        
        if is_valid_k(k_try)
            OBJ_Root(end + 1) = k_try;
            OBJ_Value(end + 1) = abs(OBJ(k_try));       
        end
    catch
    end
    clear k_LB k_UB
end
clear LBUB
clear i

% Find the Root of 'abs(OBJ)': Based on 'fminsearch'
if isempty(OBJ_Root)
    OBJ_ReTry = @(x) (is_valid_k(x) .* abs(OBJ(x)) + (~is_valid_k(x)) * 1e6);
    
    k_try = fminsearch(@(x) OBJ_ReTry(x), 0.1, optimset('Display','off'));
    clear OBJ_ReTry
    
    if is_valid_k(k_try)
        OBJ_Root(end + 1) = k_try;
        OBJ_Value(end + 1) = abs(OBJ(k_try));     
    end
end

% Root of Objective Function
[~, Index_Min] = min(OBJ_Value);
EST_k = OBJ_Root(Index_Min);
clear Index_Min OBJ_Root OBJ_Value

EST_sigma = FCN_sigma(EST_k);
EST_mu = FCN_mu(EST_k);