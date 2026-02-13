<p align="center">
  <img src="./assets/avatar.png" width="440" alt="CruceEmas_CierreCond_TrailngStop avatar" />
</p>

<h1 align="center">CruceEmas_CierreCond_TrailngStop (MQL5 EA)</h1>

<p align="center">
  <b>Cruce EMA rápida/lenta • Confirmación por pendiente • SL/Trailing por ATR • 1 entrada por vela</b>
</p>

<p align="center">
  <img alt="Type" src="https://img.shields.io/badge/type-Expert%20Advisor-blue">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
  <img alt="Use" src="https://img.shields.io/badge/use-educational-orange">
</p>

---

## 🧠 Idea
**Cruce de EMA rápida/lenta + confirmación por pendiente + SL/Trailing por ATR + 1 entrada por vela**  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## ✅ Qué hace
- Calcula **EMA rápida** y **EMA lenta** (inputs `periodo_ema_rapida` y `periodo_ema_lenta`)
- Genera señales por **cruce de medias** con confirmación:
  - **Compra:** la rápida cruza por encima de la lenta **y** ambas pendientes > 0 (`cruce_compra`)
  - **Venta:** la rápida cruza por debajo de la lenta **y** ambas pendientes < 0 (`cruce_venta`)
- Aplica **SL inicial por ATR** (`SL_ATR_Mult`) respetando `SYMBOL_TRADE_STOPS_LEVEL`
- Aplica **Trailing Stop por ATR** (`Trail_ATR_Mult`) respetando `SYMBOL_TRADE_STOPS_LEVEL`
- Controla **1 operación por vela** (usa el tiempo de barra)

> Importante: **NO** hay cierre por señal contraria. La posición se cierra por **SL/Trailing** (o fin del test).

---

## 🚀 Instalación (MT5)
1) Copia este archivo:
`CruceEmas_CierreCond_TrailngStop.mq5`

a:
`MQL5/Experts/CruceEmas_CierreCond_TrailngStop/`

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
| EMAs | periodo_ema_rapida | periodo media rápida |
| EMAs | periodo_ema_lenta | periodo media lenta |

---

## 🧪 Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Activa **Every tick based on real ticks** si tu broker lo permite
- Revisa sensibilidad a **spread/slippage** y símbolos con **stops level** alto (impacta SL mínimo)

### Quick settings (punto de partida)
- `RiskPercent`: **1.0**
- `ATR_Period`: **14**
- `SL_ATR_Mult`: **1.50**
- `Trail_ATR_Mult`: **1.00**
- `periodo_ema_rapida`: **10**
- `periodo_ema_lenta`: **25**

> Estos valores son un punto de partida para investigación. Ajusta por símbolo/timeframe/spread.

---

## 🧩 Notas técnicas
- En optimización se evita dibujar objetos/estética para acelerar el tester.
- La lógica de 1 trade por vela se controla con el tiempo de la barra (robusto en Strategy Tester).
- El trailing usa un “armado” mínimo: solo empieza si el precio avanza al menos `step` desde el precio de apertura.

---

## 📚 Docs
- `./docs/strategy.md`
- `./docs/inputs.md`
- `./docs/backtest.md`

---

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
