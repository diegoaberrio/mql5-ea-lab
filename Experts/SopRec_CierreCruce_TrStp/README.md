# SopRec_CierreCruce_TrStp (MQL5 EA)

<p align="center">
  <img src="./avatar.png" width="440" alt="mql5-ea-lab avatar" />
</p>

**Idea:** Soporte/Resistencia + filtro SMA + SL/Trailing por ATR + 1 entrada por vela  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## Qué hace
- Calcula **Resistencia** (máximo) y **Soporte** (mínimo) en una ventana de velas (`NumeroVelasCalculo`)
- Filtra tendencia con **SMA** (`periodo_ema`)
- Genera señal por patrón de vela + relación con S/R (`cruce_compra` / `cruce_venta`)
- Aplica **SL por ATR** (`SL_ATR_Mult`) y **trailing por ATR** (`Trail_ATR_Mult`)
- Controla **1 operación por vela** (usa el tiempo de barra)

## Instalación (MT5)
1) Copia este archivo:
`SopRec_CierreCruce_TrStp.mq5`

a:
`MQL5/Experts/SopRec_CierreCruce_TrStp/`

2) Abre MetaEditor → compila  
3) MT5 → Strategy Tester → selecciona el EA

## Inputs clave
| Grupo | Input | Descripción |
|------|------|-------------|
| Riesgo | UseRiskPercent | true: calcula lotaje por % de equity |
| Riesgo | RiskPercent | % de equity a arriesgar |
| Riesgo | FixedLots | lotes fijos si UseRiskPercent=false |
| ATR | ATR_Period | periodo ATR |
| ATR | SL_ATR_Mult | SL = ATR * mult |
| ATR | Trail_ATR_Mult | trailing step = ATR * mult |
| Tendencia | periodo_ema | periodo SMA (nombre histórico) |
| S/R | NumeroVelasCalculo | ventana para soporte/resistencia |

## Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Activa **Every tick based on real ticks** si tu broker lo permite
- Revisa sensibilidad a spread/slippage y horarios

Docs:
- `./docs/strategy.md`
- `./docs/inputs.md`
- `./docs/backtest.md`

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
