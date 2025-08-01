//+··································································+
//| pré-processadores                                                |
//+··································································+
#property copyright "Oblab indicarots"
#property version "1.0"
#property link "https://t.me/OB_Lab"
#property description "Indicador gratuíto e aberto, para mais conteúdos como este"
#property description "acesso nosso grupo no telegram: t.me/OB_Lab!"
#property indicator_buffers 5
#property indicator_separate_window
#property strict
#include "ob-lab-lib.mqh"

// --- variáveis & constantes ---
static int g_indicatorBuffer = 0;
static datetime g_currentTime = 0;
const int WINGDING_ARROW_UP = 228;
const int WINGDING_ARROW_DOWN = 230;
const int LINE_WIDTH = 2;

// --- inputs do usuário ---
input int inputRsiPeriod = 14;
input int inputRsiFastPeriod = 3;
input int inputRsiSlowPeriod = 12;
input ENUM_MA_METHOD inputSmoothMaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE inputRSIPrice = PRICE_CLOSE;
input double inputRsiFilterDistFromZero = 0.023;
input ENUM_THEME_MODE inputThemeMode = NIGHT;
int inputNumberOfCandles = 200;

// --- declaração de objetos ---
CIndicatorDataProcessor * rsiData = new CIndicatorDataProcessor();
CIndicatorBuffers * callArrow = new CIndicatorBuffers();
CIndicatorBuffers * putArrow = new CIndicatorBuffers();
CIndicatorBuffers * rsiLine = new CIndicatorBuffers();
CIndicatorBuffers * rsiUpLine = new CIndicatorBuffers();
CIndicatorBuffers * rsiDownLine = new CIndicatorBuffers();

//+··································································+
//| função que será chamada quando o indicador for tirado do gráfico |
//+··································································+
void deinit() {
   delete callArrow;
   delete putArrow;
   delete rsiData;
   delete rsiUpLine;
   delete rsiDownLine;
   delete rsiLine;
   ObjectsDeleteAll(0, -1, OBJ_VLINE);
}

//+··································································+
//| função que será chamada quando o indicador for colocado  pela    | 
//| primeira vez no gráfico                                          |
//+··································································+
int init() {
   // configurações de aparência do gráfico
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0);
   CVisualUpdater::SetTheme(inputThemeMode);
   CVisualUpdater::indicatorName(NULL);
   color bullColor = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BULL);
   color bearColor = (color)ChartGetInteger(0, CHART_COLOR_CANDLE_BEAR);
   color gridColor = (color)ChartGetInteger(0, CHART_COLOR_GRID);
   color foreColor = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
   
   // inicialização dos objetos
   rsiData.initialize(inputNumberOfCandles, true);
   callArrow.initialize(g_indicatorBuffer, "call Arrow");
   putArrow.initialize(g_indicatorBuffer, "put Arrow");
   rsiLine.initialize(g_indicatorBuffer, "rsi[neutral]");
   rsiUpLine.initialize(g_indicatorBuffer, "rsi[up]");
   rsiDownLine.initialize(g_indicatorBuffer, "rsi[down]");
   
   // define a aparência dos buffers
   rsiLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, LINE_WIDTH, 0, gridColor);
   rsiUpLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, LINE_WIDTH, 0, bullColor);
   rsiDownLine.setBufferStyle(DRAW_LINE, STYLE_SOLID, LINE_WIDTH, 0, bearColor);
   callArrow.setBufferStyle(DRAW_ARROW, 1, 1, WINGDING_ARROW_UP, bullColor);
   putArrow.setBufferStyle(DRAW_ARROW, 1, 1, WINGDING_ARROW_DOWN, bearColor);
   
   return(INIT_SUCCEEDED);
}

//+··································································+
//| calculo principal do indicador - criação de buffers aqui         |
//+··································································+
int start(){
   // chamada de variáveis
   double rsiOscillator = 0;
   double rsiOscillator_1 = 0;
   double rsiOscilatorAncorPoint = 0;
   bool bullCandle = false;
   bool bearCandle = false;
   bool callCondition = false;
   bool putCondition = false;
   bool upCondition = false;
   bool downCondition = false;
   
   // previne o erro 'array out of range'
   const int ic = IndicatorCounted(); if (ic == 0) return(0);
   const int limit = MathMin(ic, inputNumberOfCandles);
   
   // preenche o objeto de processamento de dados com os dados de um determinado indicador
   rsiData.setIndicatorData(rsiIndicator, inputRsiPeriod);
   
   // laço principal do indicador[local onde os buffers estão!!!]
   if (g_currentTime != Time[0]) {
      for (int i = limit; i >= 0; i--) {
         bullCandle = Close[i] > Open[i];
         bearCandle = Close[i] < Open[i];
         rsiOscillator = rsiData.getRatioOscillator(inputRsiFastPeriod, inputRsiSlowPeriod, inputSmoothMaMethod, i);
         rsiOscillator_1 = rsiData.getRatioOscillator(inputRsiFastPeriod, inputRsiSlowPeriod, inputSmoothMaMethod, i+1);
         rsiOscilatorAncorPoint = rsiOscillator - (rsiOscillator * 1.03);
         upCondition = rsiOscillator > 0 && rsiOscillator > rsiOscillator_1;
         downCondition = rsiOscillator < 0 && rsiOscillator < rsiOscillator_1;
         callCondition = rsiOscillator > 0 && upCondition && bearCandle && rsiOscillator > inputRsiFilterDistFromZero;
         putCondition = rsiOscillator < 0 && downCondition && bullCandle && rsiOscillator < inputRsiFilterDistFromZero * -1;
         
         rsiLine.setValue(rsiOscillator, i);
         rsiUpLine.setValue(rsiOscillator, upCondition, i);
         rsiDownLine.setValue(rsiOscillator, downCondition, i);
         callArrow.setValue(rsiOscilatorAncorPoint, callCondition, i);
         putArrow.setValue(rsiOscilatorAncorPoint, putCondition, i);
      }
      
      g_currentTime = Time[0];
   } else {
      rsiOscillator = rsiData.getRatioOscillator(inputRsiFastPeriod, inputRsiSlowPeriod, inputSmoothMaMethod, 0);
      rsiOscillator_1 = rsiData.getRatioOscillator(inputRsiFastPeriod, inputRsiSlowPeriod, inputSmoothMaMethod, 1);
      rsiOscilatorAncorPoint = rsiOscillator - (rsiOscillator * 1.03);
      upCondition = rsiOscillator > 0 && rsiOscillator > rsiOscillator_1;
      downCondition = rsiOscillator < 0 && rsiOscillator < rsiOscillator_1;
      callCondition = rsiOscillator > 0 && upCondition && bearCandle && rsiOscillator > inputRsiFilterDistFromZero;
      putCondition = rsiOscillator < 0 && downCondition && bullCandle && rsiOscillator < inputRsiFilterDistFromZero * -1;
   
      rsiLine.setValue(rsiOscillator, 0);
      rsiUpLine.setValue(rsiOscillator, upCondition, 0);
      rsiDownLine.setValue(rsiOscillator, downCondition, 0);
      callArrow.setValue(rsiOscilatorAncorPoint, callCondition, 0);
      putArrow.setValue(rsiOscilatorAncorPoint, putCondition, 0);
   }

   return Bars;
}

//+------------------------------------------------------------------+
//| handle para o indicador RSI                                      |
//+------------------------------------------------------------------+
double rsiIndicator(const int period, const int shift) {
   return iRSI(NULL, PERIOD_CURRENT, period, inputRSIPrice, shift);
}


