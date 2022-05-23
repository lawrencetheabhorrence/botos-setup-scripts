# run this in the csv folder
# after you have converted all your
# worksheets into csv's
# all csv's should be in one folder

# Data Cleaning Guidelines
# -------------------------
# There should only be 7 columns:
# 1. Last Name:
# 2. First Name
# 3. Batch:
# 4. Section:
# 5. Username:
# 6. Password:
# 7. Email Address:
# You must follow the exact spelling of these columns otherwise the merging of the data won't work properly.
# DO NOT PUT A NUMBER COLUMN NOR PUT DATA OUTSIDE OF THESE COLUMNS
# You need to check if your data is uniform, a column should be either all text or all numbers. If a column that is supposed to be all numbers has a nonnumerical character in a cell, then it will be interpreted as text and won't be accepted by the database.
# There should be no empty rows between data
# after converting to csv, check if there are any empty rows in the data and delete them. This is possibly made due to filters in the Sheets that were generated by the emailing system.

import pandas as pd
import os

paths = [f for f in os.listdir('.') if f.endswith('csv')]
dfs = [pd.read_csv(f,index_col=False) for f in paths]
column_order=["Last Name:","First Name:","Batch:","Section:","Username:","Password:","Email Address:"]
for df in dfs:
    # remove trailing spaces
    df.columns = df.columns.str.strip()
    df = df.reindex(columns=column_order)
# merge the users and write to a csv
pd.concat(dfs).to_csv("userdata.csv",index=False)
