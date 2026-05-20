"""Feature-importance and compensation effect across model families."""
import warnings; warnings.filterwarnings("ignore")
import numpy as np, pandas as pd, json
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.inspection import permutation_importance
from sklearn.model_selection import KFold
from sklearn.metrics import r2_score
import xgboost as xgb
import torch
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

RNG = 42
np.random.seed(RNG)

scores = pd.read_csv('construct_scores.csv')
feature_cols = [
    'ConflictExp_WB','ConflictExp_All','Tangible_Costs','Intangible_Costs',
    'Intangible_Benefits','Prevention_Eff','Compensation_Anticipation','Policy_Support',
    'Compensation_Participation','Q4_Gender','Q5_Age','Q6_Education',
    'Q8_AnnualIncome','Q9_AgriProportion','Q11_TotalArea','Q13_TotalLivestock',
    'Q14_HouseholdAsset','Q3_InNP'
]
nice_names = {
    'ConflictExp_WB': 'Conflict experience (wild boar)',
    'ConflictExp_All': 'Conflict experience (all spp.)',
    'Tangible_Costs': 'Tangible costs',
    'Intangible_Costs': 'Intangible costs',
    'Intangible_Benefits': 'Intangible benefits',
    'Prevention_Eff': 'Prevention effectiveness',
    'Compensation_Anticipation': 'Compensation anticipation',
    'Policy_Support': 'Policy support',
    'Compensation_Participation': 'Compensation participation',
    'Q4_Gender': 'Gender (1=M)',
    'Q5_Age': 'Age',
    'Q6_Education': 'Education',
    'Q8_AnnualIncome': 'Annual income',
    'Q9_AgriProportion': 'Agriculture share of income',
    'Q11_TotalArea': 'Total cropland area',
    'Q13_TotalLivestock': 'Total livestock',
    'Q14_HouseholdAsset': 'Household assets',
    'Q3_InNP': 'Inside national park'
}
X = scores[feature_cols].copy()
y = scores['Tolerance'].values
to_scale = [c for c in feature_cols if c not in ['Compensation_Participation','Q4_Gender','Q3_InNP']]
X[to_scale] = (X[to_scale] - X[to_scale].mean())/X[to_scale].std(ddof=0)
X_np = X.values

# ---------- Fit on full data for importance/coefficients ----------
ols = LinearRegression().fit(X_np, y)
rf  = RandomForestRegressor(n_estimators=500, min_samples_leaf=5,
                            random_state=RNG, n_jobs=-1).fit(X_np, y)
xgbm = xgb.XGBRegressor(n_estimators=400, max_depth=4, learning_rate=0.05,
                       subsample=0.8, colsample_bytree=0.8, reg_lambda=1.0,
                       random_state=RNG, n_jobs=-1, verbosity=0).fit(X_np, y)

# OLS coefficients (standardised X, so coeffs ≈ standardised betas)
coef = pd.Series(ols.coef_, index=feature_cols, name='OLS_beta')
# Permutation importance (model-agnostic, computed on full data with shuffling)
pi_rf  = permutation_importance(rf,  X_np, y, n_repeats=30, random_state=RNG, n_jobs=-1)
pi_xgb = permutation_importance(xgbm, X_np, y, n_repeats=30, random_state=RNG, n_jobs=-1)

imp = pd.DataFrame({
    'Feature': [nice_names[c] for c in feature_cols],
    'OLS_beta': coef.values,
    'OLS_abs_beta': np.abs(coef.values),
    'RF_perm_imp': pi_rf.importances_mean,
    'XGB_perm_imp': pi_xgb.importances_mean,
}).sort_values('RF_perm_imp', ascending=False)
print("\nFeature importance summary:")
print(imp.round(4).to_string(index=False))
imp.to_csv('feature_importance.csv', index=False)

