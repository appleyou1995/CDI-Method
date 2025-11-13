clear; clc

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data     = fullfile(Path_MainFolder, 'Data');
Path_Data_01  = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
Path_Output   = fullfile(Path_MainFolder, 'Code', '02  輸出資料 - no dividend');

% Specific Time-to-Maturity 
% Target_AllTTM = 30;
% Target_AllTTM = 60;
% Target_AllTTM = 90;
Target_AllTTM = 180;


%% Setting

% Option Quotes
Path_Data_inc = fullfile(Path_MainFolder, 'Data', 'IndexOptions19962022_SP500');


%% Load Data

% Risk-Free Rate (Annualized)
% [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. Risk-Free Rate (Annualized)]
FileName = 'RiskFreeRate19962022.txt';
Data_RF = load(fullfile(Path_Data, FileName));
clear FileName

% S&P 500 Dividend Yield (Annualized)
% [1. SecID | 2. Date (YYYYMMDD) | 3. Dividend Yield (Annualized)]
FileName = 'IndexDivYield19962022.txt';
Data_DY = load(fullfile(Path_Data, FileName));
clear FileName

Data_DY(:, 1) = [];


%% Selecting Target Date

FileName = ['TTM_', num2str(Target_AllTTM), '.csv'];
Target_AllDate = readtable(fullfile(Path_Data_01, FileName));

% Convert to datetime using the correct input format
Target_AllDate.date   = datetime(num2str(Target_AllDate.date),   'InputFormat', 'yyyyMMdd');
Target_AllDate.exdate = datetime(num2str(Target_AllDate.exdate), 'InputFormat', 'yyyyMMdd');

% Compute TTM (days)
Target_AllDate.TTM = days(Target_AllDate.exdate - Target_AllDate.date);

% Convert back to YYYYMMDD format
Target_AllDate.date   = year(Target_AllDate.date)  * 1e4 + ...
                        month(Target_AllDate.date) * 1e2 + ...
                        day(Target_AllDate.date);
Target_AllDate.exdate = year(Target_AllDate.exdate)  * 1e4 + ...
                        month(Target_AllDate.exdate) * 1e2 + ...
                        day(Target_AllDate.exdate);

Target_AllDate_date = Target_AllDate.date;
years = unique(floor(Target_AllDate_date / 10000));

clear FileName


%% Construct Risk-Neutral Density

Path_Data_02 = fullfile(Path_MainFolder, 'Code', '02  風險中立密度（RND）- no dividend');
addpath(Path_Data_02);

