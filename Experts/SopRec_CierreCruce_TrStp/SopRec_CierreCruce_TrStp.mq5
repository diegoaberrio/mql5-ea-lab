//+------------------------------------------------------------------+
//|                                     SopRec_CierreCruce_TrStp.mq5 |
//|                         (rev) Diego x diegoincode – Sep 2025     |
//+------------------------------------------------------------------+
#property copyright "Diego + diegoincode"
#property link      "https://www.mql5.com"
#property version   "1.14"

#include <Trade/Trade.mqh>
CTrade trade;
ulong  trade_ticket = 0;

#define BUFFLEN 3  // Ventana corta para cálculos de vela/MA

//========================= INPUTS (SIMPLIFICADOS) ===================
// Riesgo / lotaje
input bool   UseRiskPercent   = true;   // true: % de riesgo; false: lotes fijos
input double RiskPercent      = 1.0;    // % de equity a arriesgar
input double FixedLots        = 0.10;   // Lotes fijos si UseRiskPercent=false

// Stops por ATR
input int    ATR_Period       = 14;     // Periodo ATR
input double SL_ATR_Mult      = 1.50;   // SL = ATR * mult
input double Trail_ATR_Mult   = 1.00;   // Paso de trailing = ATR * mult

// Indicador de tendencia (como tu original)
input int    periodo_ema      = 50;     // Periodo SMA
input int    NumeroVelasCalculo = 100;  // Ventana para S/R

//========================= ESTADO / ARRAYS ==========================
bool     time_flag = true;
bool     gOptimizing = false;
datetime gLastBarTime = 0;

int      MA_handle;
int      ATR_handle;

double   MA[];
double   ATR[];
double   High[], Open[], Close[], Low[];

// S/R en variables (para optimización)
double   gRes = 0.0;   // Resistencia
double   gSup = 0.0;   // Soporte

//========================= LOOK & FEEL CHART ========================
// --- helper para etiquetas ----------------------------------------
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

// --- tu setup con más espacio y emoji ------------------------------
void SetupChartBeauty()
{
   // Estética base
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, 0, clrBlack);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, 0, clrSilver);
   ChartSetInteger(0, CHART_COLOR_GRID,       0, clrNONE);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL,0, clrLime);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR,0, clrTomato);
   ChartSetInteger(0, CHART_COLOR_CHART_UP,   0, clrLime);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, 0, clrTomato);
   ChartSetInteger(0, CHART_SHOW_OHLC,        0, true);
   ChartSetInteger(0, CHART_SHOW_GRID,        0, false);
   ChartSetInteger(0, CHART_SHOW_BID_LINE,    0, true);
   ChartSetInteger(0, CHART_SHOW_ASK_LINE,    0, true);

   // Layout arriba-derecha
   string tf = EnumToString((ENUM_TIMEFRAMES)Period());
   string font_title = "Segoe UI Emoji";   // para mostrar 🤖 y demás
   string font_text  = "Segoe UI Emoji";

   int x           = 12;        // margen derecho
   int y           = 12;        // margen superior
   int line_h      = 18;        // alto de línea
   int gap_title   = 6;         // espacio entre título y subtítulo
   int gap_blocks  = 14;        // espacio entre subtítulo y redes

   // Título + subtítulo
   MakeLabel("HUD_Title",  "🤖 SopRec_CierreCruce_TrStp (SMA/ATR)", x, y, clrGold, 12, font_title);
   y += line_h + gap_title;
   MakeLabel("HUD_SymTF",  _Symbol + " " + tf,                      x, y, clrSilver,10, font_text);

   // Espacio extra antes de redes
   y += gap_blocks;

   // Redes (puedes editar textos a tu gusto)
   MakeLabel("HUD_YT",   "📺 YouTube → @diegoincode",                     x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_TT",   "🎬 TikTok → @diegoincode",                      x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_IG",   "📸 Instagram → @diegoincode",                   x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_X",    "💬 X → @eldie10berrio",                         x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_LI",   "💼 LinkedIn → /in/diego-alonso-berrío-gómez",   x, y+=line_h, clrSilver,10, font_text);
   MakeLabel("HUD_GH",   "💻 GitHub → github.com/diegoaberrio",           x, y+=line_h, clrSilver,10, font_text);
}

//========================= TRAILING STOP (ATR) ======================
void trailing_stop_per_ticket(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;
   if(ArraySize(ATR)<2) return;

   const ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double cur_sl = NormalizeDouble(PositionGetDouble(POSITION_SL), _Digits);

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
   {
      ulong ticket = PositionGetTicket(i);
      trailing_stop_per_ticket(ticket);
   }
}

//========================= UTILIDADES ===============================
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
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE); // actualizado (no deprecado)
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxv = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step<=0) step=0.01;

   double lo = minv, hi = maxv, best = 0.0;
   for(int k=0;k<24;k++)
   {
      double mid = NormalizeLotsToStep((lo+hi)*0.5);
      if(mid<minv) { lo=minv; mid=minv; }
      double margin=0.0;
      if(!OrderCalcMargin(type,_Symbol,mid,price,margin)) { hi=mid; continue; }
      if(margin<=0) { hi=mid; continue; }
      if(margin <= free*0.95) { best=mid; lo=mid+step; }
      else hi=mid-step;
      if(hi<lo) break;
   }
   return best;
}

