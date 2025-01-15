clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data    = fullfile(Path_MainFolder, 'Data');
Path_Data_07 = fullfile(Path_MainFolder, 'Code', '07  EGARCH');
Path_Data_Output = fullfile(Path_MainFolder, 'Code', '07  輸出資料');


%% Setting

% Forecast Period: 1 month
AllFP = 21;

% Data Period
Date_Begin = 199601;
Date_End   = 202112;

% Historical Window (EGARCH Model)
HISWindow_EST = 3800;                                                      % Days
HISWindow_EI  = 3800;                                                      % Days

% Simulation Path (EGARCH Model)
NumPaths = 30000;


%% Load Data: Stock Return

% [1. Date (YYYYMMDD) | 2. Stock Return]
Data_RET = load(fullfile(Path_Data_07, 'StockReturn_19262022_SP500.txt'));

% S&P 500 Stock Returns
Data_RET = sortrows(Data_RET, 1);                                          % Update: Data_RET (Sort by Date)


%% Load Data: Target Date (Monthly)

Target_Date_Exdate = readtable(fullfile(Path_Data, 'Target_AllDate.csv'));
Date_Monthly = Target_Date_Exdate.date;
clear Target_Date_Exdate


%% Forecast S&P 500 Daily Returns with EGARCH(1,1) Model

Annual_PDF = struct;

for d = 1:length(Date_Monthly)

    Target_Date = Date_Monthly(d, 1);
    disp(['Processing date: ', num2str(Target_Date)]);

    %*********************************************************************%
    % 2. Specify EGARCH(1,1) Model: 'EstModel_EGARCH'

    HISWindow = HISWindow_EST;
    
    % 2.0 Log Return
    Index_HISDate = find(Data_RET(:, 1) < Target_Date);
    Index_HISDate = Index_HISDate((end - HISWindow + 1):end);              % Update: Index_HISDate
    RET = log(1 + Data_RET(Index_HISDate, end));
    clear Index_HISDate HISWindow

    % 2.1 Estimate Model Parameters
    % Reference: https://www.mathworks.com/help/econ/converting-from-garch-functions-to-models.html
    % Reference: https://www.mathworks.com/help/econ/specify-egarch-models-using-egarch.html
    % The Last Observation of 'RET' is the Most Recent
    Model_EGARCH = egarch('GARCHLags', 1, 'ARCHLags', 1, 'LeverageLags', 1, 'Offset', nan);
    EstModel_EGARCH = estimate(Model_EGARCH, RET, 'Display', 'Off');
    clear Model_EGARCH

    % Parameters
    Est_Mean  = EstModel_EGARCH.Offset;                                    % Mean Equation
    Est_Omega = EstModel_EGARCH.Constant;                                  % Variance Equation
    Est_Alpha = cell2mat(EstModel_EGARCH.ARCH);                            % Variance Equation (ARCH Effect)
    Est_Beta  = cell2mat(EstModel_EGARCH.GARCH);                           % Variance Equation (GARCH Effect)
    Est_Gamma = cell2mat(EstModel_EGARCH.Leverage);                        % Variance Equation (Leverage Effect)

    % 2.2 Infer Conditional Variances (In-Sample)
    V_EGARCH = infer(EstModel_EGARCH, RET);
    
    % 2.3 Infer Innovations (In-Sample)
    I_EGARCH = (RET - Est_Mean) ./ sqrt(V_EGARCH);

    clear RET

    %*********************************************************************%
    % 3. Forecast Conditional Variances Using the Specified EGARCH(1,1) Model

    HISWindow = HISWindow_EI;
    NumPeriods = AllFP;                                                    % Trading Days
    
    % 3.0 Empirical Innovations (EI)
    Data_EI = I_EGARCH((end - HISWindow + 1):end);
    
    % 3.1 Forecast Innovations 
    Index_EI = randi(HISWindow, NumPaths, NumPeriods);                     % Sampling With Replacement
    I_EGARCH_Forecast = Data_EI(Index_EI);
    clear HISWindow 

    % 3.2 Forecast Conditional Variances
    V_EGARCH_Forecast = nan(size(I_EGARCH_Forecast));                      % Construct Space

    for i = 1:NumPeriods
        if i > 1
            V_EGARCH_Forecast(:, i) = exp(Est_Omega + ...
                                          Est_Alpha * (abs(I_EGARCH_Forecast(:, i - 1)) - sqrt(2 / pi)) + ...
                                          Est_Beta * log(V_EGARCH_Forecast(:, i - 1)) + ...
                                          Est_Gamma * I_EGARCH_Forecast(:, i - 1));
        else
            V_EGARCH_Forecast(:, i) = exp(Est_Omega + ...
                                          Est_Alpha * (abs(I_EGARCH(end)) - sqrt(2 / pi)) + ...
                                          Est_Beta * log(V_EGARCH(end)) + ...
                                          Est_Gamma * I_EGARCH(end));     
        end
    end

    %*********************************************************************%
    % 5. Calculate Log Returns (Monthly)

    % Daily Return (Log Return)
    RET_EGARCH_Forecast = Est_Mean + sqrt(V_EGARCH_Forecast) .* I_EGARCH_Forecast;

    % Daily Return to Monthly Return (Log Return) 
    RET_Monthly = sum(RET_EGARCH_Forecast, 2);

    % Log Return to Gross Return
    RET_Monthly = exp(RET_Monthly);                                        % Update: RET_Monthly    

    %*********************************************************************%
    % 6. Calculate PDF of Monthly Returns

    % Manually specify PDF_X range
    PDF_X = linspace(0, 3, 30000);

    % Use Kernel Density Estimation to estimate PDF
    [PDF_Values_temp, PDF_X_temp] = ksdensity(RET_Monthly, ...
                                              'Bandwidth', 0.001, ...
                                              'Support', [0, 3], ...
                                              'NumPoints', 30000);

    % Adjust PDF_Values to match manually specified PDF_X range
    PDF_Values = interp1(PDF_X_temp, PDF_Values_temp, PDF_X, 'linear', 0);

    %*********************************************************************%
    % 7. Output

    % Extract year from Target_Date
    Year = floor(Target_Date / 10000);

    % Append PDF data to annual storage
    if ~isfield(Annual_PDF, ['Year_' num2str(Year)])
        Annual_PDF.(['Year_' num2str(Year)]).X = [];
        Annual_PDF.(['Year_' num2str(Year)]).Values = [];
    end

    Annual_PDF.(['Year_' num2str(Year)]).X = [Annual_PDF.(['Year_' num2str(Year)]).X; PDF_X];
    Annual_PDF.(['Year_' num2str(Year)]).Values = [Annual_PDF.(['Year_' num2str(Year)]).Values; PDF_Values];

    % FileName_PDF = ['PDF_' num2str(Target_Date)];
    % save(fullfile(Path_Data_Output, FileName_PDF), 'PDF_X', 'PDF_Values');

    % Clear Variable
    clear NumPeriods
    clear EstModel_EGARCH Est_Mean Est_Omega Est_Alpha Est_Beta Est_Gamma
    clear V_EGARCH I_EGARCH
    clear Index_EI Data_EI V_EGARCH_Forecast I_EGARCH_Forecast RET_EGARCH_Forecast
    % clear Target_Date RET_Monthly PDF_X PDF_Values
