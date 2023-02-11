
//+------------------------------------------------------------------+
//|                                            MQL5YoutubeSeries.mq5 |
//|                                                     André Ludwig |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "André Ludwig"
#property link      "https://www.mql5.com"
#property version   "1.00"

//Include Functions
#include <Trade\Trade.mqh> //Include MQL trade object functions
CTrade   *Trade;

//Setup Variables
input int                  InpMagicNumber = 2000001;     //Unique identifier for this expert advisor 
input string               InpTradeComment = __FILE__;   //Optional comment for trades
input ENUM_APPLIED_PRICE   InpAppliedPrice = PRICE_CLOSE;//Applied price for indicators  

//Global Variables
string   indicatorMetrics = ""; // Initiate String for indicatorMetrics Variable. This will reset variable each time OnTick function runs
int TicksRecievedCount =0; // Counts the number of ticks from oninit function
int TicksProcessedCount =0; // Counts the number of ticks processed from oninit function based off candle opens only
static datetime TimeLastTickProcessed; //Stores the last time a tick  was processed based off cafle opens only

//Macd Variables and Handle
int HandleMacd;
int MacdFast = 12;
int MacSlow = 26;
int MacdSignal = 9;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // Declare magic number for all trades
   Trade = new CTrade();
   Trade.SetExpertMagicNumber(InpMagicNumber);

   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
