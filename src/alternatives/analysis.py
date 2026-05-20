"""
Wild boar tolerance — alternative modeling.
Baseline: OLS replicating PLS-PM relationships.
Alternatives: Random Forest, XGBoost, MLP (NN), Tabular self-attention (Transformer-style).
"""
import warnings, json, os
warnings.filterwarnings("ignore")
import numpy as np
import pandas as pd
from sklearn.model_selection import KFold, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.ensemble import RandomForestRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.metrics import r2_score, mean_squared_error, mean_absolute_error
import xgboost as xgb

RNG = 42
np.random.seed(RNG)

# ---------- Load & build constructs ----------
df = pd.read_excel('3_Data.xlsx', sheet_name='Input Data')

# IMPORTANT: Codebook says Tol2 and Tol3 are reverse-encoded, but inspection of raw
# inter-item correlations shows Tol2_1 ALREADY positively correlates with Tol1_5 / Tol4_5
# in the data file (r=0.51 and 0.29).  This indicates Tol2 has already been reverse-coded
# during data preparation, so we only need to reverse Tol3 (whose correlation pattern
# shows it has NOT been reversed).  Re-reversing Tol2 (as in the original PLS-PM run)
# destroys the scale's coherence (alpha turns negative).
df['Tol3_rev'] = 6 - df['Tol3_1']

# Construct scores = mean of indicators (matches PLS-PM convention for the LCs here;
# original used PLS-PM weights but mean is the standard transparent baseline).
constructs = {
    'ConflictExp_WB':  ['CP_WB1','CP_WB2','CP_WB3','CP_WB4'],
    'ConflictExp_All': ['CP_A1','CP_A2','CP_A3'],
    'Tangible_Costs':  ['TC1_DamagedArea','TC2_EconomicLoss'],     # log-transform later
    'Intangible_Costs':['IC1','IC2_DescriptiveAttitude'],
    'Intangible_Benefits':['IB'],
    'Tolerance':       ['Tol1_5','Tol2_1','Tol3_rev','Tol4_5'],
    'Prevention_Eff':  ['PE'],
    'Compensation_Anticipation': ['CA1','CA2','CA3'],              # mixed scales -> z-score then mean
    'Policy_Support':  ['PS1','PS2'],
}

# Log-transform monetary/area tangible cost indicators before standardising
df['TC1_log'] = np.log1p(df['TC1_DamagedArea'])
df['TC2_log'] = np.log1p(df['TC2_EconomicLoss'])
df['CA3_log'] = np.log1p(df['CA3'])

# z-score each indicator, then average within construct
def z(s): return (s - s.mean())/s.std(ddof=0)

indicator_map = {
    'ConflictExp_WB':  ['CP_WB1','CP_WB2','CP_WB3','CP_WB4'],
    'ConflictExp_All': ['CP_A1','CP_A2','CP_A3'],
    'Tangible_Costs':  ['TC1_log','TC2_log'],
    'Intangible_Costs':['IC1','IC2_DescriptiveAttitude'],
    'Intangible_Benefits':['IB'],
    'Tolerance':       ['Tol1_5','Tol2_1','Tol3_rev','Tol4_5'],
    'Prevention_Eff':  ['PE'],
    'Compensation_Anticipation': ['CA1','CA2','CA3_log'],
    'Policy_Support':  ['PS1','PS2'],
}

scores = pd.DataFrame(index=df.index)
for name, items in indicator_map.items():
    scores[name] = pd.concat([z(df[i]) for i in items], axis=1).mean(axis=1)

# Add compensation participation and basic demographics (raw)
scores['Compensation_Participation'] = df['CE0']
for c in ['Q4_Gender','Q5_Age','Q6_Education','Q8_AnnualIncome','Q9_AgriProportion',
          'Q11_TotalArea','Q13_TotalLivestock','Q14_HouseholdAsset','Q3_InNP']:
    scores[c] = df[c]

# Cronbach's alpha (multi-item constructs only)
def cronbach(items):
    X = pd.concat(items, axis=1).dropna()
    k = X.shape[1]
    if k < 2: return np.nan
    var_sum = X.var(ddof=1).sum()
    var_total = X.sum(axis=1).var(ddof=1)
    return (k/(k-1)) * (1 - var_sum/var_total)

