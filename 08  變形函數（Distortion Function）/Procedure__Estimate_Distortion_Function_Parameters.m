clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data    = fullfile(Path_MainFolder, 'Data');
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Path_Data_06 = fullfile(Path_MainFolder, 'Code', '06  輸出資料');
Path_Data_07 = fullfile(Path_MainFolder, 'Code', '07  輸出資料');
Path_Output = fullfile(Path_MainFolder, 'Code', '08  輸出資料');


%% Load Data: Target_Date

Target_Date_Exdate = readtable(fullfile(Path_Data, 'Target_AllDate.csv'));
Target_Date = Target_Date_Exdate.date;
clear Target_Date_Exdate


%% Load Data: max_gross_return_y & PDF = g_hat * RND (align Smooth_RND with max_gross_return_y)

% (1) Import max_gross_return_y

Smooth_AllR = [];
years_to_merge = 1996:2021;

for year = years_to_merge    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));    
    data = load(input_filename);
    Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];    
end

max_gross_return_y = Smooth_AllR{1, '20200318'};                           % max gross return month: 20200318
clear input_filename data year years_to_merge Smooth_AllR


% (2) Import PDF = g_hat * RND (align Smooth_RND with max_gross_return_y)

load(fullfile(Path_Data_06, 'b_4_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_6_AllR_PDF.mat'));
load(fullfile(Path_Data_06, 'b_8_AllR_PDF.mat')');

AllR_PDF_Tables = {b_4_AllR_PDF, b_6_AllR_PDF, b_8_AllR_PDF};
b_values = [4, 6, 8];


%% Compute Monthly Cumulative Distribution Functions (CDF) from PDF = g_hat * RND

AllR_CDF_Tables = cell(size(AllR_PDF_Tables));
y = max_gross_return_y(:);

for i = 1:length(AllR_PDF_Tables)

    current_PDF = AllR_PDF_Tables{i};
    current_CDF = zeros(size(current_PDF));

    for t = 1:size(current_PDF, 1)
        cdf_values = cumtrapz(y, current_PDF(t, :));
        current_CDF(t, :) = cdf_values / max(cdf_values);
    end
    
    AllR_CDF_Tables{i} = current_CDF;
    assignin('base', sprintf('b_%d_AllR_CDF', b_values(i)), current_CDF);
    
end

clear i t y cdf_values current_PDF current_CDF

b_4_AllR_CDF = AllR_CDF_Tables{1};
b_6_AllR_CDF = AllR_CDF_Tables{2};
b_8_AllR_CDF = AllR_CDF_Tables{3};


%% Load Data: EGARCH PDF

EGARCH_PDF_Files = dir(fullfile(Path_Data_07, '*_EGARCH_PDF.mat'));

EGARCH_PDF_X = [];
EGARCH_PDF_Values = [];

for k = 1:length(EGARCH_PDF_Files)
    
    FileName = fullfile(Path_Data_07, EGARCH_PDF_Files(k).name);
    Data = load(FileName);

    FieldName = fieldnames(Data);
    Year_Data = Data.(FieldName{1});

    EGARCH_PDF_X = [EGARCH_PDF_X; Year_Data.X];
    EGARCH_PDF_Values = [EGARCH_PDF_Values; Year_Data.Values];

end

clear k Data FieldName Year_Data EGARCH_PDF_Files


%% Interpolate and Compute Monthly Cumulative Distribution Functions (CDF) from EGARCH PDF

EGARCH_CDF_Values = zeros(size(EGARCH_PDF_Values));

for t = 1:length(Target_Date)

    original_x = EGARCH_PDF_X(t, :);
    original_f = EGARCH_PDF_Values(t, :);

    interpolated_f = interp1(original_x, original_f, max_gross_return_y, 'spline', 0);

    cdf_values = cumtrapz(max_gross_return_y, interpolated_f);
    cdf_values = cdf_values / max(cdf_values);

    EGARCH_CDF_Values(t, :) = cdf_values;

end

clear original_x original_f interpolated_f cdf_values


%% Optimization of Alpha and Beta Parameters with Algorithm Selection

range_alpha = [0.5, 20];
range_beta  = [0.5, 20];

optimal_alpha = zeros(length(Target_Date), length(b_values));
optimal_beta  = zeros(length(Target_Date), length(b_values));

y_limits = max_gross_return_y(max_gross_return_y >= 0.8 & max_gross_return_y <= 1.2);

% Algorithm Selection ('fmincon', 'ga', 'particleswarm', 'simulannealbnd')
selected_algorithm = 'fmincon';


for b_idx = 1:length(b_values)

    b = b_values(b_idx);
    CDF_data = AllR_CDF_Tables{b_idx};

    fprintf('Processing b = %d...\n', b);

    for t = 1:length(Target_Date)
        
        CDF_g_hats = CDF_data(t, :);
        CDF_EGARCH = EGARCH_CDF_Values(t, :);
    
        objective_function = @(params) compute_total_integral(...
            params, y_limits, max_gross_return_y, CDF_g_hats, CDF_EGARCH);
    
        initial_guess = [1.0, 1.0];
        lb = [range_alpha(1), range_beta(1)];
        ub = [range_alpha(2), range_beta(2)];
    
        switch selected_algorithm
            case 'fmincon'
                options = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp');
                [opt_params, ~] = fmincon(objective_function, initial_guess, [], [], [], [], lb, ub, [], options);
    
            case 'ga'
                options = optimoptions('ga', 'Display', 'iter', 'PopulationSize', 50, 'MaxGenerations', 20);
                [opt_params, ~] = ga(objective_function, 2, [], [], [], [], lb, ub, [], options);
    
            case 'particleswarm'
                options = optimoptions('particleswarm', 'Display', 'iter', 'SwarmSize', 50, 'MaxIterations', 20);
                [opt_params, ~] = particleswarm(objective_function, 2, lb, ub, options);
    
            case 'simulannealbnd'
                options = optimoptions('simulannealbnd', 'Display', 'iter', 'MaxIterations', 50);
                [opt_params, ~] = simulannealbnd(objective_function, initial_guess, lb, ub, options);
    
            otherwise
                error('Unsupported algorithm: %s', selected_algorithm);
        end
    
        optimal_alpha(t, b_idx) = opt_params(1);
        optimal_beta(t, b_idx)  = opt_params(2);
    
        fprintf('%d - Optimal alpha: %f, beta: %f\n', Target_Date(t), opt_params(1), opt_params(2));
    end
end


%% Compute distortion integral error

function total_integral = compute_total_integral(params, y_limits, max_gross_return_y, CDF_g_hats, CDF_EGARCH)

    alpha = params(1);
    beta = params(2);

    total_integral = 0;

    for i = 1:length(y_limits)
        current_limit = y_limits(i);
        idx = max_gross_return_y == current_limit;

        selected_f_y_g_hats = CDF_g_hats(idx);
        selected_f_y_EGARCH = CDF_EGARCH(idx);

        distorted_value = Distortion(selected_f_y_EGARCH, beta, alpha);

        total_integral = total_integral + (selected_f_y_g_hats - distorted_value).^2;
    end
end


%% Distortion Function

function D = Distortion(x, beta, alpha)

    D = exp(-((-beta * log(x)).^alpha));

end


%% Plot

years_with_months = floor(Target_Date / 10000) + mod(floor(Target_Date / 100), 100) / 12;

figure;

subplot(2, 1, 1);
plot(years_with_months, optimal_alpha(:, 1), '--o', 'DisplayName', '\alpha (b=4)', 'MarkerSize', 4, 'LineWidth', 0.2);
hold on;
plot(years_with_months, optimal_alpha(:, 2), '--s', 'DisplayName', '\alpha (b=6)', 'MarkerSize', 4, 'LineWidth', 0.2);
plot(years_with_months, optimal_alpha(:, 3), '--d', 'DisplayName', '\alpha (b=8)', 'MarkerSize', 4, 'LineWidth', 0.2);
hold off;
title('Prelec alpha');
ylabel('\alpha', 'Rotation', 0, 'HorizontalAlignment', 'right');
legend('Location', 'northwest', 'Box', 'Off');
xlim([1996, 2022]);
xticks(1996:2:2022);
grid on;

subplot(2, 1, 2);
plot(years_with_months, optimal_beta(:, 1), '--o', 'DisplayName', '\beta (b=4)', 'MarkerSize', 4, 'LineWidth', 0.2);
hold on;
plot(years_with_months, optimal_beta(:, 2), '--s', 'DisplayName', '\beta (b=6)', 'MarkerSize', 4, 'LineWidth', 0.2);
plot(years_with_months, optimal_beta(:, 3), '--d', 'DisplayName', '\beta (b=8)', 'MarkerSize', 4, 'LineWidth', 0.2);
hold off;
title('Prelec beta');
xlabel('Year');
ylabel('\beta', 'Rotation', 0, 'HorizontalAlignment', 'right');
legend('Location', 'northwest', 'Box', 'Off');
xlim([1996, 2022]);
xticks(1996:2:2022);
grid on;

set(gcf, 'Position', [50, 50, 1000, 650]);

filename = 'Prelec_Parameters.png';
saveas(gcf, fullfile(Path_Output, filename));
clear filename