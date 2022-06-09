# run this in the csv folder
# after you have converted all your
# worksheets into csv's
# all csv's should be in one folder

import pandas as pd
import os

folder = os.path.expanduser('~/botos-setup-scripts/xlsx/split')

paths = [f for f in os.listdir(folder) if f.endswith('csv')]
dfs = [pd.read_csv(folder + "/" + f,index_col=False,skip_blank_lines=True).dropna(how="all",inplace=True) for f in paths]
column_order=["Last Name:","First Name:","Batch:","Section:","Username:","Password:","Email:"]
df = df.select_dtypes(['object']).apply(lambda x: x.str.strip())
for df in dfs:
    # remove trailing spaces
    df.columns = df.columns.str.strip()
    df = df.reindex(columns=column_order)
# merge the users and write to a csv
pd.concat(dfs).to_csv(folder + "/userdata.csv",index=False)
