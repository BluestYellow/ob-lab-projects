/*/=============================================================================/
\\\ [macros] --------------------------------------------------------------- /*/
#property indicator_separate_window
#property indicator_buffers 2
#property strict
#include <ob-lab-lib.mqh>

// --- constants ---

// --- variables ---
int g_bars = 1000;
int g_bufferIndex = 0;

// --- objects ---
CIndicatorDataProcessor * ___angleData = new CIndicatorDataProcessor();
CIndicatorBuffers * ___histoUpBuffer = new CIndicatorBuffers();
CIndicatorBuffers * ___histoDnBuffer = new CIndicatorBuffers();

/*/=============================================================================/
\\\ [deinitialization event] ------------------------------------------------- /
/*/ void deinit() {
   delete ___angleData;
   delete ___histoUpBuffer;
   delete ___histoDnBuffer;
}

/*/=============================================================================/
\\\ [calculate event] -------------------------------------------------------- /
/*/ int init() {   
   // variables
   int type = DRAW_HISTOGRAM;
   int style = STYLE_SOLID;
   int width = 1;
   color upLineColor = clrOrange;
   color dnLineColor = clrDimGray;

   // objects initialization
   ___angleData.initialize(g_bars, true);
   ___histoUpBuffer.initialize(g_bufferIndex, "angle line up");
   ___histoDnBuffer.initialize(g_bufferIndex, "angle line dn");
   
   // buffers style
   ___histoUpBuffer.setBufferStyle(type, style, width, 0, upLineColor);
   ___histoDnBuffer.setBufferStyle(type, style, width, 0, dnLineColor);
   
   return INIT_SUCCEEDED;
}

/*/=============================================================================/
\\\ [calculate event] -------------------------------------------------------- /
/*/ int start() { int ic = IndicatorCounted(); if (ic <= 0) return(-1);
   // variables
   int i, limit;
   
   // fill indicator data
   ___angleData.setIndicatorData(IDMaAngle, 5);
   
   // main loop
   limit = MathMin(ic, g_bars);
   for (i = limit; i >= 0; i--) 
   {
      // data set
      double angleShift0 = ___angleData.getValue(i);
      double angleShift1 = ___angleData.getValue(i + 1);
      
      // histogram conditions
      bool upCondition = angleShift0 > angleShift1;
      bool dnCondition = angleShift0 < angleShift1;
      
      ___histoUpBuffer.setValue(angleShift0, upCondition, i);
      ___histoDnBuffer.setValue(angleShift0, dnCondition, i);
   }
   
   return Bars;
}   

/*/=============================================================================/
\\\ [indicator: Moving Average] ---------------------------------------------- /
/*/ double IDMaAngle(const int period, const int shift) { 
   string   symbol   = NULL;
   int      tf       = PERIOD_CURRENT;
   int      mode     = MODE_LWMA;
   int      price    = PRICE_WEIGHTED;
   double   ma0      = iMA(symbol, tf, period, 0, mode, price, shift + 0);
   double   ma1      = iMA(symbol, tf, period, 0, mode, price, shift + 10);
   double   angle    = MathAbs(ma0 - ma1);
   
   return angle;
}



