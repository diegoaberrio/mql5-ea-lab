<p align="center">
  <img src="./assets/avatar.png" width="440" alt="3EMAS_CruceCierre_TrailingStop avatar" />
</p>

<h1 align="center">3EMAS_CruceCierre_TrailingStop (MQL5 EA)</h1>

<p align="center">
  <b>3 EMAs (R/M/L) • Confirmación por cierre • SL/Trailing por ATR • 1 entrada por vela</b>
</p>

<p align="center">
  <img alt="Type" src="https://img.shields.io/badge/type-Expert%20Advisor-blue">
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-1f6feb">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
  <img alt="Use" src="https://img.shields.io/badge/use-educational-orange">
</p>

---

## 🧠 Idea
**3 EMAs (rápida/media/lenta) + confirmación por cierre + SL/Trailing por ATR + 1 entrada por vela**  
**Enfoque:** research / educativo (sin promesas de rentabilidad)  
**Autor:** Diego — diegoincode

---

## ✅ Qué hace
- Calcula 3 medias (SMA en tu implementación) con períodos:
  - `periodo_ema_rapida`, `periodo_ema_media`, `periodo_ema_lenta`
- Filtra tendencia con la **pendiente** de cada media (todas > 0 para compra / todas < 0 para venta)
- Exige confirmación por **cierre** respecto a las EMAs:
  - Compra: `Close[1]` por encima de R/M/L
  - Venta:  `Close[1]` por debajo de R/M/L
- Aplica **SL por ATR** (`SL_ATR_Mult`) + respeta **stops level** del símbolo
- Aplica **Trailing Stop por ATR** (`Trail_ATR_Mult`) con distancia mínima por stops level
- Controla **1 operación por vela** (con `iTime` y `gLastBarTime`)
- No cierra por señal contraria: el cierre es por **SL / trailing**

---

## 🚀 Instalación (MT5)
1) Copia este archivo:
`3EMAS_CruceCierre_TrailingStop.mq5`

a:
`MQL5/Experts/3EMAS_CruceCierre_TrailingStop/`

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
| ATR | SL_ATR_Mult | SL inicial = ATR * mult (respeta stops level) |
| ATR | Trail_ATR_Mult | trailing step = ATR * mult (respeta stops level) |
| EMAs | periodo_ema_rapida | periodo media rápida (SMA) |
| EMAs | periodo_ema_media | periodo media media (SMA) |
| EMAs | periodo_ema_lenta | periodo media lenta (SMA) |

---

## 🧪 Cómo probar (recomendado)
- Timeframe sugerido: empieza por **H1** (luego compara con M30/H4)
- Si tu broker lo permite, usa **Every tick based on real ticks**
- Revisa sensibilidad a **spread/slippage** y símbolos con distintos costes

### Quick settings (punto de partida)
- `RiskPercent`: **1.0**
- `ATR_Period`: **14**
- `SL_ATR_Mult`: **1.50**
- `Trail_ATR_Mult`: **1.00**
- `periodo_ema_rapida`: **10**
- `periodo_ema_media`: **50**
- `periodo_ema_lenta`: **200**

> Estos valores son un punto de partida para investigación. Ajusta por símbolo/timeframe/spread.

---

## 🧩 Notas técnicas
- En optimización se evita dibujar objetos/estética para acelerar el tester.
- La lógica de “un trade por vela” se controla con el tiempo de la barra (robusto en Strategy Tester).
- Ojo: en este EA, los nombres `is_going_down` / `is_going_up` vienen de tu base y están “invertidos” semánticamente, pero se mantienen para respetar tu lógica original.

---

## Disclaimer
Este EA es educativo. No es asesoramiento financiero.  
Ver `../../DISCLAIMER.md`
