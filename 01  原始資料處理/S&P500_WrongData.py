from pathlib  import Path
#from datetime import datetime

import pandas            as pd
#import numpy             as np
#import matplotlib.pyplot as plt
#import datetime          as dt


pd.set_option('display.max_columns', 50)

# Windows
folder_path = Path('D:/Google/我的雲端硬碟/學術｜研究與論文/論文著作/CDI Method/Data')

# Macbook
folder_path = Path('/Users/irisyu/Library/CloudStorage/GoogleDrive-jouping.yu@gmail.com/我的雲端硬碟/學術｜研究與論文/論文著作/CDI Method/Data')


WRDS_SPX = pd.read_csv(folder_path/"SPX.csv")
WRDS_INX = pd.read_csv(folder_path/"spindx.csv")


# 姿穎學姊提供正確篩選的日期
Target_AllDate = pd.read_csv(folder_path/"Target_AllDate.csv")   
Target_AllDate['date']   = pd.to_datetime(Target_AllDate['date'], format = '%Y%m%d')
Target_AllDate['exdate'] = pd.to_datetime(Target_AllDate['exdate'], format = '%Y%m%d')



# 處理選擇權資料

option_data = WRDS_SPX
option_data['strike_price'] = option_data['strike_price'] / 1000



# 處理指數資料
WRDS_INX.info()
SP500_Index = WRDS_INX[['caldt', 'spindx']]



# 合併 option_data_1m 和 SP500_Index
option_data = pd.merge(left = SP500_Index,  right = option_data, left_on = ['caldt'], right_on = ['date'])


# time to maturity
option_data['diff'] = (option_data['exdate'] - option_data['date']).dt.days


# 欄位排序調整
cols = option_data.columns.tolist()
cols = cols[2:7] + cols[-1:] + cols[7:9] + cols[1:2] + cols[9:-1]
option_data = option_data[cols[:]]



option_data.info()
option_data_head = WRDS_SPX.head(5)
option_data_tail = WRDS_SPX.tail(5)


df_1996_01 = option_data[(option_data['date'].dt.year == 1996) & (option_data['date'].dt.month == 1)]
df_2009 = option_data[(option_data['date'].dt.year == 2009) & (option_data['date'].dt.year == 2008)]


#####################################################################################################
# We use options with "one month to maturity", giving a nonoverlapping time-series of options prices.
#####################################################################################################


option_data['date_weekday']   = option_data['date'].dt.day_name()
option_data['exdate_weekday'] = option_data['exdate'].dt.day_name()

option_data['date_weekday'].value_counts()
option_data['exdate_weekday'].value_counts()




# 留下到期日是星期五的選擇權
option_data_Friday = option_data[(option_data['exdate_weekday'] == 'Friday')]
option_data_Friday['date_weekday'].value_counts()

# 留下交易日是星期三的選擇權
option_data_Wednesday = option_data_Friday[(option_data_Friday['date_weekday'] == 'Wednesday')]
option_data_Wednesday['diff'].value_counts()


# 留下距到期日為一個月(30天)的選擇權
option_data_1m = option_data_Wednesday[(option_data_Wednesday['diff'] == 30)]


# 待確認區間
# option_data_1m = option_data[(option_data['diff'] > 27) & (option_data['diff'] < 32)]

# check
# option_data[option_data['diff'] == 28].iloc[:, : 6]


#####################################################################################################
# We also use OptionMetrics "implied volatilities" for each strike price at each date in our set.
#####################################################################################################

option_data_no_imvol = option_data_1m.dropna(subset = ['impl_volatility'])



#####################################################################################################
# We use 
# - put prices for relatively low strike prices,
# - call prices for relatively high strike prices and
# - weighted averages for intermediate strike prices.
#
#   The relative weights of puts and calls are determined using a logistic function that is 
#   - centered at the closing index value
#   - with a volatility parameter that is half of the range of observable option prices.
#####################################################################################################


option_CP_price = option_data_no_imvol

# 選擇權價格通常會以 (bid + offer)/2 來衡量
option_CP_price['option_price'] = (option_CP_price['best_bid'] + option_CP_price['best_offer']) / 2


#####################################################################################################
# Each month, for the options data with best bids (or last prices when bids are not available) 
# exceeding $ 3/8 , we fit a fourth-degree spline to implied volatilities associated with each 
# observed strike price. 
#####################################################################################################

# 不確定是否需要
option_CP_0375 = option_CP_price[option_CP_price['option_price'] > 0.375]

# 擇一
option_CP = option_CP_0375
option_CP = option_CP_price

option_CP_head = option_CP.head(10)


# 待確認「 S 和 K 相等 」的區間
option_CP_eq = option_CP[option_CP['spindx'] == option_CP['strike_price']]


option_CP['keep'] =""

option_CP.loc[(option_CP['spindx'] > option_CP['strike_price']) & (option_CP['cp_flag'] == 'P'), 'keep'] = 'True' 
option_CP.loc[(option_CP['spindx'] < option_CP['strike_price']) & (option_CP['cp_flag'] == 'C'), 'keep'] = 'True' 
option_CP.loc[option_CP['spindx'] == option_CP['strike_price'], 'keep'] = 'True'

option_CP = option_CP[option_CP['keep'] == 'True']
option_CP = option_CP.sort_values(['date', 'exdate', 'strike_price', 'spindx', 'option_price'], ascending = True)

option_CP_check = option_CP[['date', 'exdate', 'diff', 'keep', 'cp_flag', 'spindx', 'strike_price', 'option_price', 'best_bid', 'best_offer']]
option_CP_check = option_CP_check.head(1000)


option_CP_imvol = option_CP[['option_price', 'strike_price', 'impl_volatility', 'cp_flag']]
option_CP_imvol = option_CP_imvol.sort_values(['strike_price', 'impl_volatility'], ascending = True)

option_CP_imvol_C = option_CP_imvol[option_CP_imvol['cp_flag'] == 'C']
option_CP_imvol_P = option_CP_imvol[option_CP_imvol['cp_flag'] == 'P']

option_CP_imvol_C_plot = option_CP_imvol_C.plot.scatter(y = ['impl_volatility'], x = ['strike_price'], title='Call Options', s = 5)
option_CP_imvol_C_plot.set_xlabel("Strike Price")
option_CP_imvol_C_plot.set_ylabel("Implied Volatility")

option_CP_imvol_P_plot = option_CP_imvol_P.plot.scatter(y = ['impl_volatility'], x = ['strike_price'], title='Put Options', s = 5)
option_CP_imvol_P_plot.set_xlabel("Strike Price")
option_CP_imvol_P_plot.set_ylabel("Implied Volatility")

option_CP_imvol_plot = option_CP_imvol.plot.scatter(y = ['impl_volatility'], x = ['strike_price'], title='All Options', s = 5)
option_CP_imvol_plot.set_xlabel("Strike Price")
option_CP_imvol_plot.set_ylabel("Implied Volatility")



