function params_hat = GMM_power_distort( ...
    Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    %{
    ---------------------------------------------------------------------
    只估計 [alpha, beta, gamma] 三個參數
    不使用 B-spline，也無任何非線性約束
    ---------------------------------------------------------------------
    %}

    % 1) 亂數初始化
    rng(0);

    % 2) 參數初始值：只有三個參數 alpha, beta, gamma
    params0 = rand(1, 3);

    % 3) 設定優化選項
    options = optimoptions('fmincon','Display','iter','Algorithm','sqp');

    % 4) 設定上下界
    lb = [1e-6, 1e-6, 1e-6];
    ub = [  10,   10,  Inf];

    % 5) 最小化目標函式
    %    不需要 nonlinear_constraint
    params_hat = fmincon( ...
        @(p) GMM_objective_function_noBspline( ...
            p, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates), ...
        params0, [], [], [], [], lb, ub, ...
        [], ...   % 不帶任何 constraint
        options);
end


%% ------------------ GMM 目標函式 ------------------ %%

function J = GMM_objective_function_noBspline( ...
    params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    % 權重矩陣：僅做一階段 GMM 時，通常可用單位矩陣
    W = eye(3);

    % 計算 moment conditions
    g = GMM_moment_conditions_noBspline(params, ...
        Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates);

    % 目標函式：
    J = g' * W * g;
end


%% -------------- GMM Moment Conditions -------------- %%

function g = GMM_moment_conditions_noBspline( ...
    params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    % 1) 取出參數
    alpha = params(1);
    beta  = params(2);
    gamma = params(3);

    % 2) 抓月份數量
    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);

    % 3) 設定 moment 的數量
    %    令 m = 2，跑 j = 0,1,2 共 3 個 moment => g(1), g(2), g(3)
    m = 2;
    g = zeros(m+1,1);

    % 4) 逐一計算 moment
    for j = 0:m

        moment_sum = 0;

        for t = 1:T

            % 4.1 取出該月資料
            R_t_grid   = Smooth_AllR{1, months{t}};      % 離散化的 R
            RND_values = Smooth_AllR_RND{1, months{t}};  % 對應的 f^Q(R)
            realized_R = Realized_Return{t, 2};          % 該月實際實現報酬
            Rf_t       = RiskFreeRates(t);               % 該月的風險利率

            % 4.2 只取 R <= realized_R
            idx_filter = (R_t_grid <= realized_R);
            y_filtered   = R_t_grid(idx_filter);
            RND_filtered = RND_values(idx_filter);

            % 4.3 直接對 y^gamma * f^Q(y) 做從 0 ~ realized_R 的數值積分
            integrand = (y_filtered.^gamma) .* RND_filtered;
            integral_value = trapz(y_filtered, integrand);

            % 4.4 除以對應的 R_{f,t}
            g_theta = integral_value / Rf_t;

            % 4.5 扭曲函數的反函式 D^-1(g_theta)
            g_theta_distort_inv = distortion_inverse(g_theta, alpha, beta);

            % 4.6 累加 (g_theta_distort_inv)^(j+1)
            moment_sum = moment_sum + (g_theta_distort_inv ^ (j+1));
        end

        % 4.7 取平均後，減去 1/(j+2) (可依你理論需求而修改)
        g(j+1) = moment_sum / T - 1/(j+2);
    end
end


%% -------------- Distortion Function Inverse -------------- %%

function D_inv = distortion_inverse(x, alpha, beta)
    % 沿用之前的定義：D_inv(x) = exp( - ( -log(x) )^(1/alpha ) / beta );
    D_inv = exp( - ( -log(x) ).^(1/alpha ) / beta );
end
