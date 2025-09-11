from sqlalchemy import text

import pandas as pd
import numpy  as np
import os
import wrds


# %%  Main folder path

Path_PaperFolder = '我的雲端硬碟/學術｜研究與論文/論文著作/CDI Method'


# %%  Win folder path

Path_Win = 'D:/Google/'
Path_dir = os.path.join(Path_Win, Path_PaperFolder)


# %%  Mac folder path

Path_Mac = '/Users/irisyu/Library/CloudStorage/GoogleDrive-jouping.yu@gmail.com/'
Path_dir = os.path.join(Path_Mac, Path_PaperFolder)


# %%  Input and Output Path

Path_Input  = os.path.join(Path_dir, 'Data/')
Path_Output = os.path.join(Path_dir, 'Code/01  原始資料處理/')


# %%  Load Data

df_Target_Date_Exdate = pd.read_csv(os.path.join(Path_Input, 'Target_AllDate.csv'))

df_Target_Date_Exdate['date'] = pd.to_datetime(df_Target_Date_Exdate['date'], format='%Y%m%d').dt.strftime('%Y-%m-%d')
df_Target_Date_Exdate['exdate'] = pd.to_datetime(df_Target_Date_Exdate['exdate'], format='%Y%m%d').dt.strftime('%Y-%m-%d')


# %%  Connect to WRDS & Get the properties of database [ Risk-free Rate ]

conn = wrds.Connection(wrds_username='irisyu')

# OptionMetrics - Zero Coupon Yield Curve
conn.describe_table(library='optionm_all', table='zerocd')

query_optionm_rate = text("""
                          SELECT
                              date, days, rate
                          FROM
                              optionm_all.zerocd
                          WHERE 
                              date BETWEEN '1996-01-01' AND '2022-12-31'
                          AND
                              days < 100
                          """)
                          
df_rate = conn.raw_sql(query_optionm_rate)
df_rate['rate'] = df_rate['rate'] / 100

conn.close()


# %%  Calculate risk-free rate (TTM = 29)

df_rate['date'] = pd.to_datetime(df_rate['date'], format='%Y-%m-%d').dt.strftime('%Y-%m-%d')
df_filtered = df_rate[df_rate['date'].isin(df_Target_Date_Exdate['date'])]

TTM = 29

# Create an empty list to store the results
interpolated_rates = []

# Get all unique dates
unique_dates = df_filtered['date'].unique()

# Perform interpolation for each unique date
for date in unique_dates:
    # Filter out all data under that date
    subset = df_filtered[df_filtered['date'] == date]
    
    # Ensure the 'days' column has the required interpolation range
    if subset['days'].min() <= TTM <= subset['days'].max():
        # Use linear interpolation to calculate the rate
        interpolated_rate = np.interp(TTM, subset['days'], subset['rate'])
        
        # Save the result
        interpolated_rates.append({'date': date, 'days': TTM, 'rate': interpolated_rate})

# Convert the results to a DataFrame
df_risk_free_rate = pd.DataFrame(interpolated_rates)


# %%  Calculate risk-free rate measures for a 29-day horizon

DAY_COUNT = 365      # Day-count convention (ACT/365)
DELTA_DAYS = 29      # Target maturity = 29 days

# 29-day continuously compounded log return (not annualized)
df_risk_free_rate['rf_log_29d']    = df_risk_free_rate['rate'] * (DELTA_DAYS / DAY_COUNT)

# 29-day gross risk-free factor R^f = exp(log return)
df_risk_free_rate['rf_gross_29d']  = np.exp(df_risk_free_rate['rf_log_29d'])

# 29-day simple return (discrete return, not annualized)
df_risk_free_rate['rf_simple_29d'] = df_risk_free_rate['rf_gross_29d'] - 1

# 29-day discount factor (present value of $1 received in 29 days)
df_risk_free_rate['df_29d']        = 1.0 / df_risk_free_rate['rf_gross_29d']


# %%  Output

df_risk_free_rate['date'] = df_risk_free_rate['date'].str.replace('-', '')
df_risk_free_rate.to_csv(os.path.join(Path_Output, 'Risk_Free_Rate.csv'), index=False)


