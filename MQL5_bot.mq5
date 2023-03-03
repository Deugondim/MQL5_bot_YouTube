
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

//Store Position Ticket Number
ulong    TicketNumber = 0;


//Risk Metrics
input bool  TslCheck =true; //USe Trailing Stop Loss?
input bool  RiskCompounding = false; // Use Compounded Risk Method?
double   StartingEquity = 0.0; //Starting Equity
double  CurrentEquityRisk = 0.0; //Equity that will be risked per trade
input double   MaxLossPrc = 0.02; //PErcent risk per trade
input double   ATRProfitMulti = 2.0; //ATR Profit Multiple
input double   ATRLossMulti = 1.0; //ATR Loss Multiple

//Macd Variables and Handle
int HandleMacd;
int MacdFast = 12;
int MacdSlow = 26;
int MacdSignal = 9;

//Ema Variables and Handle
int HandleEma;
int EmaPeriod = 100;

//ATR Handle and Variables
int HandleATR;
int AtrPeriod = 14;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // Declare magic number for all trades
   Trade = new CTrade();
   Trade.SetExpertMagicNumber(InpMagicNumber);

    //Store starting equity onInit
   StartingEquity  = AccountInfoDouble(ACCOUNT_EQUITY);

   //Set up handle for macd indicator oninit
    HandleMacd = iMACD(Symbol(),Period(),MacdFast,MacSlow,MacdSignal,InpAppliedPrice);
    Print("Handle for Macd /", Symbol(), " / ", EnumToString(Period()),"successfully created") ;
    
    //Set up handle for Ema indicator oninit
    HandleEma = iMA(Symbol(),Period(),EmaPeriod,0,MODE_EMA,InpAppliedPrice);
    Print("Handle for Ema /", Symbol(), " / ", EnumToString(Period()),"successfully created") ;

    //Set up handle for ATR indicator oninit
    HandleATR = iATR(Symbol(),Period(),AtrPeriod);
    Print("Handle for ATR /", Symbol(), " / ", EnumToString(Period()),"successfully created") ;

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
   IndicatorRelease(HandleATR);
   IndicatorRelease(HandleMacd);
   IndicatorRelease(HandleEma);
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
   
   //Check if position is still open. If not open, return 0
   if(!PositionSelectByTicket(TicketNumber)){
      TicketNumber = 0;
   };
   
   indicatorMetrics = ""; // Initiate String for indicatorMetrics Variable. This will reset variable each time OnTick function runs
   StringConcatenate(indicatorMetrics,Symbol() ," | Last Processed: ",TimeLastTickProcessed, " | Open Ticket ",TicketNumber);
   
   
   //---Strategy Trigger ATR---// 
   double CurrentATR = GetATRValue(); // Gets ATR value double using custom function- convert double to string as per symbol sigits
   StringConcatenate(indicatorMetrics, indicatorMetrics, " | ATR: ", CurrentATR);//Concatenate indicator values to output comment for user

   //---Strategy Trigger MACD---//
   string OpenSignalMacd = GetMacdOpenSignal(); //Variable will return Long or Sort Bias only on trigger/cross event
   StringConcatenate(indicatorMetrics, indicatorMetrics, " | MACD Bias: ", OpenSignalMacd);//Concatenate indicator values to output comment for user
   
   //---Strategy Trigger Ema---// 
   string OpenSignalEma = GetEmaOpenSignal(); // VAriable will return long or short bias if close is above or below EMA
   StringConcatenate(indicatorMetrics, indicatorMetrics, " | Ema Bias: ", OpenSignalEma);//Concatenate indicator values to output comment for user
   
   
   
    //---Enter Trades---/
   if(OpenSignalMacd == "Long" && OpenSignalEma == "Long" ){
   
      TicketNumber = ProcessTradeOpen(ORDER_TYPE_BUY,CurrentATR) ;
   
   }else if(OpenSignalMacd == "Short" && OpenSignalEma == "Short" ){
      
      TicketNumber = ProcessTradeOpen(ORDER_TYPE_SELL,CurrentATR);
   }

   //Adjust Open Positions - Trailing Stop Loss
   if(TslCheck == true){
      AdjustTsl(TicketNumber, CurrentATR, ATRLossMulti);
   }

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

  //Submit MAcd Long and Short Trades
   if(priorMacd <= priorSignal && currentMacd>currentSignal && currentMacd < 0 && currentSignal < 0)
   {
      return  ("Long");
   }else if(priorMacd >= priorSignal && currentMacd < currentSignal && currentMacd > 0 && currentSignal > 0)
   {
      return  ("Short");
   }else
   {
      return  ("No Trade");
   }

}

