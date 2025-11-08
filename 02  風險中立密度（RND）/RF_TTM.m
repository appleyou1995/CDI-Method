function RF_Target = RF_TTM(Data, Date_Target, TTM_Target)
% Data: [1. Date (YYYYMMDD) | 2. TTM (Days) | 3. RF (Annualized)]

    % Number of Unique Pairs
    [AllPair, ~, Index_Pair] = unique([Date_Target TTM_Target], 'rows');

    % Preallocate output vector for efficiency
    RF_Pair = nan(size(AllPair, 1), 1);

    % Convert the first column (YYYYMMDD) in Data to datetime
    Date_Data = datetime(num2str(Data(:, 1)), 'InputFormat', 'yyyyMMdd');
    
    % Loop through each unique (Date, TTM) pair
    for d = 1:size(AllPair, 1)

        % Convert the target date to datetime
        targetDate = datetime(num2str(AllPair(d, 1)), 'InputFormat', 'yyyyMMdd');

        % Search for data up to 10 days before the target date
        found = false;
        for i = 0:10
            searchDate = targetDate - days(i);
            idx = find(Date_Data == searchDate, 1);
            if ~isempty(idx)
                sameDate = Date_Data == searchDate;
                Data_TTM = Data(sameDate, 2);
                Data_RF = Data(sameDate, 3);
                found = true;
                break;
            end
        end
        clear idx

        % If no matching data found, skip this target pair
        if ~found
            fprintf('No RF data found for target date %s (searched up to 10 days before)\n', ...
                    string(targetDate, 'yyyy-mm-dd'));
            continue;
        end

        % Perform linear interpolation (or extrapolation if out of range)
        if (AllPair(d, 2) >= min(Data_TTM)) && (AllPair(d, 2) <= max(Data_TTM))
            RF_Pair(d, 1) = interp1(Data_TTM, Data_RF, AllPair(d, 2), 'linear');
        else
            RF_Pair(d, 1) = interp1(Data_TTM, Data_RF, AllPair(d, 2), 'linear', 'extrap');
        end
        clear Data_TTM Data_RF
    end
    clear AllPair
    
    % Summary
    RF_Target = RF_Pair(Index_Pair);
    clear Index_Pair RF_Pair
    clear d i

end