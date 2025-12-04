from sqlalchemy import text

import pandas as pd
import numpy  as np
import os
import wrds


# %%  Main folder path

Path_PaperFolder = '我的雲端硬碟/學術｜研究與論文/論文著作/CDI Method'


# %%  Win folder path

#  Win 
Path_Win = 'D:/Google/'
Path_dir = os.path.join(Path_Win, Path_PaperFolder)

# Mac
# Path_Mac = '/Users/irisyu/Library/CloudStorage/GoogleDrive-jouping.yu@gmail.com/'
# Path_dir = os.path.join(Path_Mac, Path_PaperFolder)


# %%  Input and Output Path

Path_TTM    = os.path.join(Path_dir, 'Code/01  輸出資料/')
Path_Output = os.path.join(Path_dir, 'Code/01  輸出資料/')


# %%  Setting TTM_INFO

TTM_INFO = {
    30: {'filename': 'TTM_30.csv',  'delta_days': 29},
    60: {'filename': 'TTM_60.csv',  'delta_days': 59},
    90: {'filename': 'TTM_90.csv',  'delta_days': 89},
    180:{'filename': 'TTM_180.csv', 'delta_days':179},
}


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
                              date BETWEEN '1996-01-01' AND '2021-12-31'
                          AND
                              days < 365
                          """)
                          
df_rate = conn.raw_sql(query_optionm_rate)
df_rate['rate'] = df_rate['rate'] / 100
df_rate['date'] = pd.to_datetime(df_rate['date']).dt.strftime('%Y-%m-%d')

conn.close()


# %% For each TTM, compute its own risk-free series

DAY_COUNT = 365

rf_tables = {}  # store df for each TTM

for TTM, info in TTM_INFO.items():

    file_path = os.path.join(Path_TTM, info['filename'])
    if not os.path.exists(file_path):
        print(f"Warning: Missing {file_path}")
        continue

    df_dates = pd.read_csv(file_path, usecols=['date'])
    df_dates['date'] = df_dates['date'].astype(str)
    df_dates['date'] = pd.to_datetime(df_dates['date'], format='%Y%m%d').dt.strftime('%Y-%m-%d')

    delta_days = info['delta_days']
    colname_date = f"date_{TTM}"
    colname_rf   = f"rf_gross_{delta_days}d"

    records = []

    for date in df_dates['date']:
        sub = df_rate[df_rate['date'] == date]

        if sub.empty:
            continue

        if sub['days'].min() <= delta_days <= sub['days'].max():
            rate_interp = np.interp(delta_days, sub['days'], sub['rate'])

            rf_log = rate_interp * (delta_days / DAY_COUNT)
            rf_gross = np.exp(rf_log)

            records.append({colname_date: date, colname_rf: rf_gross})

    df_rf = pd.DataFrame(records)

    # 轉回 YYYYMMDD
    df_rf[colname_date] = df_rf[colname_date].str.replace('-', '')

    rf_tables[TTM] = df_rf


# %% Combine four TTM tables horizontally

df_risk_free_rate = pd.DataFrame()

for TTM in [30, 60, 90, 180]:
    if TTM in rf_tables:
        df_risk_free_rate = pd.concat([df_risk_free_rate, rf_tables[TTM]], axis=1)


# %%  Output

output_path = os.path.join(Path_Output, 'Risk_Free_Rate.csv')
df_risk_free_rate.to_csv(output_path, index=False)


# %%  Plot

import matplotlib.pyplot as plt
import pandas as pd

# 確保是從你現在的 df_risk_free_rate 開始
df = df_risk_free_rate.copy()

# 把每個 TTM 各自轉成 datetime 再畫圖
pairs = [
    ('date_30',  'rf_gross_29d',  'TTM = 30  (29d)'),
    ('date_60',  'rf_gross_59d',  'TTM = 60  (59d)'),
    ('date_90',  'rf_gross_89d',  'TTM = 90  (89d)'),
    ('date_180', 'rf_gross_179d', 'TTM = 180  (179d)'),
]

plt.figure(figsize=(10, 8))

for col_date, col_rf, label in pairs:
    # 把這個 TTM 的日期＋利率抓出來，先把 NaN 刪掉避免亂畫
    sub = df[[col_date, col_rf]].dropna()

    # 轉成 datetime（原本是 19960117 這種格式）
    t = pd.to_datetime(sub[col_date].astype(str), format='%Y%m%d')

    plt.plot(t, sub[col_rf], label=label)

plt.xlabel('Date')
plt.ylabel('Risk-free gross factor')
plt.title('Monthly risk-free gross factors for different TTM')
plt.grid(True, alpha=0.3)
plt.legend()
plt.tight_layout()
plt.show()
