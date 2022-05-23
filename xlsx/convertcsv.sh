#!/bin/bash
# Assuming that the excel files have 3 sheets
pip install xlsx2csv
mkdir split
for f in *.xlsx
do
  for i in {1..3}
  do
    xlsx2csv -s $i $f "split/${f%.*}-$i.csv"
  done
done
cd split
python merge-users.py
