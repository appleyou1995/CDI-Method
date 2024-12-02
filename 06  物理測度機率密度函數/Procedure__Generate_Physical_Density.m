clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';


%% Load the data

% Realized Return
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  原始資料處理');
Realized_Return = readtable(fullfile(Path_Data_01, 'Realized_Return.csv'));

% RND
Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  輸出資料');
Smooth_AllR = [];
Smooth_AllR_RND = [];

years_to_merge = 1996:2021;

for year = years_to_merge
    
    input_filename = fullfile(Path_Data_02, sprintf('Output_Tables_%d.mat', year));
        
    if exist(input_filename, 'file')
        data = load(input_filename);
        Smooth_AllR = [Smooth_AllR, data.Table_Smooth_AllR];
        Smooth_AllR_RND = [Smooth_AllR_RND, data.Table_Smooth_AllR_RND];
    else
        warning('File %s does not exist.', input_filename);
    end
end

% Estimated theta
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');
mat_files = dir(fullfile(Path_Data_03, 'theta_hat (b=*.mat'));

for k = 1:length(mat_files)
    file_path = fullfile(Path_Data_03, mat_files(k).name);
    load(file_path, 'theta_hat');
    b_value = regexp(mat_files(k).name, '(?<=b=)\d+', 'match', 'once');
    var_name = ['theta_hat_' b_value];
    assignin('base', var_name, theta_hat);
end

clear b_value var_name k theta_hat year
clear Path_Data_01 Path_Data_02 Path_Data_03 file_path input_filename


%% Define the knots for the B-spline

n = 3;                                                                     % Order of the B-spline (cubic B-spline)

Aggregate_Smooth_AllR = Smooth_AllR.Variables;

% Find the minimum value for which the estimated risk-neutral densities have positive support
min_knot = min(Aggregate_Smooth_AllR);

% Find the maximum realized return within the sample
max_knot = 3;

clear Aggregate_Smooth_AllR


%% Setting

% Specify the month to plot: 20200318
t = 291;

months = Smooth_AllR.Properties.VariableNames;

max_gross_return = Realized_Return{t, 2};
max_gross_return_y = Smooth_AllR{1, months{t}};

max_gross_return_month = months{t};

min_y = min(max_gross_return_y);
max_y = 3;


%% Calculate g hat

store_g = nan(3, length(max_gross_return_y));

for b = [4, 6, 8]

    Path_03 = fullfile(Path_MainFolder, 'Code', '03  條件密度積分方法（CDI method） - 2021 JBF');
    addpath(Path_03);

    y_BS = nan(b + 1, length(max_gross_return_y));

    for i = 1:(b + 1)
        y_BS(i, :) = Bspline_basis_function_value(3, b, min_y, max_y, i, max_gross_return_y);
    end
    clear i

    % Calculate the value of g function
    theta_hat_var_name = ['theta_hat_', num2str(b)];
    g_function_value = sum(transpose(eval(theta_hat_var_name)) .* y_BS, 1);

    y = max_gross_return_y;
    g = g_function_value;

    idx = b / 2 - 1;
    store_g(idx, :) = g;

    clear y_BS g_function_value g idx

end


%% Calculate Physical Density

b_values = [4, 6, 8];

b_4_AllR_PDF = table();
b_6_AllR_PDF = table();
b_8_AllR_PDF = table();

AllR_PD_Tables = {b_4_AllR_PDF, b_6_AllR_PDF, b_8_AllR_PDF};

for idx_b = 1:length(b_values)

    b = b_values(idx_b);
    current_g = store_g(idx_b, :);

    % Initialize a table for the current b value
    PD_Table = zeros(length(months), length(max_gross_return_y));

    for t = 1:length(months)

        % Retrieve the RND and x values for the current month
        original_x = Smooth_AllR{1, months{t}};
        original_f = Smooth_AllR_RND{1, months{t}};
        
        % Use the 'spline' method to interpolate the RND to match max_gross_return_y
        interpolated_f = interp1(original_x, original_f, max_gross_return_y, 'spline', 0);

        % Calculate the physical density for the current month
        current_month_PD = interpolated_f  .* current_g;
        PD_Table(t, :) = current_month_PD;

    end

    AllR_PD_Tables{idx_b} = PD_Table;
    
end

b_4_AllR_PDF = AllR_PD_Tables{1};
b_6_AllR_PDF = AllR_PD_Tables{2};
b_8_AllR_PDF = AllR_PD_Tables{3};


%% Output

Path_Output = fullfile(Path_MainFolder, 'Code', '06  輸出資料');

save(fullfile(Path_Output, 'b_4_AllR_PDF.mat'), 'b_4_AllR_PDF');
save(fullfile(Path_Output, 'b_6_AllR_PDF.mat'), 'b_6_AllR_PDF');
save(fullfile(Path_Output, 'b_8_AllR_PDF.mat'), 'b_8_AllR_PDF');