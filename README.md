<p align="center">
  <img src="./avatar_raiz.png" width="440" alt="mql5-ea-lab avatar" />
</p>

<h1 align="center">mql5-ea-lab 🤖</h1>

<p align="center">
  <b>Expert Advisors e indicadores en MQL5 (MetaTrader 5)</b><br/>
  Research • Arquitectura limpia • Gestión de riesgo • Utilidades reutilizables
</p>

<p align="center">
  <a href="./LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-2ea44f"></a>
  <a href="./DISCLAIMER.md"><img alt="Disclaimer" src="https://img.shields.io/badge/disclaimer-educational-orange"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-MetaTrader%205-blue">
  <img alt="Language" src="https://img.shields.io/badge/language-MQL5-informational">
</p>

---

## ⚠️ Aviso importante

Este repositorio es **educativo y de investigación**.  
No constituye asesoramiento financiero ni garantiza resultados. Lee **`DISCLAIMER.md`** antes de usar cualquier código.

---

## 📦 EAs incluidos

### 1) SopRec_CierreCruce_TrStp

**Idea:** Soporte/Resistencia + filtro SMA + SL/Trailing por ATR + 1 entrada por vela  
📁 Carpeta: `Experts/SopRec_CierreCruce_TrStp/`  
🔗 README: `Experts/SopRec_CierreCruce_TrStp/README.md`

---

### 2) Fibo_CruceCierre_TrailingStop

**Idea:** Fibonacci (0/50/100) + confirmación por vela + SL/Trailing por ATR + 1 entrada por vela  
📁 Carpeta: `Experts/Fibo_CruceCierre_TrailingStop/`  
🔗 README: `Experts/Fibo_CruceCierre_TrailingStop/README.md`

---

### 3) PrecioEma_CierreCruce_TrailingStop

**Idea:** Precio vs EMA (SMA) + cruces + SL/Trailing por ATR + 1 entrada por vela  
📁 Carpeta: `Experts/PrecioEma_CierreCruce_TrailingStop/`  
🔗 README: `Experts/PrecioEma_CierreCruce_TrailingStop/README.md`

---

### 4) CruceEmas_CierreCond_TrailngStop

**Idea:** Cruce EMA rápida/lenta + confirmación por pendiente + SL/Trailing por ATR + 1 entrada por vela
📁 Carpeta: `Experts/CruceEmas_CierreCond_TrailngStop/`
🔗 README: `Experts/CruceEmas_CierreCond_TrailngStop/README.md`

---

### 5) Cruce_BB

**Idea:** Bollinger (media) + ADX + MACD + Stochastic + confirmación por cruce/cierre + SL/Trailing por ATR + 1 entrada por vela  
 Carpeta: `Experts/Cruce_BB/`a
📁 Carpeta: `Experts/Cruce_BB/`
🔗 README: `Experts/Cruce_BB/README.md`

---

## 🚀 Quick Start (MT5 local)

1. Copia los `.mq5` a tu terminal:
   `MQL5/Experts/`

2. Abre **MetaEditor** → compila

3. Abre **Strategy Tester** y prueba en **demo** primero  
   (Sugerencia: empieza por **H1** y luego compara con M30/H4)

---

## 🧪 Estándar de pruebas (recomendado)

- Sensibilidad a **spread** y **slippage**
- Diferentes **sesiones** (London / NY)
- Símbolos con spreads distintos
- Backtest en rangos de fechas diferentes (mercado tendencial vs lateral)

---

## 📝 Licencia

MIT — ver `LICENSE`
