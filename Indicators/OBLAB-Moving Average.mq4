//+··································································+
//| pré-processadores                                                |
//+··································································+
#property copyright "Oblab indicarots"
#property version "1.0"
#property link "https://t.me/OB_Lab"
#property description "Indicador gratuíto e aberto, para mais conteúdos como este"
#property description "acesso nosso grupo no telegram: t.me/OB_Lab!"
#property indicator_buffers 4
#property indicator_chart_window
#property strict
#include "ob-lab-lib.mqh"

// --- variáveis & constantes ---
static int g_indicatorBuffer = 0;
static datetime g_currentTime = 0;

// --- inputs do usuário ---
input ENUM_MA_METHOD inputMaMethod = MODE_LWMA;
input ENUM_APPLIED_PRICE inputMaPrice = PRICE_WEIGHTED;
input int inputMaPeriod = 1;
input int inputFastMaPeriod = 5;
input int inputSlowMaPeriod = 20;
input int inputThirdMaPeriod = 50;
input ENUM_THEME_MODE inputThemeMode = NIGHT;
input int inputNumberOfCandles = 2000;

// --- declaração de objetos ---
CIndicatorDataProcessor* maData = new CIndicatorDataProcessor();
CIndicatorDataProcessor* htfMaData = new CIndicatorDataProcessor();
CIndicatorBuffers* maLine = new CIndicatorBuffers();
CIndicatorBuffers* maUpLine = new CIndicatorBuffers();
CIndicatorBuffers* maDownLine = new CIndicatorBuffers();
CIndicatorBuffers* htfMaLine = new CIndicatorBuffers();

//+··································································+
//| função que será chamada quando o indicador for tirado do gráfico |
//+··································································+
void deinit() {
   delete maData;
   delete maUpLine;
   delete maDownLine;
   delete maLine;
   delete htfMaData;
   delete htfMaLine;
}

//+··································································+
//| função que será chamada quando o indicador for colocado  pela    | 
//| primeira vez no gráfico                                          |
//+··································································+
int init() {
   // configurações de aparência do gráfico
   CVisualUpdater::SetTheme(inputThemeMode);
   CVisualUpdater::indicatorName(NULL);
   color bullColor = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BULL);
   color bearColor = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BEAR);
   color gridColor = (color)ChartGetInteger(0, CHART_COLOR_GRID);
   
   // inicialização dos objetos
   maData.initialize(inputNumberOfCandles, true);
   htfMaData.initialize(inputNumberOfCandles, true);
   maLine.initialize(g_indicatorBuffer, "linha da média");
   maUpLine.initialize(g_indicatorBuffer, "linha da média[up]");
   maDownLine.initialize(g_indicatorBuffer, "linha da média[down]");
   htfMaLine.initialize(g_indicatorBuffer, "linha da média(htf)");
   
   // define a aparência dos buffers
   maLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, 2, 0, gridColor);
   htfMaLine.setBufferStyle(DRAW_LINE, STYLE_DOT, 1, 0, gridColor);
   maUpLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, 2, 0, bullColor);
   maDownLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, 2, 0, bearColor);
   
   return(INIT_SUCCEEDED);
}

//+··································································+
//| calculo principal do indicador - criação de buffers aqui         |
//+··································································+
int start(){
   // chamada de variáveis
   double tmaValue = 0;
   double tmaValue_1 = 0;
   double htfTmaValue = 0;
   int htfShift = 0;
   bool tmaRising = false;
   bool tmaFalling = false;
   const int timeframe = getHTF();

   // previne o erro 'array out of range'
   const int ic = IndicatorCounted(); if (ic == 0) return(0);
   const int limit = MathMin(ic, inputNumberOfCandles);
   
   // preenche o objeto de processamento de dados com os dados de um determinado indicador
   maData.setIndicatorData(movingAverage, inputMaPeriod);
   htfMaData.setIndicatorData(htfMovingAverage, inputMaPeriod);
   
   // laço principal do indicador[local onde os buffers estão!!!]
   if (g_currentTime != Time[0]) {
      for (int i = limit; i >= 0; i--) {
         htfShift = iBarShift(NULL, timeframe, Time[i]);
         tmaValue = maData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, i);
         tmaValue_1 = maData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, i + 1);
         htfTmaValue = htfMaData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, htfShift);
         tmaRising = tmaValue > tmaValue_1 && tmaValue > htfTmaValue && Close[i] > htfTmaValue;
         tmaFalling = tmaValue < tmaValue_1 && tmaValue < htfTmaValue && Close[i] < htfTmaValue;;
         
         maLine.setValue(tmaValue, i);
         maUpLine.setValue(tmaValue, tmaRising, i);
         maDownLine.setValue(tmaValue, tmaFalling, i);
         htfMaLine.setValue(htfTmaValue, i);
      }
      g_currentTime = Time[0];
   } else {
      tmaValue = maData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, 0);
      tmaValue_1 = maData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, 1);
      htfShift = iBarShift(NULL, timeframe, Time[0]);
      htfTmaValue = htfMaData.getTriplecillator(inputFastMaPeriod, inputSlowMaPeriod, inputThirdMaPeriod, inputMaMethod, htfShift);
      tmaRising = tmaValue > tmaValue_1 && tmaValue > htfTmaValue && Close[0] > htfTmaValue;
      tmaFalling = tmaValue < tmaValue_1 && tmaValue < htfTmaValue && Close[0] < htfTmaValue;
      
      maLine.setValue(tmaValue, 0);
      maUpLine.setValue(tmaValue, tmaRising, 0);
      maDownLine.setValue(tmaValue, tmaFalling, 0);
      htfMaLine.setValue(htfTmaValue, 0);
   }

   return Bars;
}

//+··································································+
//| handler do indicador 'média móvel'                               |
//+··································································+
double movingAverage(const int period, const int shift) {
   return iMA(NULL, PERIOD_CURRENT, period, 0, inputMaMethod, inputMaPrice, shift);
}

//+··································································+
//| handler do indicador 'média móvel' de um timeframe superior      |
//+··································································+
double htfMovingAverage(const int period, const int shift) {
   const int timeframe = getHTF();
   return iMA(NULL, timeframe, period, 0, inputMaMethod, inputMaPrice, shift);
}

//+··································································+
//| seletor de tempo gráfico                                         |
//+··································································+
int getHTF() {
   int currentTimeframe = Period();
   int timeframe = 0;
   switch (currentTimeframe) {
      case(PERIOD_M1): timeframe = PERIOD_M5; break;
      case(PERIOD_M5): timeframe = PERIOD_M15; break;
      case(PERIOD_M15): timeframe = PERIOD_M30; break;
      case(PERIOD_M30): timeframe = PERIOD_H1; break;
      case(PERIOD_H1): timeframe = PERIOD_H4; break;
      case(PERIOD_H4): timeframe = PERIOD_D1; break;
      case(PERIOD_D1): timeframe = PERIOD_W1; break;
      default: timeframe = PERIOD_M1; break;
   }
   
   return timeframe;
}
