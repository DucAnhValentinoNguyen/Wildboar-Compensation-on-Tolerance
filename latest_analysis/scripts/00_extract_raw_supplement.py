# 00: builds output/models/raw_supplement.csv (extra Qualtrics fields not in the 'Input Data' sheet) from data/3_Data.xlsx, sheet 'Raw data'.
import os
import pandas as pd
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

raw = pd.read_excel(os.path.join(REPO, 'data', '3_Data.xlsx'), sheet_name='Raw data', header=None)
data = raw.iloc[2:].reset_index(drop=True)
data.columns = range(data.shape[1])

out = pd.DataFrame()
out['ID'] = data[0].astype(int)

# Species multi-select dummies (cols 60-71)
species_map = {
    60: 'sp_wildboar', 61: 'sp_blackbear', 62: 'sp_monkey', 63: 'sp_porcupine',
    64: 'sp_badger', 65: 'sp_muntjac', 66: 'sp_bluesheep', 67: 'sp_panda',
    68: 'sp_hedgehog', 69: 'sp_squirrel', 70: 'sp_rabbit', 71: 'sp_birds'
}
for col, name in species_map.items():
    out[name] = pd.to_numeric(data[col], errors='coerce').fillna(0).astype(int)
out['n_species_conflict'] = out[list(species_map.values())].sum(axis=1)
out['multispecies_conflict'] = (out['n_species_conflict'] > 1).astype(int)

# Month dummies (cols 101-112) -> peak season indicator
month_cols = list(range(101, 113))
month_names = [f'month_{i+1}' for i in range(12)]
for col, name in zip(month_cols, month_names):
    out[name] = pd.to_numeric(data[col], errors='coerce').fillna(0).astype(int)
out['n_months_conflict'] = out[month_names].sum(axis=1)

# Q88 timing
timing_map = {'夜晚': 'Night', '白天': 'Daytime', '晨昏': 'Dawn/Dusk'}
out['conflict_timing'] = data[115].map(timing_map)

# Q27 experience (multi-select)
def has_tag(s, tag):
    if pd.isna(s):
        return np.nan
    return int(tag in s)
out['exp_seen'] = data[146].apply(lambda s: has_tag(s, '看到野猪'))
out['exp_scared_attacked'] = data[146].apply(lambda s: has_tag(s, '被野猪惊吓或攻击'))
out['exp_relative_attacked'] = data[146].apply(lambda s: has_tag(s, '亲友曾被野猪攻击'))
out['exp_none'] = data[146].apply(lambda s: has_tag(s, '以上均无'))
out['direct_threat_exposure'] = ((out['exp_scared_attacked'] == 1) | (out['exp_relative_attacked'] == 1)).astype(int)

# Q28 hunting prevalence
hunt_map = {'经常有': 5, '偶尔有': 4, '很少有': 3, '可能有': 2, '没有': 1, '不知道': np.nan}
hunt_label = {'经常有': 'Often', '偶尔有': 'Occasionally', '很少有': 'Rarely', '可能有': 'Possible', '没有': 'Never', '不知道': "Don't know"}
out['hunted_ordinal'] = data[147].map(hunt_map)
out['hunted_label'] = data[147].map(hunt_label)

# Q29 reaction
reaction_map = {'驱赶': 'Drive away', '撤离': 'Evacuate', '互不干涉': 'Avoid/coexist'}
out['reaction'] = data[148].map(reaction_map)

# PE detail (strategy-specific effectiveness 0-5, and count used 0/1)
pe_cols = {'PE_A': 168, 'PE_B': 172, 'PE_C': 176, 'PE_D': 180, 'PE_E': 184, 'PE_F': 188, 'PE_G': 192}
pe_count_cols = {'PE_A_count': 169, 'PE_B_count': 173, 'PE_C_count': 177, 'PE_D_count': 181,
                 'PE_E_count': 185, 'PE_F_count': 189, 'PE_G_count': 193}
for name, col in pe_cols.items():
    out[name] = pd.to_numeric(data[col], errors='coerce')
for name, col in pe_count_cols.items():
    out[name] = pd.to_numeric(data[col], errors='coerce').fillna(0).astype(int)
out['PE_count'] = pd.to_numeric(data[196], errors='coerce')

# Three-word raw text (for text/frequency analysis)
out['word1'] = data[159]
out['word2'] = data[160]
out['word3'] = data[161]

out_path = os.path.join(REPO, 'latest_analysis', 'output', 'models', 'raw_supplement.csv')
out.to_csv(out_path, index=False, encoding='utf-8-sig')
print("Saved:", out_path, out.shape)
print(out.head(3).T)
