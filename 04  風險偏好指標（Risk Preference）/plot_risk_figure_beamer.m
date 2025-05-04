function plot_risk_figure_beamer(y, store_values, y_label, y_min, y_max, filename_base, ...
                                  Target_TTM, Path_Output, x_start, x_end)
    % Define Color (LaTeX Beamer Theme - Metropolis)
    mRed        = '#e74c3c';
    mDarkRed    = '#b22222';
    mLightBlue  = '#3279a8';
    mDarkBlue   = '#2c3e50';
    mDarkGreen  = '#4b8b3b';
    mOrange     = '#f39c12';
    mBackground = '#FAFAFA';

    % Initialize figure with theme background
    figure;
    tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');
    set(gcf, 'Color', mBackground);

    for idx = 1:3
        nexttile;

        hold on;

        plot(y, store_values(idx, :), '.', 'MarkerEdgeColor', mLightBlue);

        title(['b = ', num2str((idx + 1) * 2)], ...
            'FontName', 'Fira Sans', 'FontSize', 14, 'Color', mDarkBlue);
        xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
        ylabel(y_label, 'Interpreter', 'latex', 'FontSize', 14);

        xlim([x_start, x_end]);
        ylim([y_min, y_max]);
        grid on;

        set(gca, ...
            'box', 'on', ...
            'FontName', 'Fira Sans', ...
            'FontSize', 12, ...
            'XColor', mDarkBlue, ...
            'YColor', mDarkBlue);

        hold off;
    end

    set(gcf, 'Position', [100, 100, 1200, 400]);

    filename = sprintf('Slide_TTM_%d_%s.png', Target_TTM, filename_base);
    exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', mBackground);
end
