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
    
    % Interpolate using 'pchip' to avoid oscillation
    interpolated_f = interp1(original_x, original_f, max_gross_return_y, 'pchip', 0);

    % Ensure interpolated values are non-negative
    interpolated_f(interpolated_f < 0) = 0;

    % Compute CDF using cumulative integration
    cdf_values = cumtrapz(max_gross_return_y, interpolated_f);
    cdf_values = cdf_values / max(cdf_values);

    EGARCH_CDF_Values(t, :) = cdf_values;

end

clear original_x original_f interpolated_f cdf_values


%% Define variables

syms beta alpha


%% Distortion Function

Distortion = @(x, beta, alpha) exp(-((-beta * log(x)).^alpha));


%% Precompute Values for All Months and All y_limits

optimal_params = zeros(length(b_values), 2);

min_idx = find(max_gross_return_y >= 0.8, 1, 'first');
max_idx = find(max_gross_return_y <= 1.2, 1, 'last');

y_limits = max_gross_return_y(min_idx:max_idx);

precomputed_data = cell(length(b_values), 1);

for b_idx = 1:length(b_values)
    
    b = b_values(b_idx);
    CDF_g_hats = AllR_CDF_Tables{b_idx};    
    all_g_hats = [];
    all_egarch = [];

    for t = 1:length(Target_Date)
        fprintf('[ b = %d ] Target_Date: %d\n', ...
            b, Target_Date(t));

        CDF_g_hats_t = CDF_g_hats(t, :);
        CDF_EGARCH_t = EGARCH_CDF_Values(t, :);

        selected_f_y_g_hats = CDF_g_hats_t(min_idx:max_idx);
        selected_f_y_EGARCH = CDF_EGARCH_t(min_idx:max_idx);

        all_g_hats = [all_g_hats; selected_f_y_g_hats(:)];
        all_egarch = [all_egarch; selected_f_y_EGARCH(:)];
    end

    precomputed_data{b_idx} = struct('all_g_hats', all_g_hats, 'all_egarch', all_egarch);
end


%% Optimization of Alpha and Beta Parameters

function J = objective_function(params, precomputed, Distortion)
    beta = params(1);
    alpha = params(2);

    distorted_value = Distortion(precomputed.all_egarch, beta, alpha);
    J = sum((distorted_value - precomputed.all_g_hats).^2);
end

range_beta  = [0.5, 2];
range_alpha = [0.5, 2];

initial_guess = [1.0, 1.0];
lb = [range_beta(1), range_alpha(1)];
ub = [range_beta(2), range_alpha(2)];

for b_idx = 1:length(b_values)

    b = b_values(b_idx);
    precomputed = precomputed_data{b_idx};

    options = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp');
    [optimal_params(b_idx, :), fval] = fmincon(@(params) objective_function(params, precomputed, Distortion), ...
        initial_guess, [], [], [], [], lb, ub, [], options);

    fprintf('[ b = %d ] Optimal alpha: %.4f, Optimal beta: %.4f\n', ...
        b, optimal_params(b_idx, 2), optimal_params(b_idx, 1));
end

disp('Optimal parameters for all b:');
disp(array2table(optimal_params, 'VariableNames', {'Beta', 'Alpha'}));