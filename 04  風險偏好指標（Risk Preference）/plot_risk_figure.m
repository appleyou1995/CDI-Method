function plot_risk_figure(y, store_values, y_label, y_min, y_max, filename_base, Target_TTM, Path_Output, x_start, x_end)
    figure;
    tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'None');

    for idx = 1:3
        nexttile;

        hold on;
        plot(y, store_values(idx, :), '.');

        title(['$b =$ ', num2str((idx + 1) * 2)], 'Interpreter', 'latex', 'FontSize', 14);
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

    set(gcf, 'Position', [100, 100, 1200, 400]);

    filename = sprintf('TTM_%d_%s.png', Target_TTM, filename_base);
    saveas(gcf, fullfile(Path_Output, filename));
end