end

clear Data_RET
clear d i j


%% Output

Years = fieldnames(Annual_PDF);

for i = 1:length(Years)
    Year = Years{i};
    FileName_Annual = [Year '_EGARCH_PDF.mat'];
    save(fullfile(Path_Data_Output, FileName_Annual), '-struct', 'Annual_PDF', Year);
end

% Clear annual storage
clear Annual_PDF Years i Year FileName_Annual


%% Plot: Scatter Plot of RET_Monthly

figure;
scatter(1:length(RET_Monthly), RET_Monthly, '.');
title('Scatter Plot of RET\_Monthly');
xlabel('Index');
ylabel('Value');
grid on;


%% Plot: Histogram of RET_Monthly

figure;
histogram(RET_Monthly, 100);
title('Histogram of RET\_Monthly');
xlabel('Value');
ylabel('Frequency');
xlim([0.8, 1.2]);
grid on;


%% Plot: Cumulative Plot of RET_Monthly

figure;
plot(sort(RET_Monthly), (1:length(RET_Monthly)) / length(RET_Monthly), 'LineWidth', 2);
title('Cumulative Plot of RET\_Monthly');
xlabel('Value');
ylabel('Cumulative Probability');
xlim([0.8, 1.2]);
grid on;


%% Plot: PDF after ksdensity

figure;
plot(PDF_X, PDF_Values, 'LineWidth', 1.5);
title(['PDF of Gross Return for ', num2str(Target_Date)]);
xlabel('Gross Return');
ylabel('Probability Density');
xlim([0.8, 1.2]);
grid on;


%% Plot: CDF after ksdensity

CDF_Values = cumtrapz(PDF_X, PDF_Values);

figure;
plot(PDF_X, CDF_Values, 'LineWidth', 2);
title(['CDF of Gross Return for ', num2str(Target_Date)]);
xlabel('Gross Return');
ylabel('Cumulative Probability');
% xlim([0.8, 1.2]);
xlim([0, 3]);
ylim([0, 1]);
grid on;


%% Plot: Overlay Cumulative Plot and CDF after ksdensity

CDF_Values = cumtrapz(PDF_X, PDF_Values);

figure;
hold on;

plot(PDF_X, CDF_Values, 'LineWidth', 2, 'DisplayName', 'CDF from ksdensity');

plot(sort(RET_Monthly), (1:length(RET_Monthly)) / length(RET_Monthly), ...
     'LineWidth', 2, 'DisplayName', 'Empirical CDF');

title('Comparison of Empirical CDF and CDF from ksdensity');
xlabel('Value');
ylabel('Cumulative Probability');
% xlim([0.8, 1.2]);
xlim([0, 3]);
ylim([0, 1]);
legend('show');
grid on;

hold off;