alphas = {}
for name, items in indicator_map.items():
    if len(items) >= 2:
        alphas[name] = cronbach([df[i] for i in items])
print("Cronbach's alpha:")
for k,v in alphas.items(): print(f"  {k:30s} {v:.3f}")

# ---------- Target & features ----------
y = scores['Tolerance'].values
feature_cols = [
    'ConflictExp_WB','ConflictExp_All','Tangible_Costs','Intangible_Costs',
    'Intangible_Benefits','Prevention_Eff','Compensation_Anticipation','Policy_Support',
    'Compensation_Participation','Q4_Gender','Q5_Age','Q6_Education',
    'Q8_AnnualIncome','Q9_AgriProportion','Q11_TotalArea','Q13_TotalLivestock',
    'Q14_HouseholdAsset','Q3_InNP'
]
X = scores[feature_cols].copy()
# Standardise continuous predictors
to_scale = [c for c in feature_cols if c not in ['Compensation_Participation','Q4_Gender','Q3_InNP']]
X[to_scale] = (X[to_scale] - X[to_scale].mean())/X[to_scale].std(ddof=0)
X = X.values

# Save scores for the report
scores.to_csv('construct_scores.csv', index=False)

print(f"\nDataset: n = {len(y)}, p = {X.shape[1]}")
print(f"Tolerance:  mean={y.mean():.3f}, sd={y.std():.3f}")

# ---------- 5-fold CV evaluator ----------
def cv_eval(make_model, X, y, n_splits=5, seed=RNG):
    kf = KFold(n_splits=n_splits, shuffle=True, random_state=seed)
    r2s, rmses, maes = [], [], []
    for tr, te in kf.split(X):
        m = make_model()
        m.fit(X[tr], y[tr])
        p = m.predict(X[te])
        r2s.append(r2_score(y[te], p))
        rmses.append(np.sqrt(mean_squared_error(y[te], p)))
        maes.append(mean_absolute_error(y[te], p))
    return np.array(r2s), np.array(rmses), np.array(maes)

def report(name, r2, rmse, mae):
    print(f"  {name:30s}  R²={r2.mean():.3f}±{r2.std():.3f}   "
          f"RMSE={rmse.mean():.3f}±{rmse.std():.3f}   "
          f"MAE={mae.mean():.3f}±{mae.std():.3f}")
    return dict(model=name, r2_mean=r2.mean(), r2_sd=r2.std(),
                rmse_mean=rmse.mean(), rmse_sd=rmse.std(),
                mae_mean=mae.mean(), mae_sd=mae.std())

results = []
print("\n=== 5-fold cross-validated performance ===")
# 1. Baseline: OLS (linear regression — closest classical counterpart to PLS-PM)
results.append(report("OLS (linear baseline)", *cv_eval(lambda: LinearRegression(), X, y)))
# 2. Ridge
results.append(report("Ridge (L2)", *cv_eval(lambda: Ridge(alpha=1.0, random_state=RNG), X, y)))
# 3. Random Forest
results.append(report("Random Forest", *cv_eval(
    lambda: RandomForestRegressor(n_estimators=500, max_depth=None,
                                  min_samples_leaf=5, random_state=RNG, n_jobs=-1), X, y)))
# 4. XGBoost
results.append(report("XGBoost", *cv_eval(
    lambda: xgb.XGBRegressor(n_estimators=400, max_depth=4, learning_rate=0.05,
                             subsample=0.8, colsample_bytree=0.8,
                             reg_lambda=1.0, random_state=RNG, n_jobs=-1,
                             verbosity=0), X, y)))
# 5. MLP (sklearn neural network)
results.append(report("MLP (NN, 64-32)", *cv_eval(
    lambda: MLPRegressor(hidden_layer_sizes=(64,32), activation='relu',
                         alpha=1e-3, learning_rate_init=1e-3, max_iter=2000,
                         early_stopping=True, validation_fraction=0.15,
                         n_iter_no_change=30, random_state=RNG), X, y)))

