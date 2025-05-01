from sqlalchemy import text

import pandas as pd
import numpy  as np
import os
import wrds


# %%  論文資料夾路徑

Path_PaperFolder = '我的雲端硬碟/學術｜研究與論文/論文著作/CDI Method'


# %%  Win 資料夾路徑

Path_Win = 'D:/Google/'
Path_dir = os.path.join(Path_Win, Path_PaperFolder)


# %%  Mac 資料夾路徑

Path_Mac = '/Users/irisyu/Library/CloudStorage/GoogleDrive-jouping.yu@gmail.com/'
Path_dir = os.path.join(Path_Mac, Path_PaperFolder)


# %%  Input and Output Path

Path_Input  = os.path.join(Path_dir, 'Code/01  輸出資料/')
Path_Output = os.path.join(Path_dir, 'Code/01  輸出資料/')


# %%  Connect to WRDS & Get the properties of database

conn = wrds.Connection(wrds_username='irisyu')

libraries          = conn.list_libraries()
tables_optionm_all = conn.list_tables(library='optionm_all')


# %%  OptionMetrics - Index Dividend Yield

conn = wrds.Connection(wrds_username='irisyu')

col_headers_idxdvd = conn.describe_table(library='optionm_all', table='idxdvd')

query_optionm = text("""
                     SELECT 
                         secid, date, expiration, rate
                     FROM 
                         optionm_all.idxdvd
                     WHERE 
                         date BETWEEN '1996-01-01' AND '2022-12-31'
                     AND
                         secid = '108105'
                     """)
                   
df_optionm_div = conn.raw_sql(query_optionm)
df_optionm_div['dividend_yield'] = df_optionm_div['rate'] / 100

conn.close()

df_optionm_div['date'] = pd.to_datetime(df_optionm_div['date'])
df_optionm_div['expiration'] = pd.to_datetime(df_optionm_div['expiration'])

df_optionm_div['TTM'] = (df_optionm_div['expiration'] - df_optionm_div['date']).dt.days

df_optionm_div['date_day'] = pd.to_datetime(df_optionm_div['date']).dt.day_name()
df_optionm_div['exdate_day'] = pd.to_datetime(df_optionm_div['expiration']).dt.day_name()

df_optionm_div.loc[df_optionm_div['exdate_day'] == 'Saturday', 'expiration'] -= pd.DateOffset(days=1)
df_optionm_div['exdate_day'] = df_optionm_div['expiration'].dt.day_name()

df_optionm_div['date'] = df_optionm_div['date'].dt.strftime('%Y-%m-%d')
df_optionm_div['expiration'] = df_optionm_div['expiration'].dt.strftime('%Y-%m-%d')

df_optionm_div = df_optionm_div.sort_values(by=['date', 'expiration'])


# %%  Setting query & Load data [ S&P 500 Index ]

conn = wrds.Connection(wrds_username='irisyu')

query_SP500 = text("""
                   SELECT caldt, spindx
                   FROM crsp.dsp500
                   WHERE caldt BETWEEN '1996-01-01' AND '2023-12-31'
                   """)
                    
df_SP500 = conn.raw_sql(query_SP500)

df_SP500['caldt'] = pd.to_datetime(df_SP500['caldt'], format='%Y-%m-%d')
df_SP500['caldt'] = df_SP500['caldt'].dt.strftime('%Y-%m-%d')

conn.close()


# %%  Load Target Date & Exdate Data

# TTM_list = [30, 60, 90, 180]
TTM = 180

filename = f'Hsieh_TTM_{TTM}.csv'

df_Target_Date_Exdate = pd.read_csv(os.path.join(Path_Input, filename))

df_Target_Date_Exdate['date'] = pd.to_datetime(df_Target_Date_Exdate['date'], format='%Y%m%d').dt.strftime('%Y-%m-%d')
df_Target_Date_Exdate['exdate'] = pd.to_datetime(df_Target_Date_Exdate['exdate'], format='%Y%m%d').dt.strftime('%Y-%m-%d')


