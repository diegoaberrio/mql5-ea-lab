//+------------------------------------------------------------------+
//|                                Fibo_CruceCierre_TrailingStop.mq5 |
//|                    (rev) Diego x diegoincode – Sep 2025          |
//+------------------------------------------------------------------+
#property copyright "Diego + diegoincode"
#property link      "https://www.mql5.com"
#property version   "1.14"

#include <Trade/Trade.mqh>
CTrade trade;
ulong  trade_ticket = 0;

#define BUFFLEN 3  // misma ventana corta usada en tu lógica de secuencia

//========================= INPUTS (SIMPLIFICADOS) ===================
// Riesgo / lotaje
input bool   UseRiskPercent   = true;    // true: % de cuenta; false: lotes fijos
input double RiskPercent      = 1.0;     // % de equity a arriesgar por operación
input double FixedLots        = 0.10;    // Lotes fijos si UseRiskPercent=false

// Stops por ATR
input int    ATR_Period       = 14;      // Periodo ATR
input double SL_ATR_Mult      = 1.50;    // SL = ATR * multiplicador
input double Trail_ATR_Mult   = 1.00;    // Paso de trailing = ATR * multiplicador

// Ventana para calcular anclas del Fibonacci
input int    NumeroVelasFibo  = 100;     // nº de velas para buscar el máximo y mínimo

//========================= ESTADO / ARRAYS ==========================
bool     time_flag     = true;   // un trade por vela
bool     gOptimizing   = false;  // evita objetos y estética en optimización
datetime gLastBarTime  = 0;

int      ATR_handle    = INVALID_HANDLE;

double   ATR[];
double   High[], Open[], Close[], Low[];

// Niveles Fibonacci en memoria (para señales y para optimización)
double   gFibo0    = 0.0; // nivel 0% (mínimo ventana)
double   gFibo100  = 0.0; // nivel 100% (máximo ventana)
double   gFibo50   = 0.0; // 50%
double   gFibo50Abs= 0.0; // |50%|

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
   MakeLabel("HUD_Title", "🤖 Fibo_CruceCierre_TS (ATR)", x, y, clrGold, 12, font_title);
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


//========================= TRAILING STOP (ATR) ======================
void trailing_stop_per_ticket(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;
   if(ArraySize(ATR)<2) return;

   const ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double cur_sl     = NormalizeDouble(PositionGetDouble(POSITION_SL), _Digits);

   const double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
   const double ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK), _Digits);

   double step = Trail_ATR_Mult * ATR[1];

   if(type == POSITION_TYPE_BUY)
   {
      double new_sl = NormalizeDouble(bid - step, _Digits);
      if( (bid > (open + step)) && (new_sl > cur_sl) )
         trade.PositionModify(ticket, new_sl, 0.0);
   }
   else if(type == POSITION_TYPE_SELL)
   {
      double new_sl = NormalizeDouble(ask + step, _Digits);
      if( (ask < (open - step)) && (new_sl < cur_sl || cur_sl==0.0) )
         trade.PositionModify(ticket, new_sl, 0.0);
   }
}

void trailing_stop_all()
{
   for(int i=0;i<PositionsTotal();i++)
      trailing_stop_per_ticket(PositionGetTicket(i));
}

//========================= UTILIDADES RIESGO ========================
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
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE); // no deprecado
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

//========================= LÓGICA ORIGINAL (SIN CAMBIOS) ============
bool is_going_down()
{
   for(int i = BUFFLEN-1; i >= 1; i--)
      if(Close[i] < Close[i-1]) return false;
   return true;
}
bool is_going_up()
{
   for(int i = BUFFLEN-1; i >= 1; i--)
      if(Close[i] > Close[i-1]) return false;
   return true;
}

// Entradas usan los niveles gFibo* (si no optimizamos, además los dibujamos)
bool cruce_compra()
{
   double NivelPrecio100 = gFibo100;
   double NivelPrecio50A = gFibo50Abs;
   return (Close[1] - Open[1] > (High[1] - Close[1])*3 && Close[1] - NivelPrecio100 >= (Close[1] - Open[1])/3)
       || ((Close[2] < NivelPrecio50A && Close[1] - Open[1] > (High[1] - Close[1])*3
            && Close[1] - NivelPrecio50A >= (Close[1] - Open[1])/3));
}

bool cruce_venta()
{
   double NivelPrecio0   = gFibo0;
   double NivelPrecio50A = gFibo50Abs;
   return (Open[1] - Close[1] > (Close[1] - Low[1])*3 && NivelPrecio0 - Close[1] >= (Open[1] - Close[1])/3)
       || (Close[2] > NivelPrecio50A && Open[1] - Close[1] > (Close[1] - Low[1])*3
           && NivelPrecio50A - Close[1] >= (Open[1] - Close[1])/3);
}

