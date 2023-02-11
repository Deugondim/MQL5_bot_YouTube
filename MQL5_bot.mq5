
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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
