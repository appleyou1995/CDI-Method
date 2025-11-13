clear; clc

%% Main folder (adjust if needed)

Path_MainFolder = 'D:\Google\我的雲端硬碟\學術｜研究與論文\論文著作\CDI Method';

Path_Data    = fullfile(Path_MainFolder, 'Data');
Path_Data_01 = fullfile(Path_MainFolder, 'Code', '01  輸出資料');
Path_Output  = fullfile(Path_MainFolder, 'Code', '01  輸出資料');


%% Load S&P 500 index data

FileName = fullfile(Path_Data, 'spindx.csv');
SPX_raw  = readtable(FileName);
SPX = SPX_raw(:, {'caldt', 'spindx'});
SPX.caldt = datetime(string(SPX.caldt), 'InputFormat','yyyyMMdd');
clear FileName SPX_raw


%% Load TTM data

Target_TTM = [30, 60, 90, 180];
TTM_tables = cell(length(Target_TTM), 1);

for i = 1:length(Target_TTM)
    ttm = Target_TTM(i);
    FileName = sprintf('TTM_%d.csv', ttm);
    TTM_tables{i} = readtable(fullfile(Path_Data_01, FileName));
end

clear FileName i ttm


%% Compute realized return

for k = 1:length(TTM_tables)

    fprintf('k = %d\n', k);
    T = TTM_tables{k};

    % Convert date & exdate to datetime format
    T.date   = datetime(string(T.date),   'InputFormat','yyyyMMdd');
    T.exdate = datetime(string(T.exdate), 'InputFormat','yyyyMMdd');

    % === 1. Map date to its corresponding SPX index value ===
    [tf_date, loc_date] = ismember(T.date, SPX.caldt);
    T.date_spindx = NaN(height(T), 1);
    T.date_spindx(tf_date) = SPX.spindx(loc_date(tf_date));

    % === 2. Map exdate to SPX index (fill forward if exact match is missing) ===
    [tf_ex, loc_ex] = ismember(T.exdate, SPX.caldt);
    ex_sp = NaN(height(T), 1);

    % Fill values for exact matches
    ex_sp(tf_ex) = SPX.spindx(loc_ex(tf_ex));

    % For unmatched exdate values, search for the next available trading day
    missing_idx = find(~tf_ex);

    for ii = missing_idx'

        next_day = T.exdate(ii);
        loc_next = find(SPX.caldt >= next_day, 1, 'first');

        if ~isempty(loc_next)
            ex_sp(ii) = SPX.spindx(loc_next);
        else
            ex_sp(ii) = NaN;   % In case the date exceeds the SPX dataset range
        end
    end

    T.exdate_spindx = ex_sp;

    % === 3. Compute realized return (price-only, no dividend adjustment) ===
    T.realized_ret = T.exdate_spindx ./ T.date_spindx;

    % Save updated table back to the list
    TTM_tables{k} = T;

end

clear k ii loc_next loc_ex loc_date next_day missing_idx tf_ex tf_date ex_sp T


%% Output

for k = 1:length(TTM_tables)

    T = TTM_tables{k};
    date_str = string(T.date, "yyyyMMdd");

    Out = table(date_str, T.realized_ret, ...
        'VariableNames', {'date', 'realized_ret'});

    FileName = sprintf('Realized_Return_TTM_%d.csv', Target_TTM(k));
    writetable(Out, fullfile(Path_Output, FileName));

    fprintf('Saved: %s  (N = %d)\n', FileName, height(Out));
end