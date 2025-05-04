clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_03 = fullfile(Path_MainFolder, 'Code', '03  輸出資料 - 2021 JBF');
Path_Output = fullfile(Path_MainFolder, 'Code', '04  輸出資料 - 2021 JBF');


%% Load the data

Target_TTM_all = [30, 60, 90, 180];

for i = 1:length(Target_TTM_all)
    TTM = Target_TTM_all(i);
    xlsxFilename = sprintf('TTM_%d_g_Function_and_Its_Derivatives_1996_2021.xlsx', TTM);
    inputFile = fullfile(Path_Data_03, xlsxFilename);

    if exist(inputFile, 'file')
        x  = readmatrix(inputFile, 'Sheet', 'gross return');
        g  = readmatrix(inputFile, 'Sheet', 'g');
        g1 = readmatrix(inputFile, 'Sheet', 'g_prime');
        g2 = readmatrix(inputFile, 'Sheet', 'g_double_prime');
        g3 = readmatrix(inputFile, 'Sheet', 'g_triple_prime');

        assignin('base', sprintf('x_%d', TTM), x);
        assignin('base', sprintf('g_%d', TTM), g);
        assignin('base', sprintf('g_prime_%d', TTM), g1);
        assignin('base', sprintf('g_double_prime_%d', TTM), g2);
        assignin('base', sprintf('g_triple_prime_%d', TTM), g3);
    else
        warning('File does not exist：%s', inputFile);
    end
end

clear xlsxFilename inputFile i TTM x g g1 g2 g3


%% Calculate Risk Aversion, Prudence and Temperance

RiskMetrics = struct();

for i = 1:length(Target_TTM_all)
    TTM = Target_TTM_all(i);

    g  = eval(sprintf('g_%d', TTM));
    g1 = eval(sprintf('g_prime_%d', TTM));
    g2 = eval(sprintf('g_double_prime_%d', TTM));
    g3 = eval(sprintf('g_triple_prime_%d', TTM));
    x  = eval(sprintf('x_%d', TTM));

    % Initialize storage
    u_1 = 1 ./ g;
    u_2 = -1 ./ (g.^2) .* g1;
    u_3 = 2 ./ (g.^3) .* (g1.^2) - 1 ./ (g.^2) .* g2;
    u_4 = -6 ./ (g.^4) .* (g1.^3) + ...
           6 ./ (g.^3) .* g1 .* g2 - ...
           1 ./ (g.^2) .* g3;

    ARA = -u_2 ./ u_1;
    RRA = x .* ARA;

    AP = -u_3 ./ u_2;
    RP = x .* AP;

    AT = -u_4 ./ u_3;
    RT = x .* AT;

    RiskMetrics(i).TTM  = TTM;
    RiskMetrics(i).x    = x;
    RiskMetrics(i).ARA  = ARA;
    RiskMetrics(i).RRA  = RRA;
    RiskMetrics(i).AP   = AP;
    RiskMetrics(i).RP   = RP;
    RiskMetrics(i).AT   = AT;
    RiskMetrics(i).RT   = RT;
end

clear i TTM
clear g g1 g2 g3 x
clear u_1 u_2 u_3 u_4
clear ARA RRA AP RP AT RT


%% Plot Setting

x_start = 0.8;
x_end = 1.2;


%% Plot

plot_risk_metric_by_TTM(RiskMetrics, 'ARA', '$\mathrm{ARA}(x)$', ...
    0.5, 3.5, 'Absolute_Risk_Aversion', Path_Output, x_start, x_end);

plot_risk_metric_by_TTM(RiskMetrics, 'RRA', '$\mathrm{RRA}(x)$', ...
    1.0, 3.0, 'Relative_Risk_Aversion', Path_Output, x_start, x_end);

plot_risk_metric_by_TTM(RiskMetrics, 'AP', '$\mathrm{AP}(x)$', ...
    2.5, 6.0, 'Absolute_Prudence', Path_Output, x_start, x_end);

plot_risk_metric_by_TTM(RiskMetrics, 'RP', '$\mathrm{RP}(x)$', ...
    3.0, 5.0, 'Relative_Prudence', Path_Output, x_start, x_end);

plot_risk_metric_by_TTM(RiskMetrics, 'AT', '$\mathrm{AT}(x)$', ...
    2.5, 8.0, 'Absolute_Temperance', Path_Output, x_start, x_end);

plot_risk_metric_by_TTM(RiskMetrics, 'RT', '$\mathrm{RT}(x)$', ...
    3.0, 6.5, 'Relative_Temperance', Path_Output, x_start, x_end);

