<p align="center">
  <img src="./assets/avatar.png" width="440" alt="PrecioEma_CierreCruce_TrailingStop avatar" />
</p>

<h1 align="center">PrecioEma_CierreCruce_TrailingStop (MQL5 EA)</h1>

<p align="center">
  <b>Precio vs EMA (SMA) • Cruce/Cierre • SL/Trailing por ATR • 1 entrada por vela</b>
</p>

<p align="center">
  <img alt="Type" src="https://img.shields.io/badge/type-Expert%20Advisor-blue">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
  <img alt="Use" src="https://img.shields.io/badge/use-educational-orange">
</p>

---

## 🧠 Idea
**Cruce precio/EMA (SMA) + filtro de pendiente + SL inicial por ATR + trailing por ATR + 1 entrada por vela**  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## ✅ Qué hace
- Calcula una **SMA** (input histórico `periodo_ema`) y la usa como referencia de tendencia
- Señales por cruce (con confirmación):
  - **Compra:** `Close[2] < EMA[2]` y `Close[1] > EMA[1]` y `EMA[1] > EMA[2]`
  - **Venta:**  `Close[2] > EMA[2]` y `Close[1] < EMA[1]` y `EMA[1] < EMA[2]`
- Aplica **SL inicial** basado en ATR (`SL_ATR_Mult`) respetando **stops level** del broker
- Aplica **Trailing Stop** por ATR (`Trail_ATR_Mult`) respetando **stops level**
- Controla **1 operación por vela** (con `iTime`)

> Importante: **NO** hay cierre por señal contraria. La posición se cierra por **SL/Trailing** (o fin de test).

---

## 🚀 Instalación (MT5)
1) Copia este archivo:
`PrecioEma_CierreCruce_TrailingStop.mq5`

a:
`MQL5/Experts/PrecioEma_CierreCruce_TrailingStop/`

2) Abre MetaEditor → compila  
3) MT5 → Strategy Tester → selecciona el EA

---

## ⚙️ Inputs clave
| Grupo | Input | Descripción |
|------|------|-------------|
| Riesgo | UseRiskPercent | true: calcula lotaje por % de equity |
| Riesgo | RiskPercent | % de equity a arriesgar |
| Riesgo | FixedLots | lotes fijos si UseRiskPercent=false |
| ATR | ATR_Period | periodo ATR |
| ATR | SL_ATR_Mult | SL inicial = ATR * mult (con stops level) |
| ATR | Trail_ATR_Mult | trailing step = ATR * mult (con stops level) |
| Tendencia | periodo_ema | periodo SMA (nombre histórico) |

---

## 🧪 Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Activa **Every tick based on real ticks** si tu broker lo permite
- Ojo con símbolos con **stops level** alto (afecta el SL mínimo permitido)
- Revisa sensibilidad a **spread/slippage** y sesiones (London/NY)

### Quick settings (punto de partida)
- `RiskPercent`: **1.0**
- `ATR_Period`: **14**
- `SL_ATR_Mult`: **1.50**
- `Trail_ATR_Mult`: **1.00**
- `periodo_ema`: **50**

> Estos valores son un punto de partida para investigación. Ajusta por símbolo/timeframe/spread.

---

## 🧩 Notas técnicas
- En modo normal dibuja HUD y añade la SMA al gráfico (`ChartIndicatorAdd`).
- En optimización se evita estética para acelerar el Strategy Tester.
- La lógica de “1 trade por vela” se controla por **tiempo de barra** (robusto en tester).

---

## 📚 Docs
- `./docs/strategy.md`
- `./docs/inputs.md`
- `./docs/backtest.md`

---

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
