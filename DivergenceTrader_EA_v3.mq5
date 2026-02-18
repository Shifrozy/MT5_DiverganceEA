//+------------------------------------------------------------------+
//|                                       DivergenceTrader_EA_v2.mq5 |
//|                                    Copyright 2026, Hassan Cheema |
//|                                     Developed for Client: Benjamin|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hassan Cheema"
#property link      ""
#property version   "2.00"
#property description "RSI Divergence Trading Expert Advisor V2"
#property description "With Support/Resistance & Supply/Demand Zone Validation"
#property description "Improved Divergence Detection - Class A Only"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_TRADING_MODE
{
   MODE_AUTOMATIC = 0,    // Automatic Trading
   MODE_MANUAL = 1        // Manual Mode (Signal Only)
};

enum ENUM_SL_TYPE
{
   SL_FIXED_PIPS = 0,     // Fixed Pips
   SL_ATR_BASED = 1       // ATR Based
};

enum ENUM_DIVERGENCE_TYPE
{
   DIV_ALL = 0,           // All Types
   DIV_REGULAR_ONLY = 1,  // Regular Only
   DIV_HIDDEN_ONLY = 2    // Hidden Only
};

enum ENUM_ZONE_TYPE
{
   ZONE_NONE = 0,         // No Zone Filter (Not Recommended)
   ZONE_SR_ONLY = 1,      // Support/Resistance Only
   ZONE_SD_ONLY = 2,      // Supply/Demand Only
   ZONE_BOTH = 3          // Both S/R and S/D Zones
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== Trading Mode Settings ==="
input ENUM_TRADING_MODE   TradingMode = MODE_AUTOMATIC;      // Trading Mode
input bool                ShowDivergenceLines = true;        // Draw Divergence Lines on Chart
input bool                ShowZones = true;                  // Draw S/R and S/D Zones on Chart

input group "=== Multi-Timeframe Scanning ==="
input bool                Scan_D1 = true;                    // Scan Daily for Divergence
input bool                Scan_H4 = true;                    // Scan H4 for Divergence
input bool                Scan_H1 = true;                    // Scan H1 for Divergence
input bool                Scan_M30 = true;                   // Scan M30 for Divergence
input bool                Scan_M15 = true;                   // Scan M15 for Divergence
input bool                Scan_M5 = true;                    // Scan M5 for Divergence
input ENUM_TIMEFRAMES     EntryTimeframe = PERIOD_M1;        // Entry Confirmation Timeframe (M1 for Sniper)

input group "=== EMA Settings ==="
input int                 EMA_Entry_Period = 9;              // EMA for Entry Confirmation
input int                 EMA_TP_Period = 50;                // EMA for Take Profit

input group "=== RSI Settings ==="
input int                 RSI_Period = 14;                   // RSI Period
input ENUM_APPLIED_PRICE  RSI_AppliedPrice = PRICE_CLOSE;    // RSI Applied Price
input double              RSI_Overbought = 70.0;             // RSI Overbought Level
input double              RSI_Oversold = 30.0;               // RSI Oversold Level
input bool                RequireRSIExtreme = true;          // Require RSI in OB/OS Zone for Divergence

input group "=== Divergence Detection Settings ==="
input int                 SwingStrength = 3;                 // Swing Detection Strength (left/right bars)
input int                 MaxBarsBack = 100;                 // Max Bars to Look Back for Divergence
input int                 MinBarsBetween = 3;                // Min Bars Between Swing Points
input int                 MaxBarsBetween = 50;               // Max Bars Between Swing Points
input ENUM_DIVERGENCE_TYPE DivergenceFilter = DIV_ALL;       // Divergence Type Filter
input double              MinRSIDivergence = 2.0;            // Minimum RSI Difference for Valid Divergence
input double              MinPriceDivergence = 0.0;          // Minimum Price Difference (0 = auto by ATR)

input group "=== Zone Validation Settings ==="
input ENUM_ZONE_TYPE      ZoneFilter = ZONE_BOTH;            // Zone Type Filter
input int                 SR_LookbackBars = 200;             // S/R Lookback Period (bars)
input int                 SR_TouchCount = 2;                 // Minimum Touches for Valid S/R Level
input double              SR_ZoneWidth_ATR = 0.5;            // S/R Zone Width (ATR multiplier)
input double              MaxDistanceFromZone = 1.0;         // Max Distance from Zone (ATR multiplier)

input group "=== Supply/Demand Zone Settings ==="
input int                 SD_ConsolidationBars = 5;          // Min Consolidation Bars for S/D Zone
input double              SD_ImpulseMoveATR = 2.0;           // Min Impulsive Move (ATR multiplier)
input int                 SD_LookbackBars = 100;             // S/D Lookback Period (bars)
input double              SD_ZoneWidthATR = 0.3;             // S/D Zone Width (ATR multiplier)

input group "=== Trend Alignment ==="
input bool                RequireTrendAlignment = false;     // Require Trend Alignment (Divergence is a reversal signal)
input int                 TrendEMA_Period = 50;              // Trend EMA Period
input int                 TrendEMA_FastPeriod = 20;          // Fast EMA Period

input group "=== Risk Management ==="
input bool                EnableBreakEven = true;            // Enable Break-Even at +10 Pips
input double              BreakEvenPips = 10.0;              // Pips to trigger Break-Even
input ENUM_SL_TYPE        StopLossType = SL_ATR_BASED;       // Stop Loss Type
input double              FixedStopLossPips = 50.0;          // Fixed Stop Loss (Pips)
input int                 ATR_Period = 14;                   // ATR Period (for ATR-based SL)
input double              ATR_Multiplier = 2.0;              // ATR Multiplier for SL
input double              RiskRewardRatio = 2.0;             // Risk to Reward Ratio (fallback)
input double              RiskPercent = 1.0;                 // Risk Per Trade (% of Balance)
input double              LotSize = 0.01;                    // Fixed Lot Size (if Risk% = 0)

input group "=== Trade Management ==="
input int                 MagicNumber = 123456;              // Magic Number
input int                 MaxSlippage = 30;                  // Max Slippage (Points)
input int                 MaxSpreadPips = 50;                // Max Spread (Pips) - 0 to disable
input bool                TradeOnNewBarOnly = true;          // Trade Only on New Bar (Set true for stability)

input group "=== XAUUSD High Volatility Settings ==="
input bool                EnableVolatilityFilter = true;     // Enable Volatility Filter
input double              ATR_VolatilityThreshold = 0.0;     // ATR Threshold (0 = auto-calculate)
input double              VolatilityMultiplier = 1.5;        // ATR multiplier for high volatility

input group "=== Visual Settings ==="
input color               BullishDivColor = clrLime;         // Bullish Divergence Line Color
input color               BearishDivColor = clrRed;          // Bearish Divergence Line Color
input color               SupportZoneColor = clrDodgerBlue;  // Support Zone Color
input color               ResistanceZoneColor = clrOrangeRed;// Resistance Zone Color
input color               DemandZoneColor = clrGreen;        // Demand Zone Color
input color               SupplyZoneColor = clrCrimson;      // Supply Zone Color
input int                 LineWidth = 2;                     // Divergence Line Width
input ENUM_LINE_STYLE     LineStyle = STYLE_SOLID;           // Divergence Line Style

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade      trade;
CPositionInfo positionInfo;
CSymbolInfo symbolInfo;

int htf_rsi_handles[6];   // MTF RSI handles
int htf_ema50_handles[6]; // MTF EMA 50 handles for zones
int htf_ema200_handles[6];// MTF EMA 200 handles for zones
int tp_ema50_handles[6];  // Lower TF EMA 50 handles for TP
int entry_ema9_handle;
int rsiHandle; // Used as handle for current chart
int atrHandle;
int emaSlowHandle;
int emaFastHandle;

ENUM_TIMEFRAMES trackedTFs[] = {PERIOD_D1, PERIOD_H4, PERIOD_H1, PERIOD_M30, PERIOD_M15, PERIOD_M5};
bool enabledTFs[6];

double rsiBuffer[];
double atrBuffer[];
double emaSlowBuffer[];
double emaFastBuffer[];
double ema9Buffer[];
double ema50Buffer[];

struct PendingSignal
{
   bool active;
   bool isBullish;
   ENUM_TIMEFRAMES signalTF;
   datetime detectionTime;
   double swingPrice;
   string divergenceType;
};

PendingSignal currentSignal;

datetime lastBarTime = 0;
datetime lastProcessedSignalTime[6]; // Track last processed signal per TF
bool hasOpenPosition = false;
int currentTicket = 0;
ENUM_TIMEFRAMES activeTradeSignalTF = PERIOD_CURRENT; // Track active trade source TF

// Zone storage
struct ZoneInfo
{
   double upperLevel;
   double lowerLevel;
   bool isSupply;       // true = Supply/Resistance, false = Demand/Support
   int touchCount;
   datetime lastTouch;
   bool isValid;
};

ZoneInfo supportResistanceZones[];
ZoneInfo supplyDemandZones[];

// Divergence tracking
struct DivergenceInfo
{
   bool detected;
   bool isBullish;
   bool isRegular;
   bool isHidden;
   bool isExaggerated;
   int priceBar1;
   int priceBar2;
   double price1;
   double price2;
   double rsi1;
   double rsi2;
   bool isInZone;
   string zoneName;
};

DivergenceInfo lastDivergence;

// Swing point storage
struct SwingPoint
{
   int bar;
   double price;
   double rsi;
   bool isHigh;
};

SwingPoint swingHighs[];
SwingPoint swingLows[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize symbol info
   // Initialize symbol info
   if(!symbolInfo.Name(_Symbol))
   {
      Print("Error initializing symbol info");
      return INIT_FAILED;
   }
   
   // Set up trading object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxSlippage);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   enabledTFs[0] = Scan_D1;
   enabledTFs[1] = Scan_H4;
   enabledTFs[2] = Scan_H1;
   enabledTFs[3] = Scan_M30;
   enabledTFs[4] = Scan_M15;
   enabledTFs[5] = Scan_M5;

   for(int i=0; i<6; i++) {
      if(enabledTFs[i]) {
         htf_rsi_handles[i] = iRSI(_Symbol, trackedTFs[i], RSI_Period, RSI_AppliedPrice);
      // Zone fallback EMAs
      htf_ema50_handles[i] = iMA(_Symbol, trackedTFs[i], 50, 0, MODE_EMA, PRICE_CLOSE);
      htf_ema200_handles[i] = iMA(_Symbol, trackedTFs[i], 200, 0, MODE_EMA, PRICE_CLOSE);
      
      // TP Targets: Map to EMA 50 of the NEXT LOWER timeframe
      ENUM_TIMEFRAMES tpTF = PERIOD_CURRENT;
         if(trackedTFs[i] == PERIOD_D1) tpTF = PERIOD_H4;
         else if(trackedTFs[i] == PERIOD_H4) tpTF = PERIOD_H1;
         else if(trackedTFs[i] == PERIOD_H1) tpTF = PERIOD_M30;
         else if(trackedTFs[i] == PERIOD_M30) tpTF = PERIOD_M15;
         else if(trackedTFs[i] == PERIOD_M15) tpTF = PERIOD_M5;
         tp_ema50_handles[i] = iMA(_Symbol, tpTF, EMA_TP_Period, 0, MODE_EMA, PRICE_CLOSE);
      } else {
         htf_rsi_handles[i] = INVALID_HANDLE;
         htf_ema50_handles[i] = INVALID_HANDLE;
         tp_ema50_handles[i] = INVALID_HANDLE;
      }
   }
   
   entry_ema9_handle = iMA(_Symbol, EntryTimeframe, EMA_Entry_Period, 0, MODE_EMA, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, RSI_AppliedPrice);
   emaSlowHandle = iMA(_Symbol, PERIOD_CURRENT, TrendEMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   emaFastHandle = iMA(_Symbol, PERIOD_CURRENT, TrendEMA_FastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(atrBuffer, true);
   ArraySetAsSeries(emaSlowBuffer, true);
   ArraySetAsSeries(emaFastBuffer, true);
   ArraySetAsSeries(ema9Buffer, true);
   ArraySetAsSeries(ema50Buffer, true);
   
   ZeroMemory(currentSignal);
   for(int i=0; i<6; i++) lastProcessedSignalTime[i] = 0;
   
   // Initial zone detection so we don't wait for first bar
   DetectSupportResistanceZones();
   DetectSupplyDemandZones();
   
   Print("Sniper Divergence EA Initialized. Over-trading protection active.");
   return INIT_SUCCEEDED;
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   for(int i=0; i<6; i++) {
      if(htf_rsi_handles[i] != INVALID_HANDLE) IndicatorRelease(htf_rsi_handles[i]);
      if(htf_ema50_handles[i] != INVALID_HANDLE) IndicatorRelease(htf_ema50_handles[i]);
      if(htf_ema200_handles[i] != INVALID_HANDLE) IndicatorRelease(htf_ema200_handles[i]);
      if(tp_ema50_handles[i] != INVALID_HANDLE) IndicatorRelease(tp_ema50_handles[i]);
   }
   if(entry_ema9_handle != INVALID_HANDLE) IndicatorRelease(entry_ema9_handle);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
   if(emaSlowHandle != INVALID_HANDLE) IndicatorRelease(emaSlowHandle);
   if(emaFastHandle != INVALID_HANDLE) IndicatorRelease(emaFastHandle);
   
   // Remove all objects from chart
   ObjectsDeleteAll(0, "DIV_");
   ObjectsDeleteAll(0, "SR_");
   ObjectsDeleteAll(0, "SD_");
   
   Print("DivergenceTrader EA V2 deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   symbolInfo.RefreshRates();
   CheckOpenPosition();
   
   // Refresh visual zones on every new bar of the current chart
   if(IsNewBar()) {
      DetectSupportResistanceZones();
      DetectSupplyDemandZones();
   }
   
   // SCANNING PHASE: Priority given to Higher Timeframes
   for(int i=0; i<6; i++) {
      if(enabledTFs[i]) {
         if(ScanDivergenceForTF(trackedTFs[i], htf_rsi_handles[i])) {
            datetime signalBarTime = iTime(_Symbol, trackedTFs[i], lastDivergence.priceBar1);
            
            // Safety: Skip if this specific signal was already processed
            if(signalBarTime <= lastProcessedSignalTime[i]) continue;
            
            // MANDATORY RULE: Divergence MUST be inside or near a zone to be accepted
            string dummyZone = "";
            bool inManualZone = IsPriceInZone(lastDivergence.price1, lastDivergence.isBullish, dummyZone);
            bool nearEMA = IsPriceNearHTFEMA(lastDivergence.price1, trackedTFs[i]);
            
            if(!inManualZone && !nearEMA) continue;
            
            // Freshness: Only accept if the recent swing point is fresh (within 15 bars)
            if(lastDivergence.priceBar1 > SwingStrength + 15) continue;

            // Priority: Only replace if new signal is from a higher or same TF
            if(!currentSignal.active || i <= 2) { 
               currentSignal.active = true;
               currentSignal.signalTF = trackedTFs[i];
               currentSignal.isBullish = lastDivergence.isBullish;
               currentSignal.detectionTime = TimeCurrent();
               currentSignal.swingPrice = lastDivergence.price1;
               currentSignal.divergenceType = lastDivergence.isRegular ? "Reg" : "Hid";
               
               Print("IMMEDIATE SNIPER SIGNAL: ", currentSignal.divergenceType, " ", (currentSignal.isBullish?"BULL":"BEAR"), 
                     " on ", EnumToString(currentSignal.signalTF), ". Executing NOW.");
               
               // RULE: Execute IMMEDIATELY upon detection (Zero Lag)
               activeTradeSignalTF = currentSignal.signalTF;
               if(ExecuteBufferedTrade()) {
                  lastProcessedSignalTime[i] = signalBarTime; // ONLY mark as seen if trade successful
               }
               ZeroMemory(currentSignal); // Clear after immediate execution
               break; 
            }
         }
      }
   }
   
   // ENTRY PHASE: (Legacy Sniper Wait - Disabled for Immediate Execution)
   // Now handled inside Scanning Phase for zero lag.
   
   // Safety: In case a signal was set but not executed
   if(currentSignal.active && !hasOpenPosition) {
       activeTradeSignalTF = currentSignal.signalTF;
       ExecuteBufferedTrade();
       ZeroMemory(currentSignal);
   }
   
   // DYNAMIC TP & BREAK-EVEN PHASE: Handle open positions
   if(hasOpenPosition) {
      UpdateDynamicTPAndBE();
   }
}

void UpdateDynamicTPAndBE()
{
   if(!positionInfo.SelectByTicket(currentTicket)) return;
   
   double entryPrice = positionInfo.PriceOpen();
   double currentPrice = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? symbolInfo.Bid() : symbolInfo.Ask();
   double currentSL = positionInfo.StopLoss();
   double currentTP = positionInfo.TakeProfit();
   double pipValue = GetPipValue();
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // 1. Apply Break-Even at +10 pips
   if(EnableBreakEven) {
      double profitPips = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 
                          (currentPrice - entryPrice) / pipValue : 
                          (entryPrice - currentPrice) / pipValue;
                          
      if(profitPips >= BreakEvenPips) {
         bool needsSLUpdate = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? (currentSL < entryPrice - 5*point) : (currentSL > entryPrice + 5*point || currentSL == 0);
         if(needsSLUpdate) {
            trade.PositionModify(currentTicket, entryPrice, currentTP);
            Print("DYNAMIC: SL moved to Break-Even for ticket ", currentTicket);
         }
      }
   }
   
   // 2. Follow Dynamic TP (EMA 50 of target timeframe)
   double targetTP = GetTPLevelForSignal(activeTradeSignalTF);
   if(targetTP > 0) {
      bool needsTPUpdate = MathAbs(targetTP - currentTP) > 20 * point; // Only update if significantly moved
      if(needsTPUpdate) {
         trade.PositionModify(currentTicket, currentSL, NormalizeDouble(targetTP, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      }
   }
}

bool CheckSniperEntryConfirmation()
{
   // AGGRESSIVE SNIPER: No EMA, No Candle Close wait. Entry as soon as Price Touches Zone after Signal.
   symbolInfo.RefreshRates();
   double price = currentSignal.isBullish ? symbolInfo.Ask() : symbolInfo.Bid();
   
   string zoneName = "";
   double tpLevel = GetTPLevelForSignal(currentSignal.signalTF);
   double currentATR = GetCurrentATR();
   
   if(currentSignal.isBullish) {
      // INSTANT ENTRY: Just check if price is in/touching a support/demand zone
      if(IsPriceInZone(price, true, zoneName) || IsPriceNearHTFEMA(price, currentSignal.signalTF)) {
         return true; // Pick divergence immediately
      }
   } else {
      // INSTANT ENTRY: Just check if price is in/touching a resistance/supply zone
      if(IsPriceInZone(price, false, zoneName) || IsPriceNearHTFEMA(price, currentSignal.signalTF)) {
         return true; // Pick divergence immediately
      }
   }
   
   return false;
}

double GetTPLevelForSignal(ENUM_TIMEFRAMES signalTF)
{
   if(signalTF == PERIOD_CURRENT) return 0;
   int index = -1;
   for(int i=0; i<6; i++) if(trackedTFs[i] == signalTF) { index = i; break; }
   if(index == -1 || tp_ema50_handles[index] == INVALID_HANDLE) return 0;
   
   double emaTP[1]; 
   if(CopyBuffer(tp_ema50_handles[index], 0, 0, 1, emaTP) > 0) return emaTP[0];
   return 0;
}

bool IsPriceNearHTFEMA(double price, ENUM_TIMEFRAMES tf)
{
   int index = -1;
   for(int i=0; i<6; i++) if(trackedTFs[i] == tf) { index = i; break; }
   if(index == -1) return false;
   
   double ema50[1], ema200[1];
   double currentATR = GetCurrentATR();
   bool near = false;
   
   if(htf_ema50_handles[index] != INVALID_HANDLE && CopyBuffer(htf_ema50_handles[index], 0, 0, 1, ema50) > 0) {
      if(MathAbs(price - ema50[0]) < currentATR * 1.5) near = true; // Use 1.5 ATR for better touch detection
   }
   
   if(!near && htf_ema200_handles[index] != INVALID_HANDLE && CopyBuffer(htf_ema200_handles[index], 0, 0, 1, ema200) > 0) {
      if(MathAbs(price - ema200[0]) < currentATR * 1.5) near = true;
   }
   
   return near;
}

bool ScanDivergenceForTF(ENUM_TIMEFRAMES tf, int handle)
{
   if(handle == INVALID_HANDLE) return false;
   
   // Custom search for specific TF - Fast Detection (Start from 1)
   ArrayResize(swingHighs, 0); ArrayResize(swingLows, 0);
   if(CopyBuffer(handle, 0, 0, MaxBarsBack + 10, rsiBuffer) <= 0) return false;
   
   for(int i = 1; i < MaxBarsBack - 1; i++) {
      double high = iHigh(_Symbol, tf, i);
      double low = iLow(_Symbol, tf, i);
      bool isSH = true, isSL = true;
      for(int j = 1; j <= SwingStrength; j++) {
         if(iHigh(_Symbol, tf, i+j) >= high || iHigh(_Symbol, tf, i-j) >= high) isSH = false;
         if(iLow(_Symbol, tf, i+j) <= low || iLow(_Symbol, tf, i-j) <= low) isSL = false;
      }
      if(isSH) {
         SwingPoint sp = {i, high, rsiBuffer[i], true};
         ArrayResize(swingHighs, ArraySize(swingHighs)+1); swingHighs[ArraySize(swingHighs)-1] = sp;
      }
      if(isSL) {
         SwingPoint sp = {i, low, rsiBuffer[i], false};
         ArrayResize(swingLows, ArraySize(swingLows)+1); swingLows[ArraySize(swingLows)-1] = sp;
      }
   }
   
   if(ArraySize(swingHighs) >= 2) {
      SwingPoint sp1 = swingHighs[0], sp2 = swingHighs[1]; // [0] is most recent
      if(sp2.bar - sp1.bar >= MinBarsBetween && sp2.bar - sp1.bar <= MaxBarsBetween) {
         if((sp1.price > sp2.price && sp1.rsi < sp2.rsi) || (sp1.price < sp2.price && sp1.rsi > sp2.rsi)) {
            if(ValidateDivergence(sp1, sp2, false)) {
               lastDivergence.isBullish = false; 
               lastDivergence.isRegular = sp1.price > sp2.price;
               lastDivergence.isHidden = !lastDivergence.isRegular;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.detected = true;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLineMTF("DIV_BEAR_" + EnumToString(tf), tf, sp1.bar, sp2.bar, sp1.price, sp2.price, BearishDivColor);
               return true;
            }
         }
      }
   }
   if(ArraySize(swingLows) >= 2) {
      SwingPoint sp1 = swingLows[0], sp2 = swingLows[1]; // [0] is most recent
      if(sp2.bar - sp1.bar >= MinBarsBetween && sp2.bar - sp1.bar <= MaxBarsBetween) {
         if((sp1.price < sp2.price && sp1.rsi > sp2.rsi) || (sp1.price > sp2.price && sp1.rsi < sp2.rsi)) {
            if(ValidateDivergence(sp1, sp2, true)) {
               lastDivergence.isBullish = true; 
               lastDivergence.isRegular = sp1.price < sp2.price;
               lastDivergence.isHidden = !lastDivergence.isRegular;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.detected = true;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLineMTF("DIV_BULL_" + EnumToString(tf), tf, sp1.bar, sp2.bar, sp1.price, sp2.price, BullishDivColor);
               return true;
            }
         }
      }
   }
   return false;
}

void DrawDivergenceLineMTF(string name, ENUM_TIMEFRAMES tf, int bar1, int bar2, double price1, double price2, color lineColor)
{
   string objName = name + "_" + TimeToString(TimeCurrent());
   datetime time1 = iTime(_Symbol, tf, bar1);
   datetime time2 = iTime(_Symbol, tf, bar2);
   
   ObjectDelete(0, objName);
   if(ObjectCreate(0, objName, OBJ_TREND, 0, time2, price2, time1, price1)) {
      ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, LineWidth);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   }
}

bool ExecuteBufferedTrade()
{
   bool isBuy = currentSignal.isBullish;
   double price = isBuy ? symbolInfo.Ask() : symbolInfo.Bid();
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   
   // Calculate TP level
   double tp = GetTPLevelForSignal(currentSignal.signalTF);
   
   // Calculate SL Behind Zone
   double currentATR = GetCurrentATR();
   string zoneName = "";
   double sl = isBuy ? currentSignal.swingPrice - (currentATR * 0.7) : currentSignal.swingPrice + (currentATR * 0.7);
   
   // Search for nearest actual zone levels for logical SL
   for(int i=0; i<ArraySize(supportResistanceZones); i++) {
      if(supportResistanceZones[i].isSupply != isBuy) { // Buy:Support, Sell:Resistance
         if(isBuy) sl = MathMin(sl, supportResistanceZones[i].lowerLevel - (5*point));
         else sl = MathMax(sl, supportResistanceZones[i].upperLevel + (5*point));
      }
   }
   
   // Validation for TP
   if(isBuy) {
      if(tp <= price + stopLevel) tp = price + MathMax(150*point, (price - sl) * 1.5);
   } else {
      if(tp >= price - stopLevel || tp == 0) tp = price - MathMax(150*point, (price - sl) * 1.5);
   }
   
   // Final normalization and StopLevel safety
   if(isBuy) {
      if(sl >= price - stopLevel) sl = price - (stopLevel + 5*point);
      if(tp <= price + stopLevel) tp = price + (stopLevel + 5*point);
   } else {
      if(sl <= price + stopLevel) sl = price + (stopLevel + 5*point);
      if(tp >= price - stopLevel) tp = price - (stopLevel + 5*point);
   }

   double slPips = MathAbs(price - sl) / GetPipValue();
   double lots = CalculateLotSize(slPips);
   
   string comment = "DivSniper_" + currentSignal.divergenceType + (isBuy?"_B_":"_S_") + EnumToString(currentSignal.signalTF);
   
   bool result = false;
   if(isBuy) {
      result = trade.Buy(lots, _Symbol, price, sl, tp, comment);
   } else {
      result = trade.Sell(lots, _Symbol, price, sl, tp, comment);
   }
   
   if(trade.ResultRetcode() == 10009 || trade.ResultRetcode() == 10008) {
      currentTicket = (int)trade.ResultOrder();
      hasOpenPosition = true;
      Print("SNIPER ENTRY: ", (isBuy?"BUY":"SELL"), " executed. Ticket: ", currentTicket, " SL: ", sl, " TP: ", tp);
      return true;
   } else {
      Print("SNIPER ENTRY FAILED. Error: ", GetLastError(), " Retcode: ", trade.ResultRetcode());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Check if new bar has formed                                        |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get pip value for the symbol                                       |
//+------------------------------------------------------------------+
double GetPipValue()
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5)
      return SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;
   return SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Get current ATR value                                              |
//+------------------------------------------------------------------+
double GetCurrentATR()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(atrHandle, 0, 1, 1, atr) > 0)
      return atr[0];
   return 0;
}

//+------------------------------------------------------------------+
//| Check for open positions                                           |
//+------------------------------------------------------------------+
void CheckOpenPosition()
{
   hasOpenPosition = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            hasOpenPosition = true;
            currentTicket = (int)positionInfo.Ticket();
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Support and Resistance Zones                                |
//+------------------------------------------------------------------+
void DetectSupportResistanceZones()
{
   ArrayResize(supportResistanceZones, 0);
   
   double currentATR = GetCurrentATR();
   if(currentATR == 0) return;
   
   double zoneWidth = currentATR * SR_ZoneWidth_ATR;
   
   // Find significant highs and lows
   double levels[];
   int levelCounts[];
   bool levelIsHigh[];
   
   for(int i = SwingStrength; i < SR_LookbackBars; i++)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      
      bool isSwingHigh = true;
      bool isSwingLow = true;
      
      for(int j = 1; j <= SwingStrength; j++)
      {
         if(iHigh(_Symbol, PERIOD_CURRENT, i + j) >= high || iHigh(_Symbol, PERIOD_CURRENT, i - j) >= high)
            isSwingHigh = false;
         if(iLow(_Symbol, PERIOD_CURRENT, i + j) <= low || iLow(_Symbol, PERIOD_CURRENT, i - j) <= low)
            isSwingLow = false;
      }
      
      if(isSwingHigh)
         AddOrUpdateLevel(levels, levelCounts, levelIsHigh, high, zoneWidth, true);
      if(isSwingLow)
         AddOrUpdateLevel(levels, levelCounts, levelIsHigh, low, zoneWidth, false);
   }
   
   // Create zones from valid levels
   for(int i = 0; i < ArraySize(levels); i++)
   {
      if(levelCounts[i] >= SR_TouchCount)
      {
         ZoneInfo zone;
         zone.upperLevel = levels[i] + zoneWidth / 2;
         zone.lowerLevel = levels[i] - zoneWidth / 2;
         zone.isSupply = levelIsHigh[i];
         zone.touchCount = levelCounts[i];
         zone.lastTouch = TimeCurrent();
         zone.isValid = true;
         
         int size = ArraySize(supportResistanceZones);
         ArrayResize(supportResistanceZones, size + 1);
         supportResistanceZones[size] = zone;
         
         if(ShowZones)
            DrawZone("SR_" + IntegerToString(size), zone.lowerLevel, zone.upperLevel, 
                     zone.isSupply ? ResistanceZoneColor : SupportZoneColor, 
                     zone.isSupply ? "Resistance" : "Support");
      }
   }
   
   Print("Detected ", ArraySize(supportResistanceZones), " S/R zones");
}

//+------------------------------------------------------------------+
//| Add or update price level for S/R detection                        |
//+------------------------------------------------------------------+
void AddOrUpdateLevel(double &levels[], int &counts[], bool &isHigh[], double price, double tolerance, bool high)
{
   for(int i = 0; i < ArraySize(levels); i++)
   {
      if(MathAbs(levels[i] - price) < tolerance)
      {
         counts[i]++;
         levels[i] = (levels[i] + price) / 2; // Average the level
         return;
      }
   }
   
   int size = ArraySize(levels);
   ArrayResize(levels, size + 1);
   ArrayResize(counts, size + 1);
   ArrayResize(isHigh, size + 1);
   levels[size] = price;
   counts[size] = 1;
   isHigh[size] = high;
}

//+------------------------------------------------------------------+
//| Detect Supply and Demand Zones                                     |
//+------------------------------------------------------------------+
void DetectSupplyDemandZones()
{
   ArrayResize(supplyDemandZones, 0);
   
   double currentATR = GetCurrentATR();
   if(currentATR == 0) return;
   
   double impulsiveMove = currentATR * SD_ImpulseMoveATR;
   double zoneWidth = currentATR * SD_ZoneWidthATR;
   
   // Look for impulsive moves followed by consolidation
   for(int i = SD_ConsolidationBars + 2; i < SD_LookbackBars; i++)
   {
      // Check for bullish impulsive move (Demand Zone)
      double moveUp = iClose(_Symbol, PERIOD_CURRENT, i - SD_ConsolidationBars - 1) - 
                      iClose(_Symbol, PERIOD_CURRENT, i);
      
      if(moveUp >= impulsiveMove)
      {
         // Check for consolidation before the move
         bool isConsolidation = true;
         double consolidationHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
         double consolidationLow = iLow(_Symbol, PERIOD_CURRENT, i);
         
         for(int j = 1; j < SD_ConsolidationBars; j++)
         {
            double barHigh = iHigh(_Symbol, PERIOD_CURRENT, i + j);
            double barLow = iLow(_Symbol, PERIOD_CURRENT, i + j);
            double barRange = barHigh - barLow;
            
            if(barRange > currentATR * 1.5) isConsolidation = false;
            consolidationHigh = MathMax(consolidationHigh, barHigh);
            consolidationLow = MathMin(consolidationLow, barLow);
         }
         
         if(isConsolidation)
         {
            ZoneInfo zone;
            zone.upperLevel = consolidationHigh;
            zone.lowerLevel = consolidationLow;
            zone.isSupply = false; // Demand zone
            zone.touchCount = 1;
            zone.lastTouch = iTime(_Symbol, PERIOD_CURRENT, i);
            zone.isValid = true;
            
            if(!IsZoneOverlapping(zone, supplyDemandZones))
            {
               int size = ArraySize(supplyDemandZones);
               ArrayResize(supplyDemandZones, size + 1);
               supplyDemandZones[size] = zone;
               
               if(ShowZones)
                  DrawZone("SD_D" + IntegerToString(size), zone.lowerLevel, zone.upperLevel, 
                           DemandZoneColor, "Demand");
            }
         }
      }
      
      // Check for bearish impulsive move (Supply Zone)
      double moveDown = iClose(_Symbol, PERIOD_CURRENT, i) - 
                        iClose(_Symbol, PERIOD_CURRENT, i - SD_ConsolidationBars - 1);
      
      if(moveDown >= impulsiveMove)
      {
         // Check for consolidation before the move
         bool isConsolidation = true;
         double consolidationHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
         double consolidationLow = iLow(_Symbol, PERIOD_CURRENT, i);
         
         for(int j = 1; j < SD_ConsolidationBars; j++)
         {
            double barHigh = iHigh(_Symbol, PERIOD_CURRENT, i + j);
            double barLow = iLow(_Symbol, PERIOD_CURRENT, i + j);
            double barRange = barHigh - barLow;
            
            if(barRange > currentATR * 1.5) isConsolidation = false;
            consolidationHigh = MathMax(consolidationHigh, barHigh);
            consolidationLow = MathMin(consolidationLow, barLow);
         }
         
         if(isConsolidation)
         {
            ZoneInfo zone;
            zone.upperLevel = consolidationHigh;
            zone.lowerLevel = consolidationLow;
            zone.isSupply = true; // Supply zone
            zone.touchCount = 1;
            zone.lastTouch = iTime(_Symbol, PERIOD_CURRENT, i);
            zone.isValid = true;
            
            if(!IsZoneOverlapping(zone, supplyDemandZones))
            {
               int size = ArraySize(supplyDemandZones);
               ArrayResize(supplyDemandZones, size + 1);
               supplyDemandZones[size] = zone;
               
               if(ShowZones)
                  DrawZone("SD_S" + IntegerToString(size), zone.lowerLevel, zone.upperLevel, 
                           SupplyZoneColor, "Supply");
            }
         }
      }
   }
   
   Print("Detected ", ArraySize(supplyDemandZones), " S/D zones");
}

//+------------------------------------------------------------------+
//| Check if zone overlaps with existing zones                         |
//+------------------------------------------------------------------+
bool IsZoneOverlapping(ZoneInfo &newZone, ZoneInfo &existingZones[])
{
   for(int i = 0; i < ArraySize(existingZones); i++)
   {
      if(newZone.lowerLevel <= existingZones[i].upperLevel && 
         newZone.upperLevel >= existingZones[i].lowerLevel)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Draw zone on chart                                                 |
//+------------------------------------------------------------------+
void DrawZone(string name, double lower, double upper, color zoneColor, string label)
{
   ObjectDelete(0, name);
   
   datetime startTime = iTime(_Symbol, PERIOD_CURRENT, SR_LookbackBars);
   datetime endTime = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * 50;
   
   if(ObjectCreate(0, name, OBJ_RECTANGLE, 0, startTime, lower, endTime, upper))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TEXT, label);
      
      // Set transparency
      long clr = zoneColor;
      clr = (clr & 0xFFFFFF) | (0x40 << 24); // Add alpha
      ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
   }
   
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Check if price is in or near a valid zone                          |
//+------------------------------------------------------------------+
bool IsPriceInZone(double price, bool lookingForSupport, string &zoneName)
{
   double currentATR = GetCurrentATR();
   double maxDistance = currentATR * MaxDistanceFromZone;
   
   // Check S/R zones
   if(ZoneFilter == ZONE_SR_ONLY || ZoneFilter == ZONE_BOTH)
   {
      for(int i = 0; i < ArraySize(supportResistanceZones); i++)
      {
         ZoneInfo zone = supportResistanceZones[i];
         
         // For bullish divergence, look for support (zone.isSupply = false)
         // For bearish divergence, look for resistance (zone.isSupply = true)
         if(zone.isSupply != lookingForSupport)
         {
            double zoneCenter = (zone.upperLevel + zone.lowerLevel) / 2;
            double distanceToZone = MathAbs(price - zoneCenter);
            
            if(price >= zone.lowerLevel - maxDistance && price <= zone.upperLevel + maxDistance)
            {
               zoneName = zone.isSupply ? "Resistance" : "Support";
               return true;
            }
         }
      }
   }
   
   // Check S/D zones
   if(ZoneFilter == ZONE_SD_ONLY || ZoneFilter == ZONE_BOTH)
   {
      for(int i = 0; i < ArraySize(supplyDemandZones); i++)
      {
         ZoneInfo zone = supplyDemandZones[i];
         
         // For bullish divergence, look for demand (zone.isSupply = false)
         // For bearish divergence, look for supply (zone.isSupply = true)
         if(zone.isSupply != lookingForSupport)
         {
            if(price >= zone.lowerLevel - maxDistance && price <= zone.upperLevel + maxDistance)
            {
               zoneName = zone.isSupply ? "Supply" : "Demand";
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect swing highs and lows using fractal logic                    |
//+------------------------------------------------------------------+
bool FindSwingPoints()
{
   ArrayResize(swingHighs, 0);
   ArrayResize(swingLows, 0);
   
   if(CopyBuffer(rsiHandle, 0, 0, MaxBarsBack + SwingStrength * 2, rsiBuffer) <= 0)
   {
      Print("Error copying RSI buffer: ", GetLastError());
      return false;
   }
   
   // Find swing highs and lows with stricter criteria
   for(int i = SwingStrength; i < MaxBarsBack; i++)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      
      bool isSwingHigh = true;
      bool isSwingLow = true;
      
      // Strict comparison - must be GREATER than (not equal)
      for(int j = 1; j <= SwingStrength; j++)
      {
         if(iHigh(_Symbol, PERIOD_CURRENT, i + j) >= high)
            isSwingHigh = false;
         if(iLow(_Symbol, PERIOD_CURRENT, i + j) <= low)
            isSwingLow = false;
      }
      
      for(int j = 1; j <= SwingStrength; j++)
      {
         if(iHigh(_Symbol, PERIOD_CURRENT, i - j) >= high)
            isSwingHigh = false;
         if(iLow(_Symbol, PERIOD_CURRENT, i - j) <= low)
            isSwingLow = false;
      }
      
      if(isSwingHigh)
      {
         SwingPoint sp;
         sp.bar = i;
         sp.price = high;
         sp.rsi = rsiBuffer[i];
         sp.isHigh = true;
         
         int size = ArraySize(swingHighs);
         ArrayResize(swingHighs, size + 1);
         swingHighs[size] = sp;
      }
      
      if(isSwingLow)
      {
         SwingPoint sp;
         sp.bar = i;
         sp.price = low;
         sp.rsi = rsiBuffer[i];
         sp.isHigh = false;
         
         int size = ArraySize(swingLows);
         ArrayResize(swingLows, size + 1);
         swingLows[size] = sp;
      }
   }
   
   return (ArraySize(swingHighs) >= 2 || ArraySize(swingLows) >= 2);
}

//+------------------------------------------------------------------+
//| Validate divergence with stricter criteria                         |
//+------------------------------------------------------------------+
bool ValidateDivergence(SwingPoint &sp1, SwingPoint &sp2, bool isBullish)
{
   double currentATR = GetCurrentATR();
   double minPriceDiff = MinPriceDivergence;
   if(minPriceDiff == 0) minPriceDiff = currentATR * 0.1; // Increased sensitivity from 0.5 to 0.1 ATR
   
   // Check minimum price difference
   if(minPriceDiff > 0 && MathAbs(sp1.price - sp2.price) < minPriceDiff)
   {
      Print("DEBUG: Price diff too small (", MathAbs(sp1.price - sp2.price), " < ", minPriceDiff, ")");
      return false;
   }
   
   // If minPriceDiff is 0, we still want a tiny difference to avoid flat lines unless intended
   if(minPriceDiff == 0 && MathAbs(sp1.price - sp2.price) < _Point) 
   {
      return false;
   }
   
   // Check minimum RSI difference
   if(MathAbs(sp1.rsi - sp2.rsi) < MinRSIDivergence)
   {
      Print("RSI difference too small: ", MathAbs(sp1.rsi - sp2.rsi), " < ", MinRSIDivergence);
      return false;
   }
   
   // Check RSI extreme levels if required
   if(RequireRSIExtreme)
   {
      if(isBullish)
      {
         // For bullish divergence, RSI should be in/near oversold zone
         if(sp1.rsi > RSI_Oversold + 15 && sp2.rsi > RSI_Oversold + 15)
         {
            Print("RSI not in oversold territory for bullish divergence: RSI1=", sp1.rsi, " RSI2=", sp2.rsi);
            return false;
         }
      }
      else
      {
         // For bearish divergence, RSI should be in/near overbought zone
         if(sp1.rsi < RSI_Overbought - 15 && sp2.rsi < RSI_Overbought - 15)
         {
            Print("RSI not in overbought territory for bearish divergence: RSI1=", sp1.rsi, " RSI2=", sp2.rsi);
            return false;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if trend is aligned with divergence signal                   |
//+------------------------------------------------------------------+
bool IsTrendAligned(bool isBullish)
{
   // In the new MTF logic, EMA 9 cross on M5 serves as trend alignment.
   // Returning true always to avoid double filtering.
   return true;
}

//+------------------------------------------------------------------+
//| Detect RSI Divergence with Zone Validation                         |
//+------------------------------------------------------------------+
bool DetectDivergence()
{
   ZeroMemory(lastDivergence);
   
   if(!FindSwingPoints())
      return false;
   
   bool foundDivergence = false;
   string zoneName = "";
   
   // Check for bearish divergence (using swing highs)
   if(ArraySize(swingHighs) >= 2)
   {
      for(int i = 0; i < ArraySize(swingHighs) - 1 && !foundDivergence; i++)
      {
         SwingPoint sp1 = swingHighs[i];     // Recent swing high
         SwingPoint sp2 = swingHighs[i + 1]; // Previous swing high
         
         int barDiff = sp2.bar - sp1.bar;
         if(barDiff < MinBarsBetween || barDiff > MaxBarsBetween)
            continue;
         
         // Regular Bearish Divergence: Higher high in price, lower high in RSI
         if(sp1.price > sp2.price && sp1.rsi < sp2.rsi)
         {
            if(DivergenceFilter == DIV_ALL || DivergenceFilter == DIV_REGULAR_ONLY)
            {
               if(!ValidateDivergence(sp1, sp2, false))
                  continue;
               
               // Check if in valid zone (looking for resistance/supply)
               bool inZone = (ZoneFilter == ZONE_NONE) || IsPriceInZone(sp1.price, false, zoneName);
               
               lastDivergence.detected = true;
               lastDivergence.isBullish = false;
               lastDivergence.isRegular = true;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.rsi1 = sp1.rsi;
               lastDivergence.rsi2 = sp2.rsi;
               lastDivergence.isInZone = inZone;
               lastDivergence.zoneName = zoneName;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLine("DIV_BEAR_REG", sp1.bar, sp2.bar, sp1.price, sp2.price, BearishDivColor);
               
               Print("Regular Bearish Divergence: Price ", sp2.price, " -> ", sp1.price, 
                     " | RSI ", sp2.rsi, " -> ", sp1.rsi, " | In Zone: ", inZone ? zoneName : "NO");
               
               if(inZone) foundDivergence = true;
            }
         }
         
         // Hidden Bearish Divergence: Lower high in price, higher high in RSI
         if(!foundDivergence && sp1.price < sp2.price && sp1.rsi > sp2.rsi)
         {
            if(DivergenceFilter == DIV_ALL || DivergenceFilter == DIV_HIDDEN_ONLY)
            {
               if(!ValidateDivergence(sp1, sp2, false))
                  continue;
               
               bool inZone = (ZoneFilter == ZONE_NONE) || IsPriceInZone(sp1.price, false, zoneName);
               
               lastDivergence.detected = true;
               lastDivergence.isBullish = false;
               lastDivergence.isHidden = true;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.rsi1 = sp1.rsi;
               lastDivergence.rsi2 = sp2.rsi;
               lastDivergence.isInZone = inZone;
               lastDivergence.zoneName = zoneName;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLine("DIV_BEAR_HID", sp1.bar, sp2.bar, sp1.price, sp2.price, BearishDivColor);
               
               Print("Hidden Bearish Divergence: Price ", sp2.price, " -> ", sp1.price, 
                     " | RSI ", sp2.rsi, " -> ", sp1.rsi, " | In Zone: ", inZone ? zoneName : "NO");
               
               if(inZone) foundDivergence = true;
            }
         }
      }
   }
   
   // Check for bullish divergence (using swing lows)
   if(!foundDivergence && ArraySize(swingLows) >= 2)
   {
      for(int i = 0; i < ArraySize(swingLows) - 1 && !foundDivergence; i++)
      {
         SwingPoint sp1 = swingLows[i];     // Recent swing low
         SwingPoint sp2 = swingLows[i + 1]; // Previous swing low
         
         int barDiff = sp2.bar - sp1.bar;
         if(barDiff < MinBarsBetween || barDiff > MaxBarsBetween)
            continue;
         
         // Regular Bullish Divergence: Lower low in price, higher low in RSI
         if(sp1.price < sp2.price && sp1.rsi > sp2.rsi)
         {
            if(DivergenceFilter == DIV_ALL || DivergenceFilter == DIV_REGULAR_ONLY)
            {
               if(!ValidateDivergence(sp1, sp2, true))
                  continue;
               
               // Check if in valid zone (looking for support/demand)
               bool inZone = (ZoneFilter == ZONE_NONE) || IsPriceInZone(sp1.price, true, zoneName);
               
               lastDivergence.detected = true;
               lastDivergence.isBullish = true;
               lastDivergence.isRegular = true;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.rsi1 = sp1.rsi;
               lastDivergence.rsi2 = sp2.rsi;
               lastDivergence.isInZone = inZone;
               lastDivergence.zoneName = zoneName;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLine("DIV_BULL_REG", sp1.bar, sp2.bar, sp1.price, sp2.price, BullishDivColor);
               
               Print("Regular Bullish Divergence: Price ", sp2.price, " -> ", sp1.price, 
                     " | RSI ", sp2.rsi, " -> ", sp1.rsi, " | In Zone: ", inZone ? zoneName : "NO");
               
               if(inZone) foundDivergence = true;
            }
         }
         
         // Hidden Bullish Divergence: Higher low in price, lower low in RSI
         if(!foundDivergence && sp1.price > sp2.price && sp1.rsi < sp2.rsi)
         {
            if(DivergenceFilter == DIV_ALL || DivergenceFilter == DIV_HIDDEN_ONLY)
            {
               if(!ValidateDivergence(sp1, sp2, true))
                  continue;
               
               bool inZone = (ZoneFilter == ZONE_NONE) || IsPriceInZone(sp1.price, true, zoneName);
               
               lastDivergence.detected = true;
               lastDivergence.isBullish = true;
               lastDivergence.isHidden = true;
               lastDivergence.priceBar1 = sp1.bar;
               lastDivergence.priceBar2 = sp2.bar;
               lastDivergence.price1 = sp1.price;
               lastDivergence.price2 = sp2.price;
               lastDivergence.rsi1 = sp1.rsi;
               lastDivergence.rsi2 = sp2.rsi;
               lastDivergence.isInZone = inZone;
               lastDivergence.zoneName = zoneName;
               
               if(ShowDivergenceLines)
                  DrawDivergenceLine("DIV_BULL_HID", sp1.bar, sp2.bar, sp1.price, sp2.price, BullishDivColor);
               
               Print("Hidden Bullish Divergence: Price ", sp2.price, " -> ", sp1.price, 
                     " | RSI ", sp2.rsi, " -> ", sp1.rsi, " | In Zone: ", inZone ? zoneName : "NO");
               
               if(inZone) foundDivergence = true;
            }
         }
      }
   }
   
   return foundDivergence;
}

//+------------------------------------------------------------------+
//| Draw divergence line on chart                                      |
//+------------------------------------------------------------------+
void DrawDivergenceLine(string name, int bar1, int bar2, double price1, double price2, color lineColor)
{
   string objName = name + "_" + TimeToString(TimeCurrent());
   
   datetime time1 = iTime(_Symbol, PERIOD_CURRENT, bar1);
   datetime time2 = iTime(_Symbol, PERIOD_CURRENT, bar2);
   
   ObjectDelete(0, objName);
   
   if(ObjectCreate(0, objName, OBJ_TREND, 0, time2, price2, time1, price1))
   {
      ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, LineWidth);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, LineStyle);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   }
   
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Check if volatility is acceptable                                  |
//+------------------------------------------------------------------+
bool IsVolatilityAcceptable()
{
   if(CopyBuffer(atrHandle, 0, 0, 2, atrBuffer) <= 0)
      return true;
   
   double currentATR = atrBuffer[0];
   
   double atrArray[];
   ArraySetAsSeries(atrArray, true);
   
   if(CopyBuffer(atrHandle, 0, 0, 50, atrArray) <= 0)
      return true;
   
   double avgATR = 0;
   for(int i = 0; i < 50; i++)
      avgATR += atrArray[i];
   avgATR /= 50;
   
   double threshold = ATR_VolatilityThreshold;
   if(threshold == 0)
      threshold = avgATR * VolatilityMultiplier;
   
   if(currentATR > threshold)
   {
      Print("High volatility: ATR ", currentATR, " > ", threshold);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                   |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPips)
{
   if(RiskPercent <= 0)
      return NormalizeLot(LotSize);
   
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (RiskPercent / 100.0);
   
   double pipValue = GetPipValue();
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tickSize == 0 || tickValue == 0)
      return NormalizeLot(LotSize);
   
   double pipValuePerLot = (pipValue / tickSize) * tickValue;
   double lots = riskAmount / (stopLossPips * pipValuePerLot);
   
   return NormalizeLot(lots);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                                 |
//+------------------------------------------------------------------+
double NormalizeLot(double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathMax(minLot, lots);
   lots = MathMin(maxLot, lots);
   lots = MathRound(lots / lotStep) * lotStep;
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Calculate stop loss                                                |
//+------------------------------------------------------------------+
double CalculateStopLoss(bool isBuy)
{
   double sl = 0;
   double price = isBuy ? symbolInfo.Ask() : symbolInfo.Bid();
   double pipValue = GetPipValue();
   
   if(StopLossType == SL_FIXED_PIPS)
   {
      sl = FixedStopLossPips * pipValue;
   }
   else
   {
      if(CopyBuffer(atrHandle, 0, 0, 2, atrBuffer) <= 0)
         sl = FixedStopLossPips * pipValue;
      else
         sl = atrBuffer[1] * ATR_Multiplier;
   }
   
   // Place SL beyond the divergence swing point for better protection
   // Place SL beyond the divergence swing point for better protection
   double swingLevel = lastDivergence.price1;
   double atrBuffer_sl = GetCurrentATR() * 0.5;
   
   if(isBuy)
   {
      double slFromSwing = swingLevel - atrBuffer_sl;
      double slFromATR = price - sl;
      double finalSL = MathMin(slFromSwing, slFromATR);
      return NormalizeDouble(finalSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
   }
   else
   {
      double slFromSwing = swingLevel + atrBuffer_sl;
      double slFromATR = price + sl;
      double finalSL = MathMax(slFromSwing, slFromATR);
      return NormalizeDouble(finalSL, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
   }
}

//+------------------------------------------------------------------+
//| Calculate take profit                                              |
//+------------------------------------------------------------------+
double CalculateTakeProfit(bool isBuy, double entryPrice, double stopLoss)
{
   double slDistance = MathAbs(entryPrice - stopLoss);
   double tpDistance = slDistance * RiskRewardRatio;
   
   if(isBuy)
      return NormalizeDouble(entryPrice + tpDistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
   else
      return NormalizeDouble(entryPrice - tpDistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
}

// DEPRECATED ExecuteTrade function removed for stability. 
// Using ExecuteBufferedTrade() exclusively.

//+------------------------------------------------------------------+
//| ChartEvent function                                                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Can be extended for GUI controls
}

//+------------------------------------------------------------------+
//| Trade Transaction Event                                            |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         Print("Deal: ", trans.deal, " | ", EnumToString(trans.deal_type), 
               " | Price: ", trans.price, " | Vol: ", trans.volume);
      }
   }
}

//+------------------------------------------------------------------+
//| Tester function                                                    |
//+------------------------------------------------------------------+
double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double totalTrades = TesterStatistics(STAT_TRADES);
   double winRate = TesterStatistics(STAT_PROFIT_TRADES) / MathMax(1, totalTrades) * 100;
   double drawdown = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   
   if(drawdown == 0) drawdown = 0.01;
   double criterion = (profit * winRate) / (drawdown * 100);
   
   return criterion;
}
//+------------------------------------------------------------------+
