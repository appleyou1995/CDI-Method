function plot_risk_preference_surface(x_values, date_vec, Z_matrix, xmin, xmax, ...
                                      Target_TTM, Target_b, z_label_str, Path_Output)

    % Convert date vector to datetime format
    date_dt = datetime(string(date_vec), 'InputFormat', 'yyyyMMdd');

    % Create meshgrid for x and date
    [X, Y] = meshgrid(x_values, date_dt);

    % Plot surface with grid lines
    figure;
    set(gcf, 'Position', [100, 100, 800, 600]);
    surf(X, Y, Z_matrix, ...
         'EdgeColor', 'interp', ... 
         'FaceAlpha', 1);

    colormap turbo;
    colorbar;

    % 3D perspective view
    view(55, 15);
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('Year', 'FontName', 'Times New Roman', 'FontSize', 14);
    zlabel(z_label_str, 'FontName', 'Times New Roman', 'FontSize', 14);
    % title(title_str, 'Interpreter', 'none');
    
    % Axis ranges
    xlim([xmin, xmax]);

    % Format y-axis to show readable dates
    ax = gca;
    ax.YAxis.TickLabelFormat = 'yyyy';
    ax.YDir = 'normal';           % Time flows top-down
    ax.FontName = 'Times New Roman';
    ax.FontSize = 13;
    grid on;
    
    % Format colorbar
    cb = colorbar;
    cb.FontSize = 13;
    cb.FontName = 'Times New Roman';
    
    % Save
    mBackground = '#FAFAFA';
    filename = sprintf('Rolling_TTM=%d_b=%d_%s.png', Target_TTM, Target_b, z_label_str);
    exportgraphics(gcf, fullfile(Path_Output, filename), 'BackgroundColor', mBackground);
end
