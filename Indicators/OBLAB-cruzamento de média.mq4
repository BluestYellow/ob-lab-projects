#property indicator_buffers 4
#property indicator_chart_window
#property strict

// --- variáveis & constantes ---
const color BULL_COLORS = clrGreen;
const color BEAR_COLORS = clrRed;
const int WINGDING_UP_ARROW = 233;
const int WINGDING_DOWN_ARROW = 234;
static int g_indicatorBuffer = 0;

// --- inputs de usuário ---
input int inputFastMaPeriod = 5; 
input ENUM_MA_METHOD inputFastMaMode = MODE_EMA; 
input ENUM_APPLIED_PRICE inputFastMaPrice = PRICE_CLOSE;
input int inputSlowMaPeriod = 17; 
input ENUM_MA_METHOD inputSlowMaMode = MODE_EMA; 
input ENUM_APPLIED_PRICE inputSlowMaPrice = PRICE_CLOSE;
input int inputBars = 300;

// --- arrays ---
double slowMa[];
double fastMa[];
double upArrow[];
double downArrow[];

//+------------------------------------------------------------------+
//| evento de inicialização                                          |
//+------------------------------------------------------------------+
int init() {
   createBuffer(g_indicatorBuffer, upArrow, "b-call", DRAW_ARROW, 0, 1, BULL_COLORS, WINGDING_UP_ARROW);
   createBuffer(g_indicatorBuffer, downArrow, "b-put", DRAW_ARROW, 0, 1, BEAR_COLORS, WINGDING_DOWN_ARROW);
   createBuffer(g_indicatorBuffer, slowMa, "l-slow", DRAW_LINE, 0, 1, BULL_COLORS, 0);
   createBuffer(g_indicatorBuffer, fastMa, "l-fast", DRAW_LINE, 0, 1, BEAR_COLORS, 0);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| evento de iteração por tick rate                                 |
//+------------------------------------------------------------------+
int start() {
   
   // previne erro de array out of range por falta de velas no gráfico
   const int ic = IndicatorCounted(); if (ic == 0) return(0);
   const int limit = MathMin(ic, inputBars);
   
   // laço principal
   for (int i = limit; i >= 0; i--) {
      // definição de localização das setas
      const double atr = iATR(NULL, PERIOD_CURRENT, 14, i) / 3;
      const double lowPoint = Low[i] - atr;
      const double highPoint = High[i] + atr;
      
      // médias móveis
      fastMa[i] = ma(inputFastMaPeriod, inputFastMaMode, inputFastMaPrice, i);
      slowMa[i] = ma(inputSlowMaPeriod, inputSlowMaMode, inputSlowMaPrice, i);
      
      // sinais de call/put
      const bool callSignal = fastMa[i+1] < slowMa[i+1] && fastMa[i] > slowMa[i];
      const bool putSignal = fastMa[i+1] > slowMa[i+1] && fastMa[i] < slowMa[i];
      if (callSignal) {
         upArrow[i] = lowPoint;
      } else {
         upArrow[i] = EMPTY_VALUE;
      }
      
      if (putSignal) {
         downArrow[i] = highPoint;
      } else {
         downArrow[i] = EMPTY_VALUE;
      }

   }
   
   return Bars;
}

//+------------------------------------------------------------------+
//| função de retorno da média móvel                                 |
//+------------------------------------------------------------------+
double ma(const int period, const int mode, const int price, const int shift) {
   return iMA(NULL, PERIOD_CURRENT, period, 0, mode, price, shift);
}


//+------------------------------------------------------------------+
//| função para criação de buffers                                   |
//+------------------------------------------------------------------+
int createBuffer(  int& index, 
                   double& array[], 
                   const string label = "buffer",
                   const int type = DRAW_LINE,
                   const int style = STYLE_SOLID,
                   const int width = 1,
                   const color clr = clrRed,
                   const int arrowCode = 108
                   
) {
   // variáveis
   const string bufferLabel = IntegerToString(index) + "::" + label;
   
   // configurações de formação
   IndicatorBuffers(index+1);
   ArrayInitialize(array, EMPTY_VALUE);
   ArraySetAsSeries(array, true);
   SetIndexBuffer(index, array);
   SetIndexLabel(index, bufferLabel);
   SetIndexEmptyValue(index, EMPTY_VALUE);
   
   // estilo do buffer
   SetIndexStyle(index, type, style, width, clr);
   if (type == DRAW_ARROW) SetIndexArrow(index, arrowCode);
   
   index++;
   return index;
}






