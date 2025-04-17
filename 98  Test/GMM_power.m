function gamma_hat = GMM_power( ...
    Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    %{
    ---------------------------------------------------------------------
    只估計 gamma 一個參數
    不使用 B-spline、不使用 distortion function
    ---------------------------------------------------------------------
    %}

    % 1) 亂數初始化
    rng(0);

    % 2) 初始值（只有 gamma）
    gamma0 = rand(1, 1);

    % 3) 設定優化選項
    options = optimoptions('fmincon','Display','iter','Algorithm','sqp');

    % 4) 設定上下界
    lb = 1e-6;
    ub = Inf;

    % 5) 最小化 GMM 目標函數
    gamma_hat = fmincon( ...
        @(g) GMM_objective_power( ...
            g, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates), ...
        gamma0, [], [], [], [], lb, ub, ...
        [], options);
end


%% ------------------ GMM 目標函數 ------------------ %%

function J = GMM_objective_power( ...
    gamma, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    W = eye(3);
    g = GMM_moment_power(gamma, ...
        Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates);
    
    J = g' * W * g;
end


%% -------------- GMM Moment Conditions -------------- %%

function g = GMM_moment_power( ...
    gamma, Smooth_AllR, Smooth_AllR_RND, Realized_Return, RiskFreeRates)

    % 抓月份數
    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);

    % m = 2 (3 個 moment)
    m = 2;
    g = zeros(m+1, 1);

    for j = 0:m
        moment_sum = 0;

        for t = 1:T
            % 抓該月資料
            R_t_grid   = Smooth_AllR{1, months{t}};
            RND_values = Smooth_AllR_RND{1, months{t}};
            realized_R = Realized_Return{t, 2};
            Rf_t       = RiskFreeRates(t);

            % 篩選 R <= realized_R
            idx_filter   = (R_t_grid <= realized_R);
            y_filtered   = R_t_grid(idx_filter);
            RND_filtered = RND_values(idx_filter);

            % 積分
            integrand      = (y_filtered.^gamma) .* RND_filtered;
            integral_value = trapz(y_filtered, integrand);
            g_param        = integral_value / Rf_t;

            % moment: g_theta^(j+1)
            moment_sum = moment_sum + (g_param ^ (j+1));
        end

        % 平均後減去 1/(j+2)，再平方
        g(j+1) = (moment_sum / T - 1/(j+2)) ^ 2;
    end
end
