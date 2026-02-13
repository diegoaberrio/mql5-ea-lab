<p align="center">
  <img src="./assets/avatar.png" width="440" alt="Cruce_BB avatar" />
</p>

<h1 align="center">Cruce_BB (MQL5 EA)</h1>

<p align="center">
  <b>Bollinger (media) • ADX • MACD • Stochastic • SL/Trailing por ATR • 1 entrada por vela</b>
</p>

<p align="center">
  <img alt="Type" src="https://img.shields.io/badge/type-Expert%20Advisor-blue">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
  <img alt="Use" src="https://img.shields.io/badge/use-educational-orange">
</p>

---

## 🧠 Idea
**Bollinger (media) + filtros ADX/MACD/Stochastic + confirmación por cruce/cierre + SL/Trailing por ATR + 1 entrada por vela**  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## ✅ Qué hace
- Calcula **Bollinger Bands** y usa la **media** como referencia (`periodo_ema_bb`, `desv_bb`)
- Filtra fuerza/dirección con **ADX / +DI / -DI** (`periodo_adx`)
- Confirma momentum con **MACD** (`periodo_rapida`, `periodo_lenta`, `periodo_signal`)
- Confirma dirección reciente con **Stochastic %K** (`periodo_k`, `periodo_d`, `ralentizacion`)
- Aplica **SL por ATR** (`SL_ATR_Mult`) y **Trailing por ATR** (`Trail_ATR_Mult`)
- Controla **1 operación por vela** (usa el tiempo de barra)
- **No cierra por señal contraria**: la salida es por SL / trailing

---

## 🚀 Instalación (MT5)
1) Copia este archivo:  
`Cruce_BB.mq5`

a:  
`MQL5/Experts/Cruce_BB/`

2) Abre MetaEditor → compila  
3) MT5 → Strategy Tester → selecciona el EA

---

## ⚙️ Inputs clave
| Grupo | Input | Descripción |
|------|------|-------------|
| Riesgo | UseRiskPercent | true: lotaje por % de equity |
| Riesgo | RiskPercent | % de equity a arriesgar |
| Riesgo | FixedLots | lotes fijos si UseRiskPercent=false |
| ATR | ATR_Period | periodo ATR |
| ATR | SL_ATR_Mult | SL = ATR * mult |
| ATR | Trail_ATR_Mult | trailing step = ATR * mult |
| Bollinger | periodo_ema_bb | periodo de la media de BB |
| Bollinger | desv_bb | desviación estándar de BB |
| ADX | periodo_adx | periodo ADX |
| MACD | periodo_rapida / lenta / signal | parámetros MACD |
| Stoch | periodo_k / periodo_d / ralentizacion | parámetros Stochastic |

---

## 🧪 Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Activa **Every tick based on real ticks** si tu broker lo permite
- Revisa sensibilidad a **spread/slippage** y sesiones (Londres/NY)
- Prueba símbolos con spreads distintos (majors vs crosses)

### Quick settings (punto de partida)
- `RiskPercent`: **1.0**
- `ATR_Period`: **14**
- `SL_ATR_Mult`: **1.50**
- `Trail_ATR_Mult`: **1.00**
- `periodo_ema_bb`: **20**
- `desv_bb`: **2.0**
- `periodo_adx`: **14**

> Punto de partida para investigación. Ajusta por símbolo/timeframe/spread.

---

## 🧩 Notas técnicas
- En optimización se evita el HUD/estética para acelerar el Strategy Tester.
- La entrada usa `no_posicion = !PositionSelect(_Symbol)` para ser más robusto que por ticket.

---

## 📚 Docs
- `./docs/strategy.md`
- `./docs/inputs.md`
- `./docs/backtest.md`

---

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
