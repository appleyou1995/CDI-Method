clear; clc
warning('off', 'all');

%% 1. 設定路徑

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';
Path_Data_inc = fullfile(Path_MainFolder, 'Data', 'IndexOptions19962022_SP500');
Path_Data_01  = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
Path_Data_02  = fullfile(Path_MainFolder, 'Code', '02  輸出資料');


%% 2. 設定多個目標到期天數 (Target TTM List)

Target_TTM_List = [30, 60, 90, 180];

% 設定欄位索引 (保持不變)
Index_Date = 2;
Index_TTM = 3;
Index_CPFlag = 4;
Index_K = 5;
Index_S = 6;
Index_OP_Bid = 7; 
Index_IV = 11;


%% 3. 最外層迴圈：針對每個 TTM 執行一次

for t = 1:length(Target_TTM_List)

    Target_TTM = Target_TTM_List(t);
    disp('===================================================');
    disp(['Starting Process for Target TTM: ', num2str(Target_TTM)]);
    disp('===================================================');

    % 3-1. 讀取該 TTM 對應的日期檔案 (例如 Hsieh_TTM_30.csv)
    FileName = ['Hsieh_TTM_', num2str(Target_TTM), '.csv'];
    FilePath = fullfile(Path_Data_01, FileName);
    
    if ~exist(FilePath, 'file')
        warning(['找不到日期檔案: ', FileName, '，跳過此 TTM。']);
        continue;
    end
    
    Target_Date_Exdate = readtable(FilePath);
    Target_AllDate = Target_Date_Exdate.date;
    
    % 初始化儲存變數 (每個 TTM 都要清空重新算)
    years = unique(floor(Target_AllDate / 10000));
    Summary_Results = []; 

    % 4. 內層迴圈：處理該 TTM 下的每一年
    for y = 1:length(years)
        year = years(y);
        % disp(['  Processing Year: ', num2str(year)]); % 可註解掉以減少畫面雜訊
        
        % 初始化當年度的累加變數
        Yearly_Count = 0;
        Yearly_Sum_Price = 0;
        Yearly_Sum_IV = 0;
        Yearly_Sum_Moneyness = 0;
        
        month_in_year = Target_AllDate(floor(Target_AllDate / 10000) == year);
        
        for i = 1:length(month_in_year)
            Target_Date = month_in_year(i);
            TTM_Threshold = Target_TTM - 4;
            
            % 讀取每日選擇權資料
            FileName_OP = ['OP' num2str(fix(Target_Date / 10000)) '_' num2str(fix(rem(Target_Date, 10000) / 100)) '.txt'];
            if ~exist(fullfile(Path_Data_inc, FileName_OP), 'file')
                continue; 
            end
            Data_inc = load(fullfile(Path_Data_inc, FileName_OP));
            
            % --- [篩選邏輯開始] ---
            % 1. 篩選 TTM
            TTM_Candidates = Data_inc(Data_inc(:, Index_Date) == Target_Date, Index_TTM);
            if isempty(TTM_Candidates), continue; end
            TTM_Min = min(TTM_Candidates(TTM_Candidates >= TTM_Threshold));
            if isempty(TTM_Min), continue; end
            Data = Data_inc(Data_inc(:, Index_Date) == Target_Date & Data_inc(:, Index_TTM) == TTM_Min, :);
            
            % 2. 修正到期日 (假設只影響 TTM 值，不影響篩選結果，略過 Weekday 判斷以加速)
            Data(:, Index_TTM) = Data(:, Index_TTM) - 1; % AM Settlement
            
            % 3. 資料過濾 (Data Filtering)
            % (3-1) Bid >= 0.375
            Index = Data(:, Index_OP_Bid) >= 0.375;
            Data = Data(Index, :);
            
            % (3-2) OTM Selection
            % 標記 CPFlag (Call=31, Put=32)
            Index_C = (Data(:, Index_CPFlag) == 1) & (Data(:, Index_K) >= Data(:, Index_S));
            Index_P = (Data(:, Index_CPFlag) == 2) & (Data(:, Index_K) <= Data(:, Index_S));
            Data(Index_C, Index_CPFlag) = 31;
            Data(Index_P, Index_CPFlag) = 32;
            
            % 最終保留 OTM Call, OTM Put 及原本標記為 3X 的資料
            Index = ((Data(:, Index_CPFlag)==1) & (Data(:, Index_K) >= Data(:, Index_S))) | ...
                    ((Data(:, Index_CPFlag)==2) & (Data(:, Index_K) <= Data(:, Index_S))) | ...
                    (fix(Data(:, Index_CPFlag) / 10)==3);
            Data = Data(Index, :);
            % --- [篩選邏輯結束] ---
            
            if isempty(Data)
                continue;
            end
            
            % 計算當日統計量
            Moneyness = Data(:, Index_K) ./ Data(:, Index_S);
            
            Yearly_Count = Yearly_Count + size(Data, 1);
            Yearly_Sum_Price = Yearly_Sum_Price + sum(Data(:, Index_OP_Bid));
            Yearly_Sum_IV = Yearly_Sum_IV + sum(Data(:, Index_IV));
            Yearly_Sum_Moneyness = Yearly_Sum_Moneyness + sum(Moneyness);
        end
        
        % 計算該年度平均
        if Yearly_Count > 0
            Avg_Price = Yearly_Sum_Price / Yearly_Count;
            Avg_IV = Yearly_Sum_IV / Yearly_Count;
            Avg_Moneyness = Yearly_Sum_Moneyness / Yearly_Count;
        else
            Avg_Price = NaN; Avg_IV = NaN; Avg_Moneyness = NaN;
        end
        
        Summary_Results = [Summary_Results; year, Yearly_Count, Avg_Price, Avg_IV, Avg_Moneyness];
    end

    % 5. 輸出該 TTM 的結果

    if ~isempty(Summary_Results)
        ResultTable = array2table(Summary_Results, ...
            'VariableNames', {'Year', 'Obs_Count', 'Avg_Price', 'Avg_IV', 'Avg_Moneyness'});
        
        OutFileName = ['Summary_Stats_TTM_', num2str(Target_TTM), '.csv'];
        OutFile = fullfile(Path_Data_02, OutFileName);
        writetable(ResultTable, OutFile);
        disp(['Finished TTM ', num2str(Target_TTM), '. Saved to: ', OutFileName]);
    else
        disp(['No data processed for TTM ', num2str(Target_TTM)]);
    end
    
    disp(' '); % 空一行
end

disp('All TTMs Processed Successfully.');