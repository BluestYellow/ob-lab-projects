//+------------------------------------------------------------------+
//| macro                                                            |
//+------------------------------------------------------------------+
#property indicator_buffers 3
#property indicator_separate_window
#property strict
#include "ob-lab-lib.mqh"

// --- var & const ---
static int g_indicatorBuffers = 0;
static int g_zoom = 0;

// --- inputs do usuário ---
input int inputBars = 300;

// --- objetos ---
CIndicatorDataProcessor* candleRangeData = new CIndicatorDataProcessor();
CIndicatorBuffers* candleRangeBuffer = new CIndicatorBuffers();
CIndicatorBuffers* notableBullCandleRangeBuffer = new CIndicatorBuffers();
CIndicatorBuffers* notableBearCandleRangeBuffer = new CIndicatorBuffers();

//+------------------------------------------------------------------+
//| deinicialization                                                 |
//+------------------------------------------------------------------+
void deinit() {
   delete candleRangeData;
   delete candleRangeBuffer;
   delete notableBullCandleRangeBuffer;
   delete notableBearCandleRangeBuffer;
}

//+------------------------------------------------------------------+
//| inicialization                                                   |
//+------------------------------------------------------------------+
int init() {
   // inicializador dos objetos
   candleRangeData.initialize(inputBars, true);
   candleRangeBuffer.initialize(g_indicatorBuffers, "CR[histogram]");
   notableBullCandleRangeBuffer.initialize(g_indicatorBuffers, "NCRG[histogram]");
   notableBearCandleRangeBuffer.initialize(g_indicatorBuffers, "NCRR[histogram]");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| calculate                                                        |
//+------------------------------------------------------------------+
int start() {
   const int ic = IndicatorCounted(); if (ic <= 0) return(-1);
   const int limit = MathMin(ic, inputBars);
   
   // Define tamanho do histograma
   int histogramWidth = 0;
   const int zoom = (int)ChartGetInteger(0, CHART_SCALE);
   if (g_zoom != zoom) {
      switch (zoom) {
         case (5): histogramWidth = 16; break;
         case (4): histogramWidth = 08; break;
         case (3): histogramWidth = 04; break;
         case (2): histogramWidth = 02; break;
         case (1): histogramWidth = 01; break;
         default: histogramWidth = 01; break;
      }
      candleRangeBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, histogramWidth, 0, clrDimGray);
      notableBullCandleRangeBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, histogramWidth, 0, clrLawnGreen);
      notableBearCandleRangeBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, histogramWidth, 0, clrMagenta);
      g_zoom = zoom;
   }
   
   // captura dados de indicadores customizados
   candleRangeData.setIndicatorData(indCandleRange, 0);
   
   // laço principal
   for(int i = limit; i >= 0; i--) {
      const double crValue = candleRangeData.getValue(i);
      const double crmValue = candleRangeData.getSmoothValue(10, MODE_EMA, i);
      const bool showCrmBullValue = crValue > (crmValue * 1.33) && Close[i] > Open[i];
      const bool showCrmBearValue = crValue > (crmValue * 1.33) && Close[i] < Open[i];
      
      candleRangeBuffer.setValue(crValue, i);
      notableBullCandleRangeBuffer.setValue(crValue, showCrmBullValue, i);
      notableBearCandleRangeBuffer.setValue(crValue, showCrmBearValue, i);
      
   }
   
   return Bars;
}

//+------------------------------------------------------------------+
//| indicador: candle range                                          |
//+------------------------------------------------------------------+
double indCandleRange(const int period, const int shift) {
   const double openClose = MathAbs(Open[shift] - Close[shift]);
   const double highLow = High[shift] - Low[shift];
   const double volume = (double)Volume[shift];
   const double ocWeight = 6;
   const double vlWeight = 4;
   const double hlWeight = 2;
   const double candleRange = (openClose * ocWeight + highLow * hlWeight + volume * vlWeight) / (ocWeight + hlWeight + vlWeight);
   
   return candleRange;
}



