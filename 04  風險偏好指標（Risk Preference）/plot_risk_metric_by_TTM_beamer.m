function plot_risk_metric_by_TTM_beamer(RiskMetrics, metric_name, y_label, y_min, y_max, ...
                                        filename_base, Path_Output, x_start, x_end)

    % Define Color (LaTeX Beamer Theme - Metropolis)
    mRed        = '#e74c3c';
    mDarkRed    = '#b22222';
    mLightBlue  = '#3279a8';
    mDarkBlue   = '#2c3e50';
    mDarkGreen  = '#4b8b3b';
    mOrange     = '#f39c12';
    mBackground = '#FAFAFA';

    colors = lines(length(RiskMetrics));
    figure;
    tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');
    set(gcf, 'Color', mBackground);

    for idx_b = 1:3  % b = 4, 6, 8
        nexttile;
        hold on;

        for j = 1:length(RiskMetrics)
            x = RiskMetrics(j).x;
            metric = RiskMetrics(j).(metric_name);

            plot(x, metric(:, idx_b), 'LineWidth', 1.5, 'Color', colors(j, :));
        end

        title(['$b = $ ', num2str((idx_b + 1) * 2)], 'Interpreter', 'latex', 'FontSize', 14);
        xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
        ylabel(y_label, 'Interpreter', 'latex', 'FontSize', 14);
        xlim([x_start, x_end]);
        ylim([y_min, y_max]);
        grid on;

        set(gca, ...
            'box', 'on', ...
            'FontName', 'Times New Roman', ...
            'FontSize', 12);
        hold off;
    end

    legend(arrayfun(@(r) sprintf('TTM = %d', r.TTM), RiskMetrics, 'UniformOutput', false), ...
           'Location', 'bestoutside');

    set(gcf, 'Position', [200, 200, 1200, 380]);
    filename = sprintf('Slide_RiskMetric_MultiTTM_%s.png', filename_base);
    saveas(gcf, fullfile(Path_Output, filename));
end
