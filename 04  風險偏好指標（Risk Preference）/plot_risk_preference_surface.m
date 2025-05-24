function plot_risk_preference_surface(x_values, date_vec, Z_matrix, xmin, xmax, title_str, z_label_str)

    % Convert date vector to datetime format
    date_dt = datetime(string(date_vec), 'InputFormat', 'yyyyMMdd');

    % Create meshgrid for x and date
    [X, Y] = meshgrid(x_values, date_dt);

    % Plot surface with grid lines
    figure;
    surf(X, Y, Z_matrix, ...
         'EdgeColor', 'interp', ... 
         'FaceAlpha', 1);

    colormap turbo;                % Or try 'parula', 'jet', 'viridis', etc.
    colorbar;

    % 3D perspective view (default MATLAB style)
    view(45, 30);                  % Azimuth = 45°, Elevation = 30°
    xlabel('x');
    ylabel('Year');
    zlabel(z_label_str);
    title(title_str, 'Interpreter', 'none');
    
    % Axis ranges
    % z_min = -2;
    % z_max = 6;
    xlim([xmin, xmax]);
    % zlim([z_min, z_max]);
    % clim([z_min, z_max]);  % Match colorbar to z-axis range

    % Format y-axis to show readable dates
    ax = gca;
    ax.YAxis.TickLabelFormat = 'yyyy';
    ax.YDir = 'normal';           % Time flows top-down
    grid on;
end
