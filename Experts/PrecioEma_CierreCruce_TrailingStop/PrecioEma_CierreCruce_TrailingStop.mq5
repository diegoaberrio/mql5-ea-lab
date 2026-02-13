//+------------------------------------------------------------------+
//|                   PrecioEma_CierreCruce_TrailingStop.mq5         |
//|                (rev) Diego x diegoincode – Sep 2025              |
//+------------------------------------------------------------------+
#property copyright "Diego + diegoincode"
#property link      "https://www.mql5.com"
#property version   "1.18"

#include <Trade/Trade.mqh>
CTrade trade;
ulong  trade_ticket = 0;

#define BUFFLEN 3   // mismo tamaño usado por tu lógica

//========================= INPUTS (SIMPLIFICADOS) ===================
// Gestión de riesgo
input bool   UseRiskPercent   = true;   // true: % de equity; false: lotes fijos
input double RiskPercent      = 1.0;    // % por operación
input double FixedLots        = 0.10;   // si UseRiskPercent=false

// Stops por ATR
input int    ATR_Period       = 14;     // Periodo ATR
input double SL_ATR_Mult      = 1.50;   // SL inicial = ATR * mult
input double Trail_ATR_Mult   = 1.00;   // Trailing step = ATR * mult

// Indicador (tu base)
input int    periodo_ema      = 50;     // SMA

//========================= ESTADO / ARRAYS ==========================
bool     time_flag     = true;          // 1 trade por vela
bool     gOptimizing   = false;         // sin HUD en optimización
datetime gLastBarTime  = 0;

int      EMA_handle    = INVALID_HANDLE;
int      ATR_handle    = INVALID_HANDLE;

double   EMA[];
double   ATR[];
double   High[], Open[], Close[], Low[];

// --- helper para etiquetas (reutilizable) -------------------------
void MakeLabel(const string name,
               const string text,
               int x, int y,
               color col,
               int fontsize,
               const string font,
               ENUM_BASE_CORNER corner = CORNER_RIGHT_UPPER,
               ENUM_ANCHOR_POINT anchor = ANCHOR_RIGHT_UPPER)
{
   if(ObjectFind(0,name) != -1) ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,   corner);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,   anchor);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontsize);
   ObjectSetString (0,name,OBJPROP_FONT,font);
   ObjectSetString (0,name,OBJPROP_TEXT,text);
}

//========================= LOOK & FEEL (solo en modo normal) ========
void SetupChartBeauty()
{
   // Estética base
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, 0, clrBlack);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, 0, clrSilver);
   ChartSetInteger(0, CHART_COLOR_GRID,       0, clrNONE);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL,0, clrLime);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR,0, clrTomato);
   ChartSetInteger(0, CHART_SHOW_OHLC,        0, true);
   ChartSetInteger(0, CHART_SHOW_GRID,        0, false);
   ChartSetInteger(0, CHART_SHOW_BID_LINE,    0, true);
   ChartSetInteger(0, CHART_SHOW_ASK_LINE,    0, true);

   // HUD arriba-derecha con más espacio
   string tf = EnumToString((ENUM_TIMEFRAMES)Period());
   string font_title = "Segoe UI Emoji";   // para mostrar 🤖/iconos
   string font_text  = "Segoe UI Emoji";

   int x           = 12;     // margen derecho
   int y           = 12;     // margen superior
   int line_h      = 18;     // alto de línea
   int gap_title   = 6;      // espacio título → subtítulo
   int gap_blocks  = 14;     // espacio subtítulo → redes

   // Título + subtítulo
   MakeLabel("HUD_Title", "🤖 PrecioEMA TS (ATR) ", x, y, clrGold, 12, font_title);
   y += line_h + gap_title;
   MakeLabel("HUD_SymTF", _Symbol + " " + tf,            x, y, clrSilver,10, font_text);

   // Espacio extra y redes
   y += gap_blocks;
   MakeLabel("HUD_YT", "📺 YouTube → @diegoincode",                       x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_TT", "🎬 TikTok → @diegoincode",                        x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_IG", "📸 Instagram → @diegoincode",                     x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_X",  "💬 X → @eldie10berrio",                           x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_LI", "💼 LinkedIn → /in/diego-alonso-berrío-gómez",     x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_GH", "💻 GitHub → github.com/diegoaberrio",             x, y+=line_h, clrSilver,10, font_text);
}

