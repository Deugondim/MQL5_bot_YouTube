
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

   //Set up handle for macd indicator oninit
    HandleMacd = iMACD(Symbol(),Period(),MacdFast,MacSlow,MacdSignal,InpAppliedPrice);
    Print("Handle for Macd /", Symbol(), " / ", EnumToString(Period()),"successfully created") ;

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  //Remove indicator handle from Metatrader Cache
   IndicatorRelease(HandleMacd);
   IndicatorRelease(HandleEma);
   IndicatorRelease(HandleATR);
   Print("Released"); 

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
     
   //Declare Variables
   TicksRecievedCount++; //Counts the number of ticks recieved

   //Checks for new candle
   bool IsNewCandle = false;
   if(TimeLastTickProcessed != iTime(Symbol(), Period(),0))   
   {
      IsNewCandle = true;
      TimeLastTickProcessed = iTime(Symbol(), Period(),0);
   }
   
   if(IsNewCandle == true)
   {
   
   TicksProcessedCount++; // count the number of ticks processed
   indicatorMetrics = ""; // Initiate String for indicatorMetrics Variable. This will reset variable each time OnTick function runs
   StringConcatenate(indicatorMetrics,Symbol() ," | Last Processed: ",TimeLastTickProcessed);
   
   
   //---Strategy Trigger MACD---//
   string OpenSignalMacd = GetMacdOpenSignal(); //Variable will return Long or Sort Bias only on trigger/cross event
   StringConcatenate(indicatorMetrics, indicatorMetrics, " | MACD Bias: ", OpenSignalMacd);//Concatenate indicator values to output comment for user
   
  
 
   }
   
   
   Comment("\n \rExpert:",InpMagicNumber, "\n\r",
   "MT5 Server Time: ", TimeCurrent(), "\n\r",
   "Ticks Recieved: ",TicksRecievedCount, "\n\r",
   "Ticks Processed: ",TicksProcessedCount, "\n\r\n\r",
   "Symbols Traded: \n\r",
   indicatorMetrics);


  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| /Custom functions/                                               |
//+------------------------------------------------------------------+
  
 // Custom function to get MACD signals
  
  
string GetMacdOpenSignal()
{   
   //Set symbol string and indicator buffers
   string   CurrentSymbol = Symbol();
   const int StartCandle = 0;
   const int RequiredCandles = 3; //How many candles are required to be stored in Expert - (prior, current confirmed, not confirmed)
   //Indicator Variables and Buffers
   const int IndexMacd = 0; //Macd Line
   const int IndexSignal = 1;
   double   BufferMacd[];  //(prior, current confirmed, not confirmed)
   double   BufferSignal[];   //(prior, current confirmed, not confirmed)
   
   //Define Macd and Signal lines, from not confimed candle 0, for 3 candles, and stores results
   bool  fillMacd = CopyBuffer(HandleMacd,IndexMacd,StartCandle,RequiredCandles,BufferMacd);
   bool  fillSignal = CopyBuffer(HandleMacd,IndexSignal,StartCandle,RequiredCandles,BufferSignal);
   if(fillMacd==false || fillSignal==false) 
   {
   return "Buffer not full"; //If buffers are not completely filled, return to end onTick
   }
   //Find required Macd signal lines and normalize to 10 places to prevent rounding errors
   double   currentMacd = NormalizeDouble(BufferMacd[1],10);
   double   currentSignal = NormalizeDouble(BufferSignal[1],10);
   double   priorMacd = NormalizeDouble(BufferMacd[0],10);
   double   priorSignal = NormalizeDouble(BufferSignal[0],10);
   

}