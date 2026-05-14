import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.rcParams['font.family'] = 'serif'
matplotlib.rcParams['font.size'] = 9
matplotlib.rcParams['axes.labelsize'] = 10
matplotlib.rcParams['legend.fontsize'] = 8

# --- Figure 10: Relative error end-of-line fault (no compensation) ---
df_fim = pd.read_csv('valores_resultados_fim_linha_sem_compensacao.csv')

fault_types = ['ABC', 'AC', 'BC', 'AB']
phases = ['IA', 'IB', 'IC']
phase_labels = ['Phase A', 'Phase B', 'Phase C']

fig, axes = plt.subplots(2, 2, figsize=(7, 5))
axes = axes.flatten()

for idx, (type_idx, type_name) in enumerate(zip([1, 2, 3, 4], fault_types)):
    ax = axes[idx]
    row = df_fim[df_fim['tipoCurto'] == type_idx].iloc[0]

    errors = []
    valid = []
    for phase in phases:
        sim_val = row[f'{phase}_Sim']
        calc_val = row[f'{phase}_Calc']
        if sim_val > 1 and calc_val > 1:
            error = abs(sim_val - calc_val) / calc_val * 100
            errors.append(error)
            valid.append(True)
        else:
            errors.append(0)
            valid.append(False)

    colors = ['#1f77b4', '#ff7f0e', '#2ca02c']
    bars = ax.bar(phase_labels, errors, color=colors, width=0.5, edgecolor='black', linewidth=0.5)

    for i, (bar, v) in enumerate(zip(bars, valid)):
        if not v:
            bar.set_color('#cccccc')
            bar.set_edgecolor('#999999')
            ax.text(bar.get_x() + bar.get_width()/2, 0.0001,
                    'open', ha='center', va='bottom', fontsize=6, color='gray')

    ax.set_title(f'Fault {type_name}', fontweight='bold')
    ax.set_ylabel('Relative error (%)')
    max_err = max(e for e in errors if e > 0) if any(e > 0 for e in errors) else 0.01
    ax.set_ylim(0, max_err * 1.5)
    ax.grid(axis='y', alpha=0.3)

    for bar, error, v in zip(bars, errors, valid):
        if v and error > 0.0001:
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height(),
                    f'{error:.4f}%', ha='center', va='bottom', fontsize=7)

plt.tight_layout()
plt.savefig('img/Imagem10.png', dpi=300, bbox_inches='tight')
plt.close()
print('Imagem10.png generated.')

# --- Figure 11: Relative error ABC internal fault by position (no compensation) ---
df_meio = pd.read_csv('valores_resultados_meio_linha_sem_compensacao.csv')

df_abc = df_meio[df_meio['tipoCurto'] == 1].copy()
df_abc['pos'] = df_abc['n'] * 100

errors_a = abs(df_abc['IA_Sim'] - df_abc['IA_Calc']) / df_abc['IA_Calc'] * 100
errors_b = abs(df_abc['IB_Sim'] - df_abc['IB_Calc']) / df_abc['IB_Calc'] * 100
errors_c = abs(df_abc['IC_Sim'] - df_abc['IC_Calc']) / df_abc['IC_Calc'] * 100

fig, ax = plt.subplots(figsize=(7, 3.5))
ax.plot(df_abc['pos'], errors_a, '-o', markersize=4, label='Phase A', color='#1f77b4')
ax.plot(df_abc['pos'], errors_b, '-s', markersize=4, label='Phase B', color='#ff7f0e')
ax.plot(df_abc['pos'], errors_c, '-^', markersize=4, label='Phase C', color='#2ca02c')

ax.set_xlabel('Fault position (% of line length)')
ax.set_ylabel('Relative error (%)')
ax.set_title('Relative error: analytical model vs Simulink (internal ABC fault)', fontweight='bold')
ax.legend(loc='upper right')
ax.grid(True, alpha=0.3)
ax.set_xlim(0, 100)

plt.tight_layout()
plt.savefig('img/Imagem11.png', dpi=300, bbox_inches='tight')
plt.close()
print('Imagem11.png generated.')