//========================= HELPERS SL/TRAIL =========================
double StopsLevelPoints()
{
   return (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
}

double InitialSLDistance() // ATR y stops level
{
   double d_atr  = (ArraySize(ATR)>1 ? SL_ATR_Mult * ATR[1] : 0.0);
   double d_slvl = (StopsLevelPoints()+1) * _Point; // +1 punto por seguridad
   return MathMax(d_atr, d_slvl);
}

//========================= TRAILING STOP (ATR) ======================
void trailing_stop_per_ticket(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;
   if(ArraySize(ATR)<2) return;

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double open   = PositionGetDouble(POSITION_PRICE_OPEN);
   double cur_sl = NormalizeDouble(PositionGetDouble(POSITION_SL), _Digits);

   const double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
   const double ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);

   double step = Trail_ATR_Mult * ATR[1];
   double minD = (StopsLevelPoints()+1) * _Point;

   if(type == POSITION_TYPE_BUY)
   {
      if(bid <= open + step) return; // arma trailing solo si avanzó >= step
      double new_sl = NormalizeDouble(bid - MathMax(step,minD), _Digits);
      if(new_sl > cur_sl && new_sl < bid)
         trade.PositionModify(ticket, new_sl, 0.0);
   }
   else if(type == POSITION_TYPE_SELL)
   {
      if(ask >= open - step) return;
      double new_sl = NormalizeDouble(ask + MathMax(step,minD), _Digits);
      if( (cur_sl==0.0 || new_sl < cur_sl) && new_sl > ask )
         trade.PositionModify(ticket, new_sl, 0.0);
   }
}

void trailing_stop_all()
{
   for(int i=0;i<PositionsTotal();i++)
      trailing_stop_per_ticket(PositionGetTicket(i));
}

//========================= RIESGO / MARGEN ==========================
double NormalizeLotsToStep(double lots)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step<=0) step=0.01;
   lots = MathFloor(lots/step)*step;
   lots = MathMax(minv, MathMin(maxv, lots));
   return lots;
}

double MaxLotsByMargin(ENUM_ORDER_TYPE type, double price)
{
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step<=0) step=0.01;

   double lo=minv, hi=maxv, best=0.0;
   for(int k=0;k<24;k++)
   {
      double mid = NormalizeLotsToStep((lo+hi)*0.5);
      if(mid<minv) { lo=minv; mid=minv; }
      double margin=0.0;
      if(!OrderCalcMargin(type,_Symbol,mid,price,margin)) { hi=mid; continue; }
      if(margin>0 && margin <= free*0.95) { best=mid; lo=mid+step; } else hi=mid-step;
      if(hi<lo) break;
   }
   return best;
}

double CalcLotsByRisk(double entry_price, double sl_price)
{
   if(!UseRiskPercent) return NormalizeLotsToStep(FixedLots);

   double sl_dist = MathAbs(entry_price - sl_price);
   if(sl_dist<=0) return 0.0;

   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_money = equity * (RiskPercent/100.0);

   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tick_size<=0 || tick_value<=0) return 0.0;

   double ticks = sl_dist / tick_size;
   double money_per_lot = ticks * tick_value;
   if(money_per_lot<=0) return 0.0;

   return NormalizeLotsToStep(risk_money / money_per_lot);
}

//========================= TU LÓGICA (ENTRADAS) =====================
bool is_above_ema() { return Close[1] > EMA[1]; }
bool is_below_ema() { return Close[1] < EMA[1]; }

// Secuencia basada en EMA (solo FILTRO de ENTRADA; NO cierra)
bool is_going_down()
{
   for(int i = BUFFLEN-1; i >= 1; i--)
      if(EMA[i] < EMA[i-1]) return false;
   return true;
}
bool is_going_up()
{
   for(int i = BUFFLEN-1; i >= 1; i--)
      if(EMA[i] > EMA[i-1]) return false;
   return true;
}

// Cruces (entradas)
bool cruce_compra() { return Close[2] < EMA[2] && Close[1] > EMA[1] && EMA[1] > EMA[2]; }
bool cruce_venta()  { return Close[2] > EMA[2] && Close[1] < EMA[1] && EMA[1] < EMA[2]; }

