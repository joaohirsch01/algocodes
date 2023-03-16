//+------------------------------------------------------------------+
//|                                                     MA_Slope.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Moving Average Slope indicator"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot MASlope
#property indicator_label1  "MASlope"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGreen,clrRed,clrDarkGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- input parameters
input uint                 InpPeriod         =  50;            // Period
input ENUM_MA_METHOD       InpMethod         =  MODE_SMA;      // Method
input ENUM_APPLIED_PRICE   InpAppliedPrice   =  PRICE_CLOSE;   // Applied price
input double               InpSlope          =  0.0;           // Slope
input uint                 InpLength         =  1;             // Slope length
//--- indicator buffers
double         BufferMASlope[];
double         BufferColors[];
//--- global variables
double         slope;
int            period;
int            length;
int            handle_ma;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set global variables
   period=int(InpPeriod<1 ? 1 : InpPeriod);
   length=int(InpLength<1 ? 1 : InpLength);
   slope=(InpSlope<0 ? 0 : InpSlope);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferMASlope,INDICATOR_DATA);
   SetIndexBuffer(1,BufferColors,INDICATOR_COLOR_INDEX);
//--- setting indicator parameters
   IndicatorSetString(INDICATOR_SHORTNAME,MethodToString(InpMethod)+" Slope ("+(string)period+","+DoubleToString(slope,1)+","+(string)length+")");
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(BufferMASlope,true);
   ArraySetAsSeries(BufferColors,true);
//--- create handles
   ResetLastError();
   handle_ma=iMA(NULL,PERIOD_CURRENT,period,0,InpMethod,InpAppliedPrice);
   if(handle_ma==INVALID_HANDLE)
     {
      Print("The iMA(",(string)period,") object was not created: Error ",GetLastError());
      return INIT_FAILED;
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
//--- Проверка количества доступных баров
   if(rates_total<fmax(length,4) || Point()==0) return 0;
//--- Проверка и расчёт количества просчитываемых баров
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-length-1;
      ArrayInitialize(BufferMASlope,EMPTY_VALUE);
      ArrayInitialize(BufferColors,2);
     }
//--- Подготовка данных
   int count=(limit>1 ? rates_total : 1);
   int copied=CopyBuffer(handle_ma,0,0,count,BufferMASlope);
   if(copied!=count) return 0;

//--- Расчёт индикатора
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      double Sl=(BufferMASlope[i]-BufferMASlope[i+length])/Point();
      BufferColors[i]=(Sl>slope ? 0 : Sl<-slope ? 1 : 2);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Возвращает наименование метода МА                                |
//+------------------------------------------------------------------+
string MethodToString(ENUM_MA_METHOD method)
  {
   return StringSubstr(EnumToString(method),5);
  }
//+------------------------------------------------------------------+