//========================= INIT / DEINIT ============================
int OnInit()
{
   gOptimizing = (bool)MQLInfoInteger(MQL_OPTIMIZATION);
   ATR_handle  = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);

   if(ATR_handle==INVALID_HANDLE)
   {
      Print("Error creando ATR");
      return INIT_FAILED;
   }

   ArraySetAsSeries(ATR,  true);
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Open, true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Low,  true);

   if(!gOptimizing) SetupChartBeauty();

   gLastBarTime = 0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(ATR_handle != INVALID_HANDLE) IndicatorRelease(ATR_handle);

   if(!gOptimizing)
   {
      ObjectDelete(0,"HUD_Title");
      ObjectDelete(0,"Fibonacci");
   }
}

//========================= ONTICK ===================================
void OnTick()
{
   // Un trade por vela (robusto en tester)
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime != gLastBarTime)
   {
      gLastBarTime = barTime;
      time_flag = true;
   }

   // Copia de datos
   int need = MathMax(NumeroVelasFibo+5, BUFFLEN+3);
   CopyBuffer(ATR_handle, 0, 0, BUFFLEN+2, ATR);

   CopyHigh (_Symbol, PERIOD_CURRENT,0,need,High);
   CopyOpen (_Symbol, PERIOD_CURRENT,0,need,Open);
   CopyClose(_Symbol, PERIOD_CURRENT,0,need,Close);
   CopyLow  (_Symbol, PERIOD_CURRENT,0,need,Low);

   if(ArraySize(High)<NumeroVelasFibo || ArraySize(Low)<NumeroVelasFibo) return;

   // Cálculo de niveles Fibo en memoria (máximo/mínimo de la ventana)
   int idxMax = ArrayMaximum(High, 2, NumeroVelasFibo);
   int idxMin = ArrayMinimum(Low,  2, NumeroVelasFibo);
   gFibo100   = High[idxMax];
   gFibo0     = Low[idxMin];
   gFibo50    = (gFibo100 + gFibo0) * 0.5;
   gFibo50Abs = MathAbs(gFibo50);

   // Dibujo Fibonacci y HUD solo en modo normal (no optimización)
   if(!gOptimizing)
   {
      // Construimos el objeto Fibo para visual (anclas temporales a izquierda/derecha)
      MqlRates prc[];
      ArraySetAsSeries(prc,true);
      int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, NumeroVelasFibo+5, prc);
      if(copied>=NumeroVelasFibo+1)
      {
         ObjectDelete(_Symbol, "Fibonacci");
         // Ancla izquierda: hace NumeroVelasFibo velas; derecha: barra actual
         datetime t_left  = prc[NumeroVelasFibo].time;
         datetime t_right = prc[0].time;
         ObjectCreate(_Symbol, "Fibonacci", OBJ_FIBO, 0,
                      t_left,  gFibo100,      // 100%
                      t_right, gFibo0);       // 0%
      }
      // HUD simple
      string hud =
         "ATR(" + IntegerToString(ATR_Period) + "): " + (ArraySize(ATR)>1? DoubleToString(ATR[1],_Digits):"-") + "\n" +
         "Fibo 0%: "   + DoubleToString(gFibo0,_Digits)    + "  |  " +
         "Fibo 50%: "  + DoubleToString(gFibo50,_Digits)   + "  |  " +
         "Fibo 100%: " + DoubleToString(gFibo100,_Digits);
      Comment(hud);
   }

   // Trailing por ATR
   trailing_stop_all();

   // Entrada a mercado (un trade por vela)
   bool no_posicion = (trade_ticket==0) || (!PositionSelectByTicket(trade_ticket));
   if(no_posicion && time_flag && ArraySize(ATR)>1)
   {
      bool long_sig  = cruce_compra() && is_going_up();
      bool short_sig = cruce_venta()  && is_going_down();

      const double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      const double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      if(long_sig)
      {
         double sl_price = NormalizeDouble(ask - SL_ATR_Mult*ATR[1], _Digits);
         double lots_risk = CalcLotsByRisk(ask, sl_price);
         double lots_cap  = MaxLotsByMargin(ORDER_TYPE_BUY, ask);
         double lots      = NormalizeLotsToStep( MathMin(lots_risk, lots_cap) );

         double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(lots < minv && lots_cap >= minv) lots = minv;

         if(lots >= minv)
         {
            if(trade.Buy(lots, _Symbol, 0.0, sl_price, 0.0))
            {
               trade_ticket = trade.ResultOrder();
               time_flag = false;
            }
         }
      }
      else if(short_sig)
      {
         double sl_price = NormalizeDouble(bid + SL_ATR_Mult*ATR[1], _Digits);
         double lots_risk = CalcLotsByRisk(bid, sl_price);
         double lots_cap  = MaxLotsByMargin(ORDER_TYPE_SELL, bid);
         double lots      = NormalizeLotsToStep( MathMin(lots_risk, lots_cap) );

         double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         if(lots < minv && lots_cap >= minv) lots = minv;

         if(lots >= minv)
         {
            if(trade.Sell(lots, _Symbol, 0.0, sl_price, 0.0))
            {
               trade_ticket = trade.ResultOrder();
               time_flag = false;
            }
         }
      }
   }
}
