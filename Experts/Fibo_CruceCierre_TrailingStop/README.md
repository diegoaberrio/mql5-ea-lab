<p align="center">
  <img src="./assets/avatar.png" width="440" alt="Fibo_CruceCierre_TrailingStop avatar" />
</p>

<h1 align="center">Fibo_CruceCierre_TrailingStop (MQL5 EA)</h1>

<p align="center">
  <b>Fibonacci 0/50/100 • Confirmación por vela • SL/Trailing por ATR • 1 entrada por vela</b>
</p>

<p align="center">
  <img alt="Type" src="https://img.shields.io/badge/type-Expert%20Advisor-blue">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
  <img alt="Use" src="https://img.shields.io/badge/use-educational-orange">
</p>

---

## 🧠 Idea
**Fibonacci (0/50/100) + confirmación por vela (cruce/cierre) + SL/Trailing por ATR + 1 entrada por vela**  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## ✅ Qué hace
- Calcula niveles **Fibo 0% / 50% / 100%** usando el **mínimo y máximo** de una ventana (`NumeroVelasFibo`)
- Genera señales con lógica de vela + relación con niveles (`cruce_compra` / `cruce_venta`)
- Dibuja el objeto **Fibonacci** en el gráfico (**solo en modo normal**, no optimización)
- Aplica **SL por ATR** (`SL_ATR_Mult`) y **Trailing por ATR** (`Trail_ATR_Mult`)
- Controla **1 operación por vela** (usa el tiempo de barra)

---

## 🚀 Instalación (MT5)
1) Copia este archivo:
`Fibo_CruceCierre_TrailingStop.mq5`

a:
`MQL5/Experts/Fibo_CruceCierre_TrailingStop/`

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
| ATR | SL_ATR_Mult | SL = ATR * mult |
| ATR | Trail_ATR_Mult | trailing step = ATR * mult |
| Fibo | NumeroVelasFibo | ventana para max/min (anclas Fibonacci) |

---

## 🧪 Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Activa **Every tick based on real ticks** si tu broker lo permite
- Revisa sensibilidad a **spread/slippage**, sesiones y símbolos con spreads distintos

### Quick settings (punto de partida)
- `RiskPercent`: **1.0**
- `ATR_Period`: **14**
- `SL_ATR_Mult`: **1.50**
- `Trail_ATR_Mult`: **1.00**
- `NumeroVelasFibo`: **100**

> Estos valores son un punto de partida para investigación. Ajusta por símbolo/timeframe/spread.

---

## 🧩 Notas técnicas
- En optimización se evita dibujar objetos/estética para acelerar el tester.
- La lógica de 1 trade por vela se controla con el tiempo de la barra (robusto en Strategy Tester).

---

## 📚 Docs
- `./docs/strategy.md`
- `./docs/inputs.md`
- `./docs/backtest.md`

---

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
