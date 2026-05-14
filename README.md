# Short-Circuit Analysis for Two-Phase Two-Wire (TPTW) Distribution Systems

Analytical short-circuit model for rural three-phase two-wire (T2F/TPTW) distribution networks, where the ground acts as the third conductor (phase C).

## Repository Structure

```
Short-Circuit-TPTW/
├── run_all.m                     # Master script - runs everything
├── calcImpedanciasCarson.m       # Carson's equations (impedance calculation)
├── calcCurtoT2F.m                # Short-circuit currents (mesh/KVL method)
├── defineFaltaT2F.m              # Fault resistance definitions (ABC, AB, AC, BC)
├── CurtoCircuitoFim.m            # Analytical equations (end-of-line fault)
├── CurtoCircuitoMeioLinha.m      # Analytical equations (mid-line fault)
├── AnaliseSensibilidade.m        # Sensitivity analysis + elasticity index
├── IEEE13_T2F_Substituicao.m     # IEEE 13-bus: TPTW vs Three-phase vs SWER
├── TesteArtigo1.m                # Main validation script (Simulink + analytical)
├── gerar_figuras_validacao.py    # Python script to generate error figures
├── OpenDSS/
│   ├── T2F_Base.dss             # OpenDSS model of TPTW system
│   ├── ValidacaoOpenDSS.m       # OpenDSS validation script
│   ├── validacao_comprimento.csv
│   ├── validacao_posicao.csv
│   ├── validacao_fim_linha.csv
│   └── validacao_resistividade.csv
├── img/
│   ├── Imagem10.png             # Relative error: end-of-line faults
│   └── Imagem11.png             # Relative error: ABC fault vs position
├── valores_resultados_fim_linha_sem_compensacao.csv
├── valores_resultados_meio_linha_sem_compensacao.csv
├── valores_resultados_fim_linha_com_compensacao_Artigo.csv
├── valores_resultados_meio_linha_com_compensacao_Artigo.csv
├── valores_resultados_simulacao_fim_linha_com_comp_Artigo.csv
├── valores_resultados_simulacao_meio_linha_com_comp_Artigo.csv
├── sensibilidade_*.csv           # Sensitivity analysis results
└── IEEE13_substituicao_resultados.csv
```

## System Parameters

| Parameter | Value | Unit |
|-----------|-------|------|
| Voltage | 13.8 | kV |
| Frequency | 60 | Hz |
| Conductor | 2 AWG | - |
| AC Resistance | 1.102 | Ω/km |
| GMR | 0.00308 | m |
| Spacing (dij) | 1.60 | m |
| Height | 10.372 | m |
| Soil resistivity | 100 | Ω·m |
| Line length | 60 | km |
| Source SCC | 120 | MVA |
| X/R ratio | 7 | - |
| Transformer | 300 kVA, Z=1.91% | - |

## How to Run

### Run Everything (recommended)
```matlab
cd Short-Circuit-TPTW
run_all
```
This single script executes all analyses in sequence:
1. Parametric sensitivity analysis (pure MATLAB)
2. IEEE 13-bus comparison: TPTW vs Three-phase vs SWER (pure MATLAB)
3. Validation figures from pre-computed Simulink data (Python)
4. OpenDSS validation (skipped automatically if OpenDSS is not installed)

All output figures are saved to `img/` and CSV results to the root directory.

### Individual Scripts
```matlab
cd Short-Circuit-TPTW
AnaliseSensibilidade          % Sensitivity analysis only
IEEE13_T2F_Substituicao       % IEEE 13-bus comparison only
```

### OpenDSS Validation (requires OpenDSS installed)
```matlab
cd Short-Circuit-TPTW/OpenDSS
ValidacaoOpenDSS
```

### Python (generate error figures from CSV data)
```bash
cd Short-Circuit-TPTW
python gerar_figuras_validacao.py
```

## Validation Results

- **Simulink vs Analytical (no compensation):** max error 0.055% (ABC fault)
- **OpenDSS vs Analytical:** mean error 2.03%, max 8.08% (AB fault due to transformer coupling)
- **OpenDSS AC/BC faults:** ~20% error attributed to Ze not modeled in OpenDSS

## Key Findings

1. Ground acts as phase C → minimum fault is two-phase (not single-phase)
2. Symmetrical components do NOT decouple (|Z01|/|Z11| = 56% at 60 km)
3. TPTW-AC fault current equals SWER fault current (analytically confirmed)
4. Maximum protection reach formula: `d_max = (V_phase/I_pk - Z0) / Z_eff`

## Fault Types

| Type | Raf | Rbf | Rcf | Description |
|------|-----|-----|-----|-------------|
| ABC | ~0 | ~0 | 40 Ω | Three-phase |
| AB | 20 Ω | 20 Ω | open | Phase-to-phase |
| AC | ~0 | open | 40 Ω | Phase A to ground |
| BC | open | ~0 | 40 Ω | Phase B to ground |

## Citation

If you use this code, please cite the associated paper (IEEE Transactions on Power Delivery, submitted).

## License

MIT