# ---------- Compensation effect: estimate ATE-like contrast across models ----------
# Strategy: for each model, predict tolerance with Compensation_Participation set to 0
# vs 1 for every respondent (counterfactual), and average the difference.
def avg_effect(model, X, var_idx):
    X0 = X.copy(); X0[:,var_idx] = 0
    X1 = X.copy(); X1[:,var_idx] = 1
    return float((model.predict(X1) - model.predict(X0)).mean())

cp_idx = feature_cols.index('Compensation_Participation')
# Fit baseline MLP and Transformer too, briefly
mlp = MLPRegressor(hidden_layer_sizes=(64,32), activation='relu', alpha=1e-3,
                   max_iter=2000, early_stopping=True, validation_fraction=0.15,
                   n_iter_no_change=30, random_state=RNG).fit(X_np, y)

# Tab Transformer (re-implement & retrain on full data)
import torch.nn as nn
class TabTransformer(nn.Module):
    def __init__(self, n_features, d_model=16, n_heads=2, dropout=0.2):
        super().__init__()
        self.proj = nn.Linear(1, d_model)
        self.feat_emb = nn.Parameter(torch.randn(n_features, d_model)*0.02)
        self.attn = nn.MultiheadAttention(d_model, n_heads, dropout=dropout, batch_first=True)
        self.ln1  = nn.LayerNorm(d_model)
        self.ff   = nn.Sequential(nn.Linear(d_model, d_model*2), nn.GELU(),
                                  nn.Dropout(dropout), nn.Linear(d_model*2, d_model))
        self.ln2  = nn.LayerNorm(d_model)
        self.head = nn.Sequential(nn.Flatten(),
                                  nn.Linear(n_features*d_model, 32), nn.GELU(),
                                  nn.Dropout(dropout), nn.Linear(32, 1))
    def forward(self, x):
        h = self.proj(x.unsqueeze(-1)) + self.feat_emb
        a, _ = self.attn(h, h, h, need_weights=False)
        h = self.ln1(h + a)
        h = self.ln2(h + self.ff(h))
        return self.head(h).squeeze(-1)

torch.manual_seed(RNG)
tt = TabTransformer(X_np.shape[1])
opt = torch.optim.AdamW(tt.parameters(), lr=1e-3, weight_decay=1e-3)
sch = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=300)
Xt = torch.tensor(X_np, dtype=torch.float32); yt = torch.tensor(y, dtype=torch.float32)
loss_fn = nn.MSELoss()
for ep in range(300):
    tt.train()
    idx = torch.randperm(len(Xt))
    for s in range(0,len(idx),64):
        b = idx[s:s+64]; opt.zero_grad()
        loss = loss_fn(tt(Xt[b]), yt[b]); loss.backward(); opt.step()
    sch.step()
tt.eval()

class TTWrap:
    def __init__(self, m): self.m = m
    def predict(self, X):
        with torch.no_grad():
            return self.m(torch.tensor(X, dtype=torch.float32)).numpy()

models = {'OLS': ols, 'RandomForest': rf, 'XGBoost': xgbm, 'MLP': mlp, 'TabTransformer': TTWrap(tt)}
ate_rows = []
for name, m in models.items():
    eff = avg_effect(m, X_np, cp_idx)
    # bootstrap CI
    rng = np.random.RandomState(RNG)
    boots = []
    n_boot = 100 if name in ('OLS','RandomForest','XGBoost') else 200
    for _ in range(n_boot):
        idx = rng.choice(len(X_np), len(X_np), replace=True)
        if name in ('MLP','TabTransformer'):
            # too slow to refit each bootstrap — use the same trained model and bootstrap on the contrast
            boots.append(avg_effect(m, X_np[idx], cp_idx))
        else:
            try:
                mb = type(m)(**(m.get_params() if hasattr(m,'get_params') else {}))
            except Exception:
                mb = None
            if mb is None or name=='OLS':
                # Refit cheap models
                if name=='OLS': mb = LinearRegression().fit(X_np[idx], y[idx])
                elif name=='RandomForest':
                    mb = RandomForestRegressor(n_estimators=150, min_samples_leaf=5,
                                               random_state=RNG, n_jobs=-1).fit(X_np[idx], y[idx])
                elif name=='XGBoost':
                    mb = xgb.XGBRegressor(n_estimators=150, max_depth=4, learning_rate=0.05,
                                          random_state=RNG, n_jobs=-1, verbosity=0).fit(X_np[idx], y[idx])
            else:
                mb.fit(X_np[idx], y[idx])
            boots.append(avg_effect(mb, X_np, cp_idx))
    boots = np.array(boots)
    ate_rows.append(dict(model=name, ate=eff, ci_lo=np.percentile(boots,2.5), ci_hi=np.percentile(boots,97.5)))
    print(f"  Avg effect of compensation participation on standardised Tolerance ({name}):"
          f" {eff:+.3f}  [95% CI {np.percentile(boots,2.5):+.3f}, {np.percentile(boots,97.5):+.3f}]")

