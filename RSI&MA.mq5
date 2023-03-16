//+------------------------------------------------------------------+
//|                                                 RSIOnMAOnRSI.mq5 |
//|                              Copyright © 2020, Vladimir Karputov |
//|                     https://www.mql5.com/ru/market/product/43516 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2020, Vladimir Karputov"
#property link      "https://www.mql5.com/ru/market/product/43516"
#property version   "1.000"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot RSI
#property indicator_label1  "RSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkViolet
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot RSIOnMA
#property indicator_label2  "RSIOnMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrangeRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot MAOnRSI
#property indicator_label3  "MAOnRSI"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int                  Inp_MA_ma_period     = 21;          // MA: averaging period
input int                  Inp_MA_ma_shift      = 0;           // MA: horizontal shift
input ENUM_MA_METHOD       Inp_MA_ma_method     = MODE_SMA;    // MA: smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_applied_price = PRICE_CLOSE; // MA: type of price
input int                  Inp_RSI_ma_period    = 14;          // RSI: averaging period
input color                Inp_RSI_Level_Color  = clrDimGray;  // Color line Levels
input double               Inp_RSI_Level_Down   = 20.0;        // Value Level Down
input double               Inp_RSI_Level_Middle = 50.0;        // Value Level Middle
input double               Inp_RSI_Level_Up     = 80.0;        // Value Level Up
//--- indicator buffers
double   RSIBuffer[];
double   RSIOnMABuffer[];
double   MAOnRSIBuffer[];
//---
int      handle_iMA;                            // variable for storing the handle of the iMA indicator
int      handle_iRSI;                           // variable for storing the handle of the iRSI indicator
int      handle_iRSIOnMA;                       // variable for storing the handle of the iRSI indicator
int      handle_iMAOnRSI;                       // variable for storing the handle of the iRSI indicator
int      bars_calculated=0;                     // we will keep the number of values in the Relative Strength Index indicator
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,RSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,RSIOnMABuffer,INDICATOR_DATA);
   SetIndexBuffer(2,MAOnRSIBuffer,INDICATOR_DATA);
//--- custom parameters
   IndicatorSetInteger(INDICATOR_LEVELS,3);

   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,Inp_RSI_Level_Color);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,Inp_RSI_Level_Color);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,Inp_RSI_Level_Color);

   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASH);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,2,STYLE_DASH);

   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,Inp_RSI_Level_Down);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,Inp_RSI_Level_Middle);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,Inp_RSI_Level_Up);
//--- set maximum and minimum for subwindow
   IndicatorSetDouble(INDICATOR_MINIMUM,0);
   IndicatorSetDouble(INDICATOR_MAXIMUM,100);
//---

//--- create handle of the indicator iMA
   handle_iMA=iMA(Symbol(),Period(),Inp_MA_ma_period,Inp_MA_ma_shift,
                  Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created
   if(handle_iMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(Symbol(),Period(),Inp_RSI_ma_period,Inp_MA_applied_price);
//--- if the handle is not created
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSIOnMA=iRSI(Symbol(),Period(),Inp_RSI_ma_period,handle_iMA);
//--- if the handle is not created
   if(handle_iRSIOnMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI On MA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMAOnRSI=iMA(Symbol(),Period(),Inp_MA_ma_period,Inp_MA_ma_shift,
                       Inp_MA_ma_method,handle_iRSI);
//--- if the handle is not created
   if(handle_iMAOnRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA On RSI indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- number of values copied from the iRSI indicator
   int values_to_copy;
//--- determine the number of values calculated in the indicator
   int calculated=BarsCalculated(handle_iRSI);
   if(calculated<=0)
     {
      PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
      return(0);
     }
//--- if it is the first start of calculation of the indicator or if the number of values in the iRSI indicator changed
//---or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history)
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
     {
      //--- if the iRSIBuffer array is greater than the number of values in the iRSI indicator for symbol/period, then we don't copy everything
      //--- otherwise, we copy less than the size of indicator buffers
      if(calculated>rates_total)
         values_to_copy=rates_total;
      else
         values_to_copy=calculated;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      //--- for calculation not more than one bar is added
      values_to_copy=(rates_total-prev_calculated)+1;
     }
//--- fill the array with values of the iRSI indicator
//--- if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
   if(!FillArrayFromBuffer(RSIBuffer,handle_iRSI,values_to_copy))
      return(0);
//--- fill the array with values of the iRSI indicator
//--- if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
   if(!FillArrayFromBuffer(RSIOnMABuffer,handle_iRSIOnMA,values_to_copy))
      return(0);
//--- fill the iMABuffer array with values of the Moving Average indicator
//--- if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
   if(!FillArrayFromBuffer(MAOnRSIBuffer,Inp_MA_ma_shift,handle_iMAOnRSI,values_to_copy))
      return(0);
//--- memorize the number of values in the Relative Strength Index indicator
   bars_calculated=calculated;
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Filling indicator buffers from the iRSI indicator                |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &rsi_buffer[],  // indicator buffer of Relative Strength Index values
                         int ind_handle,        // handle of the iRSI indicator
                         int amount             // number of copied values
                        )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iRSIBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_handle,0,0,amount,rsi_buffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
//--- everything is fine
   return(true);
  }
//+------------------------------------------------------------------+
//| Filling indicator buffers from the MA indicator                  |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &values[],   // indicator buffer of Moving Average values
                         int shift,          // shift
                         int ind_handle,     // handle of the iMA indicator
                         int amount          // number of copied values
                        )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_handle,0,-shift,amount,values)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
//--- everything is fine
   return(true);
  }
//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_iMA!=INVALID_HANDLE)
      IndicatorRelease(handle_iMA);
   if(handle_iRSI!=INVALID_HANDLE)
      IndicatorRelease(handle_iRSI);
   if(handle_iRSIOnMA!=INVALID_HANDLE)
      IndicatorRelease(handle_iRSIOnMA);
   if(handle_iMAOnRSI!=INVALID_HANDLE)
      IndicatorRelease(handle_iMAOnRSI);
  }
//+------------------------------------------------------------------+