# ---------- Tabular self-attention "Transformer-style" model ----------
import torch
import torch.nn as nn

class TabTransformer(nn.Module):
    """One self-attention block over features, treated as tokens with learned projections."""
    def __init__(self, n_features, d_model=16, n_heads=2, dropout=0.2):
        super().__init__()
        self.proj = nn.Linear(1, d_model)               # each scalar feature -> d_model
        self.feat_emb = nn.Parameter(torch.randn(n_features, d_model)*0.02)
        self.attn = nn.MultiheadAttention(d_model, n_heads, dropout=dropout, batch_first=True)
        self.ln1  = nn.LayerNorm(d_model)
        self.ff   = nn.Sequential(nn.Linear(d_model, d_model*2), nn.GELU(),
                                  nn.Dropout(dropout), nn.Linear(d_model*2, d_model))
        self.ln2  = nn.LayerNorm(d_model)
        self.head = nn.Sequential(nn.Flatten(),
                                  nn.Linear(n_features*d_model, 32), nn.GELU(),
                                  nn.Dropout(dropout), nn.Linear(32, 1))
    def forward(self, x):                                # x: (B, F)
        h = self.proj(x.unsqueeze(-1)) + self.feat_emb   # (B, F, d_model)
        a, _ = self.attn(h, h, h, need_weights=False)
        h = self.ln1(h + a)
        h = self.ln2(h + self.ff(h))
        return self.head(h).squeeze(-1)

def fit_transformer(Xtr, ytr, Xva, yva, n_features, epochs=300, lr=1e-3, wd=1e-3, seed=RNG):
    torch.manual_seed(seed); np.random.seed(seed)
    model = TabTransformer(n_features)
    opt = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=wd)
    sch = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=epochs)
    loss_fn = nn.MSELoss()
    Xtr_t, ytr_t = torch.tensor(Xtr, dtype=torch.float32), torch.tensor(ytr, dtype=torch.float32)
    Xva_t, yva_t = torch.tensor(Xva, dtype=torch.float32), torch.tensor(yva, dtype=torch.float32)
    best, best_state, patience, no_improve = float('inf'), None, 40, 0
    for ep in range(epochs):
        model.train()
        # one batch — dataset is small
        idx = torch.randperm(len(Xtr_t))
        for s in range(0, len(idx), 64):
            b = idx[s:s+64]
            opt.zero_grad()
            p = model(Xtr_t[b])
            loss = loss_fn(p, ytr_t[b])
            loss.backward(); opt.step()
        sch.step()
        model.eval()
        with torch.no_grad():
            v = loss_fn(model(Xva_t), yva_t).item()
        if v < best - 1e-5:
            best, best_state, no_improve = v, {k:v.clone() for k,v in model.state_dict().items()}, 0
        else:
            no_improve += 1
            if no_improve >= patience: break
    model.load_state_dict(best_state)
    return model

# Manual CV for the transformer
kf = KFold(n_splits=5, shuffle=True, random_state=RNG)
r2s, rmses, maes = [], [], []
for fold, (tr, te) in enumerate(kf.split(X)):
    Xtr, Xte = X[tr], X[te]
    ytr, yte = y[tr], y[te]
    # Split tr into train/val
    Xtr2, Xva, ytr2, yva = train_test_split(Xtr, ytr, test_size=0.15, random_state=RNG)
    model = fit_transformer(Xtr2, ytr2, Xva, yva, n_features=X.shape[1])
    model.eval()
    with torch.no_grad():
        p = model(torch.tensor(Xte, dtype=torch.float32)).numpy()
    r2s.append(r2_score(yte, p))
    rmses.append(np.sqrt(mean_squared_error(yte, p)))
    maes.append(mean_absolute_error(yte, p))
r2s, rmses, maes = np.array(r2s), np.array(rmses), np.array(maes)
results.append(report("Tab Transformer (attn)", r2s, rmses, maes))

# ---------- Save results ----------
pd.DataFrame(results).to_csv('model_results.csv', index=False)
print("\nSaved: model_results.csv, construct_scores.csv")
