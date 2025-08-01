//+------------------------------------------------------------------+
//| MACROS                                                           |
//+------------------------------------------------------------------+
#property indicator_buffers 3
#property indicator_separate_window
#property strict
#include "ob-lab-lib.mqh"

// --- inputs de usuário
input int inputAtrPeriod = 14;
input int inputVolatilityFastPeriod = 7;
input int inputVolatilitySlowPeriod = 14;
input ENUM_THEME_MODE inputThemeMode = NIGHT;
input int inputBars = 120;

// --- variáveis e constantes ---
static int g_indicatorBuffers = 0;
const int BASE_NORMALIZATION_VALUE = 100;
const int BASE_NORMALIZATION_DIGITS = 5;
const color LOW_VOLATILITY_COLOR = C'166,219,58';
const color MEDIUM_VOLATILITY_COLOR = C'224,168,52';
const color HIGH_VOLATILITY_COLOR = C'230,82,45';

// --- objetos ---
CIndicatorDataProcessor* volumeData = new CIndicatorDataProcessor();
CIndicatorDataProcessor* atrData = new CIndicatorDataProcessor();
CIndicatorDataProcessor* atrVolData = new CIndicatorDataProcessor();
CIndicatorBuffers* goodVolatilityBuffer = new CIndicatorBuffers();
CIndicatorBuffers* midVolatilityBuffer = new CIndicatorBuffers();
CIndicatorBuffers* badVolatilityBuffer = new CIndicatorBuffers();

void deinit() {
   delete goodVolatilityBuffer;
   delete midVolatilityBuffer;
   delete badVolatilityBuffer;
   delete volumeData;
   delete atrData;
   delete atrVolData;
}

//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int init() {
   // Setups do indicador
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 0);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_SOLID);
   CVisualUpdater::SetTheme(inputThemeMode);
   CVisualUpdater::indicatorName(NULL);
   
   // Inicialização dos objetos
   volumeData.initialize(inputBars, true);
   atrData.initialize(inputBars, true);
   atrVolData.initialize(inputBars, true);
   goodVolatilityBuffer.initialize(g_indicatorBuffers, "volatility[good]");
   badVolatilityBuffer.initialize(g_indicatorBuffers, "volatility[mid]");
   midVolatilityBuffer.initialize(g_indicatorBuffers, "volatility[bad]");
   
   // Aparência dos buffers
   goodVolatilityBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, 1, 0, LOW_VOLATILITY_COLOR);
   midVolatilityBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, 1, 0, MEDIUM_VOLATILITY_COLOR);
   badVolatilityBuffer.setBufferStyle(DRAW_HISTOGRAM, 0, 1, 0, HIGH_VOLATILITY_COLOR);
   
   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//| Função de cálculo                                                |
//+------------------------------------------------------------------+
int start() {
   // Previne erro 'array out of range'
   const int ic = IndicatorCounted(); if (ic == 0) return(0);
   const int limit = MathMin(ic, inputBars);
   
   // Adiciona dados nos objetos de dados
   volumeData.setIndicatorData(indVolume, 0);
   atrData.setIndicatorData(indAtr, inputAtrPeriod);
   atrVolData.setIndicatorData(indAtrVolume, 0);
   
   // Laço principal do indicador
   for (int i = limit; i >= 0; i--) {
      const double volatility_0 = atrData.getRatioOscillator(inputVolatilityFastPeriod, inputVolatilitySlowPeriod, MODE_EMA, i+0);
      const double volatility_1 = atrData.getRatioOscillator(inputVolatilityFastPeriod, inputVolatilitySlowPeriod, MODE_EMA, i+1);
      
      const bool plotGoodVolatility = volatility_0 < 0 && volatility_0 < volatility_1;
      const bool plotMidVolatility = ((volatility_0 < 0 && volatility_0 > volatility_1) || (volatility_0 > 0 && volatility_0 < volatility_1));
      const bool plotBadVolatility = volatility_0 > 0 && volatility_0 > volatility_1;
      
      goodVolatilityBuffer.setValue(volatility_0, plotGoodVolatility, i);
      midVolatilityBuffer.setValue(volatility_0, plotMidVolatility, i);
      badVolatilityBuffer.setValue(volatility_0, plotBadVolatility, i);
   }
   
   return Bars;
}


//+------------------------------------------------------------------+
//| Indicador: volume                                                |
//+------------------------------------------------------------------+
double indVolume(const int period, const int shift) {
   return (double)iVolume(NULL, PERIOD_CURRENT, shift);
}

//+------------------------------------------------------------------+
//| Indicador: atr                                                   |
//+------------------------------------------------------------------+
double indAtr(const int period, const int shift) {
   return iATR(NULL, PERIOD_CURRENT, period, shift);
}

//+------------------------------------------------------------------+
//| indicador: atr + volume                                          |
//+------------------------------------------------------------------+
double indAtrVolume(const int period, const int shift) {
   const double volume = volumeData.getNormalizedData(BASE_NORMALIZATION_VALUE, BASE_NORMALIZATION_DIGITS, shift);
   const double atr = atrData.getNormalizedData(BASE_NORMALIZATION_VALUE, BASE_NORMALIZATION_DIGITS, shift);
   const double atrVolume = (atr + volume) / 2;
   return atrVolume;
}






