%% GMM Moment Conditions

function g = GMM_moment_conditions(params, Smooth_AllR, Smooth_AllR_RND, Realized_Return, b, min_knot, max_knot)

    theta = params(1:b+1);
    alpha = params(b+2);
    beta  = params(b+3);

    months = Smooth_AllR.Properties.VariableNames;
    T = length(months);
    m = b;
    g = zeros(m + 1, 1);

    for j = 0:m
        moment_sum = 0;
        valid_T = 0;

        for t = 1:T
            try
                current_month_realized_ret = Realized_Return{t, 2};
                if isnan(current_month_realized_ret)
                    continue
                end

                current_month_y = Smooth_AllR{1, months{t}}(:);
                current_month_RND = Smooth_AllR_RND{1, months{t}}(:);

                idx = current_month_y <= current_month_realized_ret;
                if sum(idx) == 0
                    continue
                end

                current_month_y_filtered = current_month_y(idx);
                current_month_RND_filtered = current_month_RND(idx);

                if length(current_month_y_filtered) ~= length(current_month_RND_filtered)
                    continue
                end

                g_theta = 0;

                for i = 1:(b + 1)
                    B_values = Bspline_basis_function_value(3, b, min_knot, max_knot, i, current_month_y_filtered);
                    if any(isnan(B_values))
                        warning('NaN in B_values at t=%d, month=%s', t, months{t});
                        g_theta = NaN;
                        break
                    end
                    integral = trapz(current_month_y_filtered, B_values .* current_month_RND_filtered);
                    if isnan(integral) || isinf(integral)
                        g_theta = NaN;
                        break
                    end
                    g_theta = g_theta + theta(i) * integral;
                end

                if isnan(g_theta) || isinf(g_theta) || g_theta <= 0
                    continue
                end

                % distortion function 應用
                g_distorted = distortion_inverse(g_theta, alpha, beta);

                moment_sum = moment_sum + g_distorted^(j + 1);
                valid_T = valid_T + 1;

            catch ME
                warning('Error at t=%d (%s): %s', t, months{t}, ME.message);
                continue
            end
        end

        if valid_T > 0
            g(j + 1) = moment_sum / valid_T - 1 / (j + 2);
        else
            g(j + 1) = NaN;
        end
    end
end