//Process open trades for buy and sell
 
ulong ProcessTradeOpen(ENUM_ORDER_TYPE orderType, double CurrentATR)
 {
 
   //Set symbol stirng and variables
   string   CurrentSymbol = Symbol();
   double   price =0;
   double   stopLossPrice =0;
   double   takeProfitPrice=0;
   
   //Get price, sl, tp for open and close orders
   if(orderType == ORDER_TYPE_BUY)
   {
      
      price = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK), Digits());
      stopLossPrice = NormalizeDouble(price - CurrentATR*ATRLossMulti,Digits());
      takeProfitPrice = NormalizeDouble(price + CurrentATR*ATRProfitMulti,Digits());
      
   }else if(orderType == ORDER_TYPE_SELL)
      {
     
      price = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_BID), Digits());
      stopLossPrice = NormalizeDouble(price + CurrentATR*ATRLossMulti,Digits());
      takeProfitPrice = NormalizeDouble(price - CurrentATR*ATRProfitMulti,Digits());
     
      }
      
      // get lot size
      double LotSize = OptimalLotSize(CurrentSymbol,price,stopLossPrice);
      
      //Execute trades
      Trade.PositionClose(CurrentSymbol);
      Trade.PositionOpen(CurrentSymbol,orderType,LotSize,price,stopLossPrice,takeProfitPrice,InpTradeComment);
      
      //Get Position Ticket 
      ulong   Ticket = PositionGetTicket(0);


      //Add in any error handling
      Print("Trade Processed For ",CurrentSymbol, " Order Type ", orderType," Lot Size ",LotSize," Ticket ", Ticket);
      return(Ticket);
 } 


   //Finds the optimal lot size for the trade
   double OptimalLotSize(string CurrentSymbol, double EntryPrice, double StopLoss){

       //Set symbol string and calculate point value
      double TickSize      = SymbolInfoDouble(CurrentSymbol,SYMBOL_TRADE_TICK_SIZE);
      double TickValue     = SymbolInfoDouble(CurrentSymbol,SYMBOL_TRADE_TICK_VALUE);
      if(SymbolInfoInteger(CurrentSymbol,SYMBOL_DIGITS) <= 3)
         TickValue = TickValue/100;
      double PointAmount   = SymbolInfoDouble(CurrentSymbol,SYMBOL_POINT);
      double TicksPerPoint = TickSize/PointAmount;
      double PointValue    = TickValue/TicksPerPoint;

      //Calculate risk based off entry and stop loss level by pips
      double RiskPoints = MathAbs((EntryPrice - StopLoss)/TickSize);
     
      //Set risk model - Fixed or compounding
      if(RiskCompounding == true)
         CurrentEquityRisk = AccountInfoDouble(ACCOUNT_EQUITY);
      else
         CurrentEquityRisk = StartingEquity; 

      //Calculate total risk amount in dollars
      double RiskAmount = CurrentEquityRisk * MaxLossPrc;

      //Calculate lot size
      double RiskLots   = NormalizeDouble(RiskAmount/(RiskPoints*PointValue),2);

      //Print values in Journal to check if operating correctly
      PrintFormat("TickSize=%f,TickValue=%f,PointAmount=%f,TicksPerPoint=%f,PointValue=%f,",
                     TickSize,TickValue,PointAmount,TicksPerPoint,PointValue);   
      PrintFormat("EntryPrice=%f,StopLoss=%f,RiskPoints=%f,RiskAmount=%f,RiskLots=%f,",
                     EntryPrice,StopLoss,RiskPoints,RiskAmount,RiskLots);   

      //Return optimal lot size
      return RiskLots;

   }




 //Custom function that returns long and short signals base off EMA and Close Prices
 string GetEmaOpenSignal()
 {
    //Set symbol string and indicator buffers
   string   CurrentSymbol = Symbol();
   const int StartCandle = 0;
   const int RequiredCandles = 2; //How many candles are required to be stored in Expert - (current confirmed, not confirmed)
   //Indicator Variables and Buffers
   const int IndexEma = 0; //Ema Line
   double   BufferEma[];  //(current confirmed, not confirmed)
   
   //Define Macd and Signal lines, from not confimed candle 0, for 3 candles, and stores results
   bool  fillEma = CopyBuffer(HandleEma,IndexEma,StartCandle,RequiredCandles,BufferEma);
   if(fillEma==false) 
   {
   return "Buffer not full"; //If buffers are not completely filled, return to end onTick
   }
   
   //Gets the current confirmed Ema Value
   double   currentEma = NormalizeDouble(BufferEma[1],10);
   double   currentClose = NormalizeDouble(iClose(Symbol(),Period(),0),10);
   
   
   //Submit Ema Long and Short Trades
   if(currentClose>currentEma)
   {
      return  ("Long");
   }else if(currentClose<currentEma)
   {
      return  ("Short");
   }else
   {
      return  ("No Trade");
   }
 }

    // Custom function to get ATR Value
   double GetATRValue(){
   //Set symbol string and indicator buffers
   string   CurrentSymbol = Symbol();
   const int   StartCandle = 0;
   const int   IndexATR = 0; //ATR Value
   const int RequiredCandles = 3; //How many candles are required to be stored in Expert - (prior, current confirmed, not confirmed)
   double   BufferATR[];   //Capture 3 candles for ATR [0,1,2] 
   
   // Populate buffers for ATR Value; check erros
   bool FillATR = CopyBuffer(HandleATR,IndexATR,StartCandle,RequiredCandles,BufferATR); // Copy buffe uses oldest as 0 (reversed)
   if (FillATR == false)return(0);

   //Find ATR for CAndle 1 only
   double CurrentATR = NormalizeDouble(BufferATR[1],5);

   //Return ATR value
   return(CurrentATR);
   
   }


   void  AdjustTsl(ulong Ticket,double CurrentATR, double ATRMulti){

    //Set symbol string and variables
   string CurrentSymbol   = Symbol();
   double Price           = 0.0;
   double OptimalStopLoss = 0.0;  

   //Check correct ticket number is selected for further position data to be stored. Return if error.
   if (!PositionSelectByTicket(Ticket))
      return;

   //Store position data variables
   ulong  PositionDirection = PositionGetInteger(POSITION_TYPE);
   double CurrentStopLoss   = PositionGetDouble(POSITION_SL);
   double CurrentTakeProfit = PositionGetDouble(POSITION_TP);
   
   //Check if position direction is long 
   if (PositionDirection==POSITION_TYPE_BUY)
   {
      //Get optimal stop loss value
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK), Digits());
      OptimalStopLoss = NormalizeDouble(Price - CurrentATR*ATRMulti, Digits());
      
      //Check if optimal stop loss is greater than current stop loss. If TRUE, adjust stop loss
      if(OptimalStopLoss > CurrentStopLoss)
      {
         Trade.PositionModify(Ticket,OptimalStopLoss,CurrentTakeProfit);
         Print("Ticket ", Ticket, " for symbol ", CurrentSymbol," stop loss adjusted to ", OptimalStopLoss);
      }

      //Return once complete
      return;
   } 

   //Check if position direction is short 
   if (PositionDirection==POSITION_TYPE_SELL)
   {
      //Get optimal stop loss value
      Price           = NormalizeDouble(SymbolInfoDouble(CurrentSymbol, SYMBOL_BID), Digits());
      OptimalStopLoss = NormalizeDouble(Price + CurrentATR*ATRMulti, Digits());

      //Check if optimal stop loss is less than current stop loss. If TRUE, adjust stop loss
      if(OptimalStopLoss < CurrentStopLoss)
      {
         Trade.PositionModify(Ticket,OptimalStopLoss,CurrentTakeProfit);
         Print("Ticket ", Ticket, " for symbol ", CurrentSymbol," stop loss adjusted to ", OptimalStopLoss);
      }
      
      //Return once complete
      return;
   } 



   }