//========================= INIT / DEINIT ============================
int OnInit()
{
   gOptimizing = (bool)MQLInfoInteger(MQL_OPTIMIZATION);

   EMA_handle = iMA(_Symbol,PERIOD_CURRENT,periodo_ema,0,MODE_SMA,PRICE_CLOSE);
   ATR_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);

   if(EMA_handle==INVALID_HANDLE || ATR_handle==INVALID_HANDLE)
   {
      Print("Error creando indicadores. EMA:",EMA_handle," ATR:",ATR_handle);
      return INIT_FAILED;
   }

   ArraySetAsSeries(EMA,  true);
   ArraySetAsSeries(ATR,  true);
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Open, true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Low,  true);

   if(!gOptimizing)
   {
      SetupChartBeauty();
      // --- Dibuja la EMA en la ventana principal de precio
      ChartIndicatorAdd(0, 0, EMA_handle);
   }

   gLastBarTime = 0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(EMA_handle != INVALID_HANDLE) IndicatorRelease(EMA_handle);
   if(ATR_handle != INVALID_HANDLE) IndicatorRelease(ATR_handle);
   if(!gOptimizing) ObjectDelete(0,"HUD_Title");
}

//========================= ONTICK ===================================
void OnTick()
{
   // Un trade por vela
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime != gLastBarTime){ gLastBarTime = barTime; time_flag = true; }

   // Copia de datos
   CopyBuffer(EMA_handle, 0, 0, BUFFLEN+2, EMA);
   CopyBuffer(ATR_handle, 0, 0, BUFFLEN+2, ATR);

   CopyHigh (_Symbol, PERIOD_CURRENT,0,BUFFLEN+2,High);
   CopyOpen (_Symbol, PERIOD_CURRENT,0,BUFFLEN+2,Open);
   CopyClose(_Symbol, PERIOD_CURRENT,0,BUFFLEN+2,Close);
   CopyLow  (_Symbol, PERIOD_CURRENT,0,BUFFLEN+2,Low);

   if(!gOptimizing)
   {
      double pendiente = (ArraySize(EMA)>2)? (EMA[1]-EMA[2]) : 0.0;
      string hud =
         "EMA(" + IntegerToString(periodo_ema) + "): " + (ArraySize(EMA)>1? DoubleToString(EMA[1],_Digits):"-") + "  |  " +
         "ATR(" + IntegerToString(ATR_Period) + "): " + (ArraySize(ATR)>1? DoubleToString(ATR[1],_Digits):"-") + "\n" +
         "Pendiente EMA: " + DoubleToString(pendiente,_Digits) + "  |  Precio: " +
         (ArraySize(Close)>1? DoubleToString(Close[1],_Digits):"-");
      Comment(hud);
   }

   // Trailing por ATR
   trailing_stop_all();

   // Entradas (sin cierres manuales; solo SL/TS)
   bool no_posicion = (trade_ticket==0) || (!PositionSelectByTicket(trade_ticket));

   if(no_posicion && time_flag && ArraySize(ATR)>1 && ArraySize(EMA)>2)
   {
      bool long_sig  = cruce_compra() && is_above_ema() && is_going_up();
      bool short_sig = cruce_venta()  && is_below_ema() && is_going_down();

      const double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      const double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double d_init    = InitialSLDistance();

      if(long_sig)
      {
         double sl_price = NormalizeDouble(ask - d_init, _Digits);
         if(sl_price >= ask) sl_price = NormalizeDouble(ask - (StopsLevelPoints()+1)*_Point, _Digits);

         double lots_risk = CalcLotsByRisk(ask, sl_price);
         double lots_cap  = MaxLotsByMargin(ORDER_TYPE_BUY, ask);
         double lots      = NormalizeLotsToStep(MathMin(lots_risk, lots_cap));

         double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(lots < minv && lots_cap >= minv) lots = minv;

         if(lots >= minv && trade.Buy(lots, _Symbol, 0.0, sl_price, 0.0))
         { trade_ticket = trade.ResultOrder(); time_flag = false; }
      }
      else if(short_sig)
      {
         double sl_price = NormalizeDouble(bid + d_init, _Digits);
         if(sl_price <= bid) sl_price = NormalizeDouble(bid + (StopsLevelPoints()+1)*_Point, _Digits);

         double lots_risk = CalcLotsByRisk(bid, sl_price);
         double lots_cap  = MaxLotsByMargin(ORDER_TYPE_SELL, bid);
         double lots      = NormalizeLotsToStep(MathMin(lots_risk, lots_cap));

         double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(lots < minv && lots_cap >= minv) lots = minv;

         if(lots >= minv && trade.Sell(lots, _Symbol, 0.0, sl_price, 0.0))
         { trade_ticket = trade.ResultOrder(); time_flag = false; }
      }
   }

   // IMPORTANTE: NO hay bloque de "cierre por señal contraria".
   // La operación solo se cierra por SL (incluido trailing) o por fin de test.
}
