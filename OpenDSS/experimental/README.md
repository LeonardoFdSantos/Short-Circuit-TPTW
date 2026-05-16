# Experimental: Explicit Ze Modeling in OpenDSS

## What was attempted

Tried to explicitly model the equalization impedance Ze in OpenDSS to eliminate the 20% discrepancy in AC/BC (phase-to-ground) faults between the analytical model and OpenDSS.

Two approaches were tested:
1. **Reactor between ground nodes** (`Reactor.ZE bus1=BARRAT2F.3 bus2=FALTA.3`) — had no effect because the fault path goes to node `.0` (global ground), not through `.3`.
2. **3-phase line with phase 3 as ground conductor** (matrix 3×3, fault from phase 1 to phase 3) — made the error worse (30%) because it adds Ze on top of what Carson already embeds.

## Why it doesn't work

Carson's equations already include the earth return impedance in the self and mutual impedances (Zp, Zm). The `ΔZ` correction terms in Carson account for the current returning through the earth. Adding Ze explicitly is **double-counting** the earth return path.

The 20% discrepancy is inherent to the difference in modeling philosophy:
- **Analytical model**: treats phase C (ground) as a separate lumped path with `Re = real(Zp-2Zm)*d - Rti - Rtc`
- **OpenDSS**: earth return is distributed implicitly via Carson's corrections in the 2×2 impedance matrix

## Conclusion

The two models provide **formal bounds** for phase-to-ground fault current:
- Upper bound (OpenDSS, without Re): higher current
- Lower bound (analytical, with Re): lower current, conservative for protection

This is not a bug — it's a valid physical interpretation documented in the paper.

## Files

- `T2F_ComZe.dss` — 3-phase OpenDSS model (approach 2)
- `ValidacaoZe.m` — Validation script comparing with/without Ze
- `validacao_ze.csv` — Results (end-of-line, all fault types)
- `validacao_ze_comprimento.csv` — Results (AC fault vs length)
