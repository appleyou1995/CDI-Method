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
NumPaths = 100;


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
    % 5: Calculate Log Returns (Monthly)

    % Daily Return (Log Return)
    RET_EGARCH_Forecast = Est_Mean + sqrt(V_EGARCH_Forecast) .* I_EGARCH_Forecast;

    % Daily Return to Monthly Return (Log Return) 
    RET_Monthly = sum(RET_EGARCH_Forecast, 2);

    % Log Return to Gross Return
    RET_Monthly = exp(RET_Monthly);                                        % Update: RET_Monthly    

    %*********************************************************************%
    % 6. Output
    FileName = ['GrossReturn_' num2str(Target_Date)];
    save(fullfile(Path_Data_Output, FileName), 'RET_Monthly')

    % Clear Variable
    clear Target_Date NumPeriods
    clear EstModel_EGARCH Est_Mean Est_Omega Est_Alpha Est_Beta Est_Gamma
    clear V_EGARCH I_EGARCH
    clear Index_EI Data_EI V_EGARCH_Forecast I_EGARCH_Forecast RET_EGARCH_Forecast
    clear RET_Monthly
end

clear Data_RET
clear d i j