pd.DataFrame(ate_rows).to_csv('compensation_effect.csv', index=False)

# ---------- Plots ----------
plt.rcParams.update({'font.size': 10})

# 1. Model comparison
res = pd.read_csv('model_results.csv')
fig, ax = plt.subplots(figsize=(7,3.5))
order = res.sort_values('r2_mean')
ax.barh(order['model'], order['r2_mean'],
        xerr=order['r2_sd'], color='#3a86ff', alpha=0.85,
        edgecolor='#1a4dbf')
ax.set_xlabel('5-fold CV R²  (mean ± SD)')
ax.set_title('Predictive performance: Tolerance ≈ f(WTM constructs + sociodemographics)')
ax.axvline(0, color='k', linewidth=0.5)
plt.tight_layout(); plt.savefig('fig_model_comparison.png', dpi=140); plt.close()

# 2. Feature importance (top 12)
top = imp.head(12).iloc[::-1]
fig, ax = plt.subplots(figsize=(7,4.5))
ax.barh(top['Feature'], top['RF_perm_imp'], color='#06a77d', alpha=0.85)
ax.set_xlabel('Permutation importance (Random Forest, ΔR²)')
ax.set_title('Which variables drive Tolerance? (RF permutation importance)')
plt.tight_layout(); plt.savefig('fig_feature_importance.png', dpi=140); plt.close()

# 3. OLS coefficients
fig, ax = plt.subplots(figsize=(7,4.5))
order_b = pd.Series(ols.coef_, index=[nice_names[c] for c in feature_cols]).sort_values()
colors = ['#d62828' if v<0 else '#06a77d' for v in order_b.values]
ax.barh(order_b.index, order_b.values, color=colors, alpha=0.85)
ax.axvline(0, color='k', linewidth=0.5)
ax.set_xlabel('Standardised OLS coefficient (β)')
ax.set_title('Direction & magnitude of effects on standardised Tolerance')
plt.tight_layout(); plt.savefig('fig_ols_coefs.png', dpi=140); plt.close()

# 4. Compensation effect
fig, ax = plt.subplots(figsize=(6.5,3.2))
eff_df = pd.DataFrame(ate_rows)
ax.errorbar(eff_df['ate'], eff_df['model'],
            xerr=[eff_df['ate']-eff_df['ci_lo'], eff_df['ci_hi']-eff_df['ate']],
            fmt='o', color='#1a4dbf', capsize=4)
ax.axvline(0, color='k', linewidth=0.5)
ax.set_xlabel('Counterfactual effect of Compensation Participation on Tolerance (SD units)')
ax.set_title('Compensation effect across model families (95% bootstrap CI)')
plt.tight_layout(); plt.savefig('fig_compensation_effect.png', dpi=140); plt.close()

print("\nPlots saved: fig_model_comparison.png, fig_feature_importance.png, fig_ols_coefs.png, fig_compensation_effect.png")