double CalcLotsByRisk(double entry_price, double sl_price)
{
   if(!UseRiskPercent)
      return NormalizeLotsToStep(FixedLots);

   double sl_dist = MathAbs(entry_price - sl_price);
   if(sl_dist <= 0) return 0.0;

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

//========================= SEÑALES (ORIGINALES) =====================
// Mantenemos is_going_* tal cual tu versión original
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

bool cruce_compra()
{
   double PrecioResistencia = gOptimizing ? gRes
                         : ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE, 0);
   return Close[1] - Open[1] > (High[1] - Close[1])*3
          && Close[1] - PrecioResistencia >= (Close[1] - Open[1])/3
          && Close[1] > MA[1];
}
bool cruce_venta()
{
   double PrecioSoporte = gOptimizing ? gSup
                       : ObjectGetDouble(0, "Soporte", OBJPROP_PRICE, 0);
   return Open[1] - Close[1] > (Close[1] - Low[1])*3
          && PrecioSoporte - Close[1] >= (Open[1] - Close[1])/3
          && Close[1] < MA[1];
}

//========================= TIMER ====================================
void OnTimer(){ time_flag = true; EventKillTimer(); }

//========================= INIT / DEINIT ============================
int OnInit()
{
   gOptimizing = (bool)MQLInfoInteger(MQL_OPTIMIZATION);

   MA_handle  = iMA(_Symbol, PERIOD_CURRENT, periodo_ema, 0, MODE_SMA, PRICE_CLOSE);
   ATR_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);

   if(MA_handle==INVALID_HANDLE || ATR_handle==INVALID_HANDLE)
   {
      Print("Error creando indicadores. MA:",MA_handle," ATR:",ATR_handle);
      return INIT_FAILED;
   }

   ArraySetAsSeries(MA,  true);
   ArraySetAsSeries(ATR, true);
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Low, true);

   if(!gOptimizing) SetupChartBeauty();

   gLastBarTime = 0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(MA_handle  != INVALID_HANDLE) IndicatorRelease(MA_handle);
   if(ATR_handle != INVALID_HANDLE) IndicatorRelease(ATR_handle);

   if(!gOptimizing)
   {
      ObjectDelete(0,"Resistencia");
      ObjectDelete(0,"Soporte");
      ObjectDelete(0,"HUD_Title");
   }
}

//========================= ONTICK ===================================
void OnTick()
{
   // Reset 1 trade/vela usando tiempo de la barra (válido en EAs)
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime != gLastBarTime)
   {
      gLastBarTime = barTime;
      time_flag = true;
   }

   // Copia de datos
   int need = MathMax(NumeroVelasCalculo, BUFFLEN+2);
   CopyBuffer(MA_handle,  0, 0, BUFFLEN, MA);
   CopyBuffer(ATR_handle, 0, 0, BUFFLEN, ATR);

   CopyHigh (_Symbol, PERIOD_CURRENT,0,need,High);
   CopyOpen (_Symbol, PERIOD_CURRENT,0,need,Open);
   CopyClose(_Symbol, PERIOD_CURRENT,0,need,Close);
   CopyLow  (_Symbol, PERIOD_CURRENT,0,need,Low);

   if(ArraySize(High)<NumeroVelasCalculo || ArraySize(Low)<NumeroVelasCalculo) return;

   // Cálculo S/R directo (sin objetos en optimización)
   int idxMax = ArrayMaximum(High, 2, NumeroVelasCalculo);
   int idxMin = ArrayMinimum(Low,  2, NumeroVelasCalculo);
   gRes = High[idxMax];
   gSup = Low[idxMin];

   // Dibujo y HUD solo fuera de optimización
   if(!gOptimizing)
   {
      ObjectDelete(_Symbol, "Resistencia");
      ObjectCreate(_Symbol, "Resistencia", OBJ_HLINE, 0, 0, gRes);
      ObjectSetInteger(0, "Resistencia", OBJPROP_COLOR, clrDeepSkyBlue);
      ObjectSetInteger(0, "Resistencia", OBJPROP_WIDTH, 2);

      ObjectDelete(_Symbol, "Soporte");
      ObjectCreate(_Symbol, "Soporte", OBJ_HLINE, 0, 0, gSup);
      ObjectSetInteger(0, "Soporte", OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(0, "Soporte", OBJPROP_WIDTH, 2);

      string hud =
         "SMA(" + IntegerToString(periodo_ema) + "): " + (ArraySize(MA)>1? DoubleToString(MA[1],_Digits):"-") + "  |  " +
         "ATR(" + IntegerToString(ATR_Period) + "): " + (ArraySize(ATR)>1? DoubleToString(ATR[1],_Digits):"-") + "\n" +
         "Resistencia: " + DoubleToString(gRes,_Digits) + "   |   Soporte: " + DoubleToString(gSup,_Digits) + "\n" +
         (UseRiskPercent? "Riesgo %: " + DoubleToString(RiskPercent,2)
                        : "Lotes fijos: " + DoubleToString(FixedLots,2)) +
         "  |  SLxATR: " + DoubleToString(SL_ATR_Mult,2) +
         "  |  TrailATR: " + DoubleToString(Trail_ATR_Mult,2);
      Comment(hud);
   }

   // Trailing por ATR
   trailing_stop_all();

   // Única entrada por vela
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
