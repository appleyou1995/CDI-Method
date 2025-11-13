clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Output = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF - no dividend');


%% Setting

% Grid for gross returns
R_axis = linspace(0.003, 3, 30000);                                        % 1 × N
R_col  = R_axis(:);                                                        % N × 1 (for spcol)

min_knot = min(R_axis);
max_knot = max(R_axis);

degree = 3;                                                                % cubic B-spline
order  = degree + 1;

% Four TTM groups
TTM_list = [30, 60, 90, 180];

% Which b to plot
b_list = [4, 6, 8];


%% Loop over each TTM

for TTM = TTM_list

    fprintf('\n===== Processing TTM = %d =====\n', TTM);

    % Loop over each b
    for b = b_list

        % 1. Load theta_hat for this specific TTM & b
        pattern = sprintf('TTM_%d_theta_hat (b=%d).mat', TTM, b);
        mat_files = dir(fullfile(Path_Output, pattern));
        
        if isempty(mat_files)
            warning('No theta_hat file found for TTM=%d, b=%d', TTM, b);
            continue;
        end
        
        S = load(fullfile(Path_Output, mat_files(1).name), 'theta_hat');
        theta_hat = S.theta_hat(:).';


        % 2. Create open-uniform knot vector
        num_knots = degree + b + 2;
        knots = linspace(min_knot, max_knot, num_knots);

        % Open-uniform ends
        knots(1:(degree+1))     = min_knot;
        knots((end-degree):end) = max_knot;


        % 3. Evaluate B-splines on grid (N × (b+1))
        B_all = spcol(knots, order, R_col);  
        B_stack = B_all.';                                                 % (b+1) × N


        % 4. Compute linear combination
        g_vec = theta_hat * B_stack;                                       % 1 × N


        % 5. Plot (same style as your original figure)

        figure('Position', [800, 50, 550, 350]);
        tiledlayout(1, 1, 'TileSpacing', 'Compact', 'Padding', 'None');

        % ----- Left: zoomed in -----
        nexttile;
        hold on; grid on;

        plot(R_axis, B_stack, 'LineWidth', 1.5);
        plot(R_axis, g_vec, 'k', 'LineWidth', 2);

        xlabel('gross return');
        ylabel('Value');

        % Legend
        leg_str = arrayfun(@(i) sprintf('$B^3_{%d}$', i), 0:b, ...
            'UniformOutput', false);
        leg_str{end+1} = '$\sum_{i=0}^{b}\theta_{i}B^3_i$';

        legend(leg_str, 'Interpreter', 'latex', ...
            'Location', 'northwest', 'Box', 'off');

        ylim([-0.1 2.5]);


        % 6. Save output
        outname = sprintf('Cubic_B_Spline_spcol_TTM_%d_b%d.png', TTM, b);
        saveas(gcf, fullfile(Path_Output, outname));

        fprintf('Saved: %s\n', outname);
    end
end