# %%  Adding missing dates from df_Target_Date_Exdate['exdate'] to df_SP500['caldt']
####  and filling NaN values with the previous row's values

df_SP500_copy = df_SP500.copy()

missing_exdates = df_Target_Date_Exdate[~df_Target_Date_Exdate['exdate'].isin(df_SP500_copy['caldt'])]['exdate']
new_rows = pd.DataFrame({'caldt': missing_exdates})

for col in df_SP500_copy.columns:
    if col != 'caldt':
        new_rows[col] = np.nan

df_SP500_copy = pd.concat([df_SP500_copy, new_rows], ignore_index=True)
df_SP500_copy = df_SP500_copy.sort_values(by='caldt').reset_index(drop=True)
df_SP500_copy.fillna(method='ffill', inplace=True)


# %%  Merge: TTM_list = [30]

# df_merged = pd.merge(df_Target_Date_Exdate, df_SP500_copy[['caldt', 'spindx']], left_on='date', right_on='caldt', how='left')
# df_merged.rename(columns={'spindx': 'date_spindx'}, inplace=True)
# df_merged.drop(columns=['caldt'], inplace=True)

# df_merged = pd.merge(df_merged, df_SP500_copy[['caldt', 'spindx']], left_on='exdate', right_on='caldt', how='left')
# df_merged.rename(columns={'spindx': 'exdate_spindx'}, inplace=True)
# df_merged.drop(columns=['caldt'], inplace=True)

# df_merged = pd.merge(df_merged, df_optionm_div, how='left', 
#                      left_on=['date', 'exdate'], 
#                      right_on=['date', 'expiration'])

# row_diff = len(df_merged) - len(df_Target_Date_Exdate)

# print(f"Number of missing values in 'dividend_yield': {df_merged['dividend_yield'].isna().sum()}")
# print(f"Row difference between df_merged and df_Target_Date_Exdate: {row_diff} rows")


# %%  Merge: TTM_list = [60, 90, 180]

df_merged = pd.merge(df_Target_Date_Exdate, df_SP500_copy[['caldt', 'spindx']], left_on='date', right_on='caldt', how='left')
df_merged.rename(columns={'spindx': 'date_spindx'}, inplace=True)
df_merged.drop(columns=['caldt'], inplace=True)

df_merged = pd.merge(df_merged, df_SP500_copy[['caldt', 'spindx']], left_on='exdate', right_on='caldt', how='left')
df_merged.rename(columns={'spindx': 'exdate_spindx'}, inplace=True)
df_merged.drop(columns=['caldt'], inplace=True)

df_optionm_filtered = df_optionm_div[(df_optionm_div['TTM'] >= TTM - 4) & (df_optionm_div['TTM'] <= TTM + 0)].copy()

duplicated_dates = df_optionm_filtered['date'][df_optionm_filtered['date'].duplicated()].unique()
df_duplicates = df_optionm_filtered[df_optionm_filtered['date'].isin(duplicated_dates)]

df_merged = pd.merge(df_merged, df_optionm_filtered, how='left', on='date')
row_diff = len(df_merged) - len(df_Target_Date_Exdate)

print(f"Number of missing values in 'dividend_yield': {df_merged['dividend_yield'].isna().sum()}")
print(f"Row difference between df_merged and df_Target_Date_Exdate: {row_diff} rows")


# %%  Calculate Realized Return

TTM_mode = df_merged['TTM'].mode().iloc[0]
TTM_Annualized = (TTM_mode - 1) /365

df_merged['S0_ADJ'] = np.exp(- df_merged['dividend_yield'] * TTM_Annualized) * df_merged['date_spindx']
df_merged['realized_ret'] = df_merged['exdate_spindx'] / df_merged['S0_ADJ']


# %%  Output

df_output = df_merged[['date', 'realized_ret']]
df_output['date'] = df_merged['date'].str.replace('-', '')

output_filename = f'Realized_Return_TTM_{TTM}.csv'
df_output.to_csv(os.path.join(Path_Output, output_filename), index=False)