for y = 1:length(years)

    year = years(y);
    disp(['Processing year: ', num2str(year)]);
    
    Table_Smooth_AllK     = table();
    Table_Smooth_AllR     = table();
    Table_Smooth_AllR_RND = table();
    
    month_in_year = Target_AllDate_date(floor(Target_AllDate_date / 10000) == year);

    for d = 1:length(month_in_year)
        
        tic;
    
        % Setting
        Target_Date = month_in_year(d);
        idx = Target_AllDate.date == Target_Date;
        Target_TTM = Target_AllDate.TTM(idx);
    
        disp(['Processing date: ', num2str(Target_Date)]);
    
        %*********************************************************************%
        % Step 1: Load Data
        % [1.  SecID              | 2.  Date (YYYYMMDD)    | 3.  TTM (Days)    | 4.  CPflag | 5.  K  | 6. S  
        % [7.  Option Price (Bid) | 8.  Option Price (Ask) | 9.  Open Interest | 10. Volume | 11. IV | 
        % [12. Delta              | 13. Gamma              | 14. Theta         | 15. Vega   ]        
        FileName = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
        Data = load(fullfile(Path_Data_inc, FileName));
        clear FileName
            
        % Index of Data
        Index_ID = 1;
        Index_Date = 2;
        Index_TTM = 3;
        Index_CPFlag = 4;
        Index_K = 5;
        Index_S = 6;
    %     Index_F = 7;                                                     % Forward price (Theoretical)
        Index_OP_Bid = 7;
        Index_OP_Ask = 8;
        Index_OI = 9;
        Index_V = 10;
        Index_IV = 11;
        Index_Delta = 12;
        Index_Gamma = 13;
        Index_Theta = 14;
        Index_Vega = 15;
        Index_RF = Index_Vega + 1;                                         % Construction
        Index_DY = Index_Vega + 2;                                         % Construction
        Index_S_ADJ = Index_Vega + 3;                                      % Construction
    
        % Expiration Correction: Saturday to Friday
        Date_EXP_WeekDay = weekday(datenum(num2str(Data(:, Index_Date)), 'yyyymmdd') ...
                                   + Data(:, Index_TTM));      
        Data(Date_EXP_WeekDay==7, Index_TTM) = Data(Date_EXP_WeekDay==7, Index_TTM) - 1;   % Update: Data    
        clear Date_EXP_WeekDay            
        
        %*********************************************************************%
        % Step 2: Specific Data
        Index = find(Data(:, Index_ID)==108105);
        Data = Data(Index, :);                                             % Update: Data
        clear Index
        
        % Find the options data with the nearest TTM to the target TTM for the given Target_Date
        TTM = Target_TTM - 4;
        TTM_Candidates = Data(Data(:, Index_Date) == Target_Date, Index_TTM);
        TTM_Min = min(TTM_Candidates(TTM_Candidates >= TTM));
        Index = find((Data(:, Index_Date)==Target_Date) & ...
                     (Data(:, Index_TTM)==TTM_Min));
        Data = Data(Index, :);                                             % Update: Data
        clear Index
        
        % Expiration Correction: AM Settlement
        % Calculation of Risk-Free Rate, Implied Volatility, and Future Price (IvyDB Reference Manual) 
        Data(:, Index_TTM) = Data(:, Index_TTM) - 1;                       % Update: Data   
    
        %*********************************************************************%
        % Step 3: Specific Option Type
    
        %*********************************************************************%
        % Step 5: Calculation of Risk-Free Rate                       
        % RF_Target = RF_TTM(Data, Date_Target, TTM_Target)
        Data(:, Index_RF) = RF_TTM(Data_RF, ...
                                   Data(:, Index_Date), Data(:, Index_TTM));   % Annualized
                        
        %*********************************************************************%
        % Step 6: Calculation of Dividend Yield
        Index = find(Data_DY(:, 1)==Target_Date);
        Data(:, Index_DY) = Data_DY(Index, end);                           % Annualized
        clear Index
        
        %*********************************************************************%
        % Step 7: Calculation of Dividend Adjusted Stock Price 
        S0 = Data(:, Index_S);
        TTM = Data(:, Index_TTM) / 365;                                    % Annualized                                        
        DY = Data(:, Index_DY);                                            % Annualized
        
        % Data(:, Index_S_ADJ) = exp(- DY .* TTM) .* S0;
        Data(:, Index_S_ADJ) = S0;
        clear S0 TTM DY
    
        %*********************************************************************%
        % Step 8: Data Filtering
        % 8.1. Bid Price > (3 / 8)
        Index = find(Data(:, Index_OP_Bid) > (3 / 8));
        Data = Data(Index, :);                                             % Update: Data   
        clear Index
    
        %**********************************%
        % 8.2. Ask Price > Bid Price > 0
        Index = find((Data(:, Index_OP_Ask) > Data(:, Index_OP_Bid)) & ...
                     (Data(:, Index_OP_Bid) > 0)); 
        Data = Data(Index, :);                                             % Update: Data
        clear Index
            
        %**********************************%
        % 8.3. Standard No-Arbitrage Conditions (European)
        K = Data(:, Index_K);
        OP = 0.5 * (Data(:, Index_OP_Bid) + Data(:, Index_OP_Ask));
        S0_ADJ = Data(:, Index_S_ADJ);
        TTM = Data(:, Index_TTM) / 365;                                    % Annualized
        RF = Data(:, Index_RF);                                            % Annualized    
        
        Index_C = find((Data(:, Index_CPFlag)==1) & ...
                       (OP <= S0_ADJ) & ...
                       (OP >= (S0_ADJ - exp(- RF .* TTM) .* K)));
    
        Index_P = find((Data(:, Index_CPFlag)==2) & ...
                       (OP <= (exp(- RF .* TTM) .* K)) & ...
                       (OP >= (exp(- RF .* TTM) .* K - S0_ADJ)));
        clear K OP S0_ADJ TTM RF
        
        Index = union(Index_C, Index_P);
        Data = Data(Index, :);                                             % Update: Data
        clear Index_C Index_P Index                
    
        %**********************************%
        % 8.4. Out-of-the-Money (OTM) and Around At-the-Money (ATM) Options
        K = Data(:, Index_K);
        S0 = Data(:, Index_S);
        
        % Blend Point
        BP = 20;                                                           % Figlewski (2010)                            
    
        Index = find((Data(:, Index_CPFlag)==1) & ...
                     ((K >= (S0 - BP)) & (K <= (S0 + BP))));
        Data(Index, Index_CPFlag) = 31;                                    % Update: Data (CP Flag)           
        clear Index
    
        Index = find((Data(:, Index_CPFlag)==2) & ...
                     ((K >= (S0 - BP)) & (K <= (S0 + BP))));
        Data(Index, Index_CPFlag) = 32;                                    % Update: Data (CP Flag)           
        clear Index BP
              
        Index = find(((Data(:, Index_CPFlag)==1) & (K >= S0)) | ...
                     ((Data(:, Index_CPFlag)==2) & (K <= S0)) | ...
                     (fix(Data(:, Index_CPFlag) / 10)==3));      
        Data = Data(Index, :);                                             % Update: Data 
        clear Index K S0
    
        %*********************************************************************%
        % Step 9: Calculation of Option-Implied Volatility (Using the Black-Scholes Formula)
    %     % Consistent with (Option Price to Implied Volatility) and (Implied Volatility to Option Price)
    %     Type = cell(size(Data, 1), 1);                                         % Construct Space
    %     Type((Data(:, Index_CPFlag)==1) | (Data(:, Index_CPFlag)==31)) = {'Call'};   
    %     Type((Data(:, Index_CPFlag)==2) | (Data(:, Index_CPFlag)==32)) = {'Put'};
    % 
    %     K = Data(:, Index_K);
    %     OP = 0.5 * (Data(:, Index_OP_Bid) + Data(:, Index_OP_Ask));
    %     S0_ADJ = Data(:, Index_S_ADJ);   
    %     TTM = Data(:, Index_TTM) / 365;                                        % Annualized
    %     RF = Data(:, Index_RF);                                                % Annualized    
    %     
    %     Data(:, Index_IV) = blsimpv(S0_ADJ, K, RF, TTM, OP, ...
    %                                 [], [], [], Type);                         % Update: Data               
    %     clear Type K OP S0_ADJ TTM RF      
    
        % Drop NaN
        Index_Drop = find(isnan(Data(:, Index_IV)) > 0);
        Data(Index_Drop, :) = [];                                          % Update: Data 
        clear Index_Drop
        
        %*********************************************************************%
        % Step 10: Blend Implied Volatility Around the At-the-Money (ATM) Level
        Index = find((Data(:, Index_CPFlag)==31) | ...
                     (Data(:, Index_CPFlag)==32));         
        [AllK, ~, Index_AllK] = unique(Data(Index, Index_K));
    
        if length(AllK) > 1
            for i = 1:length(AllK)
                Data_BP = Data(Index(Index_AllK==i), :);                   % For Specific 'K'
                Data_BP = sortrows(Data_BP, - Index_CPFlag);               % Update: Data_BP (Sorted, Put to Call)
    
                if size(Data_BP, 1) > 1
                    % Both Call and Put Exist
                    W = (max(AllK) - AllK(i)) / (max(AllK) - min(AllK));  
            
                    Data(Index(Index_AllK==i), Index_IV) = [W (1 - W)] * Data_BP(:, Index_IV);   % Update: Data (IV)  
                    clear W
                else
                    % Either Call or Put Exist
                    Data(Index(Index_AllK==i), Index_CPFlag) = 3;          % Update: Data (CP Flag)
                end
                clear Data_BP    
            end
            clear i
        else
            if length(Index) > 1
                % Both Call and Put Exist
                Data(Index, Index_IV) = nanmean(Data(Index, Index_IV));    % Update: Data (IV)
            else
                % Either Call or Put Exist
                Data(Index, Index_CPFlag) = 3;                             % Update: Data (CP Flag)
            end
        end
        clear AllK Index_AllK
        clear Index 
        
        Data(Data(:, Index_CPFlag)==31, Index_CPFlag) = 3;                 % Update: Data (CP Flag)  
        Data(Data(:, Index_CPFlag)==32, :) = [];                           % Update: Data (CP Flag)  
        Data = sortrows(Data, Index_K);                                    % Update: Data (Sorted)
    
        %*********************************************************************%
        % Step 11: Determine the Range of Density Function
        S0 = Data(1, Index_S);
        S0_ADJ = Data(1, Index_S_ADJ);                                                
        TTM = Data(1, Index_TTM) / 365;                                    % Annualized
        RF = Data(1, Index_RF);                                            % Annualized
    
        % All Possible Range
        K_Low = (0.3 / 100) * S0;                                          % Hollstein and Prokopczuk (2016 JFQA) 
        K_High = 3 * S0;                                                   % Hollstein and Prokopczuk (2016 JFQA) 
        Smooth_AllK = K_Low:0.05:K_High;
        clear K_Low K_High
    
        %**********************************%
        % Step 11-1: Least-Squares Spline Approximation (Empirical)
        % Fourth Order (1 Knot)
        LSS = spap2(1, 4, Data(:, Index_K), Data(:, Index_IV));
        LSS = spap2(newknt(LSS), 4, Data(:, Index_K), Data(:, Index_IV));  % Update: LSS
    
        % Smoothed Implied Volatility
        Smooth_K = Smooth_AllK((Smooth_AllK >= min(Data(:, Index_K))) & ...
                               (Smooth_AllK <= max(Data(:, Index_K))));
        Smooth_IV = fnval(LSS, Smooth_K);
        clear LSS
    
        % Smoothed Option Price
        S0_ADJ = S0_ADJ * ones(size(Smooth_K));                            % Update: S0_ADJ
        TTM = TTM * ones(size(Smooth_K));                                  % Update: TTM
        RF = RF * ones(size(Smooth_K));                                    % Update: RF
    
        Smooth_OP = blsprice(S0_ADJ, Smooth_K, RF, TTM, Smooth_IV, []);
    
        %**********************************%
        % Step 11-2: Risk-Neutral Density and Distribution (Empirical)
        % Smooth_EMP_PDF and Smooth_EMP_CDF (w.r.t. Smooth_K)
        TTM = TTM(1);                                                      % Update: TTM
        RF = RF(1);                                                        % Update: RF
    
        % Risk-Neutral Density (PDF)
        % K_{2} to K_{N - 1}
        Smooth_EMP_PDF = exp(RF * TTM) * ...
                         (Smooth_OP(3:end) - 2 * Smooth_OP(2:(end - 1)) + Smooth_OP(1:(end - 2))) ./ ...
                         ((Smooth_K(3:end) - Smooth_K(2:(end - 1))) .^ 2);
    
        % Risk-Neutral Distribution (CDF)
        % K_{2} to K_{N - 1}
        Smooth_EMP_CDF = exp(RF * TTM) * ...
                         ((Smooth_OP(3:end) - Smooth_OP(1:(end - 2))) ./ ...
                         (Smooth_K(3:end) - Smooth_K(1:(end - 2)))) + 1;
    %     clear Smooth_OP
        clear TTM RF 
    
        % K_{2} to K_{N - 1}
        Smooth_K = Smooth_K(2:(end - 1));                                  % Update: Smooth_K
        Smooth_OP = Smooth_OP(2:(end - 1));                                % Update: Smooth_OP (Just Record)
        Smooth_IV = Smooth_IV(2:(end - 1));                                % Update: Smooth_IV (Just Record)
        
        %*********************************************************************%
        % Step 12: Risk-Neutral Density (Right-Tail Connection)
        % Setting
        BP_R0 = 0.95; 
        BP_R1 = 0.98; 
     
        % (BP_R1, K_R1, EMP_PDF_R1)
        Index = find((Smooth_EMP_CDF - BP_R1) >= 0);
        if length(Index) > 0
            BP_R1 = Smooth_EMP_CDF(Index(1));                              % Update: BP_R1    
            
            K_R1 = Smooth_K(Index(1)); 
            EMP_PDF_R1 = Smooth_EMP_PDF(Index(1));
        else
            BP_R1 = Smooth_EMP_CDF(end);                                   % Update: BP_R1    
            
            K_R1 = Smooth_K(end);     
            EMP_PDF_R1 = Smooth_EMP_PDF(end);      
        end
        BP_R0 = BP_R1 - 0.03;                                              % Update: BP_R0 
        clear Index 
    
        % (BP_R0, K_R0, EMP_PDF_R0, EMP_CDF_R0)
        Index = find((Smooth_EMP_CDF - BP_R0) >= 0);
        BP_R0 = Smooth_EMP_CDF(Index(1));                                  % Update: BP_R0
        K_R0 = Smooth_K(Index(1));
        EMP_PDF_R0 = Smooth_EMP_PDF(Index(1));
        EMP_CDF_R0 = Smooth_EMP_CDF(Index(1));
        clear Index 
     
        % (Parameters_GEV_R, Smooth_GEV_R_PDF, Smooth_GEV_R_CDF, FitError_GEV_R)
        try
            % Solve System of Equations (Three Conditions)
            % (mu, sigma, k) = (Location, Scale, Shape)
            [mu sigma k] = Fit_GEV_PDF(K_R0, K_R1, ...
                                       EMP_CDF_R0, EMP_PDF_R0, EMP_PDF_R1);
    
            % Right Tail of Risk-Neutral Density (PDF)
            Smooth_GEV_R_PDF = gevpdf(Smooth_AllK, ...
                                      k, sigma, mu);
                          
            % Right Tail of Risk-Neutral Distribution (CDF)
            Smooth_GEV_R_CDF = gevcdf(Smooth_AllK, ...
                                      k, sigma, mu);     
                              
            % Parameters 
            Parameters_GEV_R = [mu sigma k];      
            
            % Error of Three Conditions
            FitError_GEV_R = CheckError_GEV_PDFCDF(mu, sigma, k, ...
                                                   K_R0, K_R1, ...
                                                   EMP_CDF_R0, EMP_PDF_R0, EMP_PDF_R1);            
        catch
        end                       
        clear EMP_CDF_R0 EMP_PDF_R0 EMP_PDF_R1
        clear mu sigma k 
    
        %*********************************************************************%
        % Step 13: Risk-Neutral Density (Left-Tail Connection, Reverse Left to Right)
        % Setting
        BP_L0 = 0.05;
        BP_L1 = 0.02;
        
        % (BP_L1, K_L1, EMP_PDF_L1)
        Index = find((BP_L1 - Smooth_EMP_CDF) >= 0);
        if length(Index) > 0
            BP_L1 = Smooth_EMP_CDF(Index(end));                            % Update: BP_L1 
                
            K_L1 = Smooth_K(Index(end));  
            EMP_PDF_L1 = Smooth_EMP_PDF(Index(end));
        else
            BP_L1 = Smooth_EMP_CDF(1);                                     % Update: BP_L1    
                
            K_L1 = Smooth_K(1);  
            EMP_PDF_L1 = Smooth_EMP_PDF(1);    
        end
        BP_L0 = BP_L1 + 0.03;                                              % Update: BP_L0
        clear Index 
    
        % (BP_L0, K_L0, EMP_PDF_L0, EMP_CDF_L0)
        Index = find((BP_L0 - Smooth_EMP_CDF) >= 0);
        BP_L0 = Smooth_EMP_CDF(Index(end));                                % Update: BP_L0  
        K_L0 = Smooth_K(Index(end));
        EMP_PDF_L0 = Smooth_EMP_PDF(Index(end));
        EMP_CDF_L0 = Smooth_EMP_CDF(Index(end));
        clear Index 
    
        % (Parameters_GEV_L, Smooth_GEV_L_PDF, Smooth_GEV_L_CDF, FitError_GEV_L)
        try
            % Solve System of Equations (Three Conditions)
            % (mu, sigma, k) = (Location, Scale, Shape)
            [mu sigma k] = Fit_GEV_PDF(- K_L0, - K_L1, ...
                                       1 - EMP_CDF_L0, EMP_PDF_L0, EMP_PDF_L1);
    
            % Left Tail of Risk-Neutral Density (PDF)
            Smooth_GEV_L_PDF = gevpdf(- Smooth_AllK, ...
                                      k, sigma, mu);
                          
            % Left Tail of Risk-Neutral Distribution (CDF)
            Smooth_GEV_L_CDF = 1 - gevcdf(- Smooth_AllK, ...
                                          k, sigma, mu);   
                              
            % Parameters 
            Parameters_GEV_L = [(- mu) sigma k]; 
    
            % Error of Three Conditions
            FitError_GEV_L = CheckError_GEV_PDFCDF(mu, sigma, k, ...
                                                   - K_L0, - K_L1, ...
                                                   1 - EMP_CDF_L0, EMP_PDF_L0, EMP_PDF_L1);                 
        catch
        end
        clear EMP_CDF_L0 EMP_PDF_L0 EMP_PDF_L1  
        clear mu sigma k 
    
        %*********************************************************************%
        % Step 14: Combination of Full Density (PDF, Stock Price)
        Smooth_AllK_RND = nan(size(Smooth_AllK));                          % Construct Space
    
        % Risk-Neutral Density (Empirical)
        Index_EMP = find((Smooth_AllK >= K_L0) & ...
                         (Smooth_AllK <= K_R0));
        Smooth_AllK_RND(Index_EMP) = Smooth_EMP_PDF((Smooth_K >= K_L0) & ...
                                                    (Smooth_K <= K_R0));
    
        % Generalized Extreme Value Function (GEV, Right Tail)
        Index_GEV_R = find(Smooth_AllK >= K_R0);
        try
            Smooth_AllK_RND(Index_GEV_R) = Smooth_GEV_R_PDF(Index_GEV_R);
        catch
        end
    
        % Generalized Extreme Value Function (GEV, Left Tail)
        Index_GEV_L = find(Smooth_AllK <= K_L0);
        try
            Smooth_AllK_RND(Index_GEV_L) = Smooth_GEV_L_PDF(Index_GEV_L);
        catch
        end
    
    %     % Normalization: Sum to One
    %     Smooth_AllK_RND = Smooth_AllK_RND / trapz(Smooth_AllK, Smooth_AllK_RND);   % Update: Smooth_AllK_RND (Normalized)
        
        Smooth_AllR = Smooth_AllK / S0_ADJ(1);
        Smooth_AllR_RND = S0_ADJ(1) * Smooth_AllK_RND;
        
        %*********************************************************************%
        % Step 15: Output
        columnName = num2str(Target_Date);
        Table_Smooth_AllK.(columnName)     = Smooth_AllK;
        Table_Smooth_AllR.(columnName)     = Smooth_AllR;
        Table_Smooth_AllR_RND.(columnName) = Smooth_AllR_RND;
    
        % Clear Variable
        clear Smooth_AllK Smooth_AllR Smooth_AllK_RND Smooth_AllR_RND
        clear Index_EMP Index_GEV_L Index_GEV_R
    
        clear Smooth_K Smooth_IV Smooth_OP Smooth_EMP_PDF Smooth_EMP_CDF
        clear BP_L0 BP_L1 K_L0 K_L1 FitError_GEV_L Parameters_GEV_L Smooth_GEV_L_PDF Smooth_GEV_L_CDF
        clear BP_R0 BP_R1 K_R0 K_R1 FitError_GEV_R Parameters_GEV_R Smooth_GEV_R_PDF Smooth_GEV_R_CDF
    
        clear Target_Date Target_TTM Data
        clear Index_ID Index_Date Index_TTM Index_CPFlag Index_K Index_S Index_F Index_OP_Bid Index_OP_Ask Index_OI Index_V Index_IV
        clear Index_Delta Index_Gamma Index_Theta Index_Vega 
        clear Index_RF Index_DY Index_IS Index_IS_ADJ Index_S_ADJ

        elapsed_time = toc;
        disp(['     Spend Time: ', num2str(elapsed_time), ' Seconds']);
    end
    
    FileName = fullfile(Path_Output, ['TTM_', num2str(Target_AllTTM), '_RND_Tables_', num2str(year), '.mat']);
    save(FileName, 'Table_Smooth_AllK', 'Table_Smooth_AllR', 'Table_Smooth_AllR_RND');
    clear FileName
end

clear Data_RF Data_DY
clear RootName_WRDS Path_Data_inc RootName_TTM
clear d 
