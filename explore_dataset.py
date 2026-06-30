import pandas as pd
import os
import json

dataset_path = r'c:\Users\prade\Downloads\Dateset for CrasheJeevansetu-20260627T135230Z-3-001\Dateset for CrasheJeevansetu'

# Load first training file to inspect
df = pd.read_parquet(os.path.join(dataset_path, 'train-00000-of-00011.parquet'))
print('Data Types:')
print(df.dtypes)
print('\nFirst row:')
print(df.iloc[0].to_dict())
print('\nLabel distribution:')
print(df['label'].value_counts())
print('\nSample data:')
print(df.head(3))

# Check other files
print('\n\n=== File Summary ===')
files = sorted([f for f in os.listdir(dataset_path) if f.endswith('.parquet')])
for f in files:
    df_temp = pd.read_parquet(os.path.join(dataset_path, f))
    print(f'{f}: {len(df_temp)} records, labels: {df_temp["label"].value_counts().to_dict()}')
