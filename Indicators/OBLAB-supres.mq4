//+··································································+
//| pré-processadores                                                |
//+··································································+
#property copyright "Oblab indicarots"
#property version "1.0"
#property link "https://t.me/OB_Lab"
#property description "Indicador gratuíto e aberto, para mais conteúdos como este"
#property description "acesso nosso grupo no telegram: t.me/OB_Lab!"
#property indicator_buffers 0
#property indicator_chart_window
#property strict
#include "ob-lab-lib.mqh"

// --- variáveis & constantes ---
static datetime g_currentTime = 0;
static double g_maximumLevel = 0;
static double g_minimumLevel = 0;
static bool g_calculateLevel = true;
static int g_indicatorBuffer = 0;
static int g_numberOfLevels = 3000;
const int WINGDING_UP_ARROW = 217;
const int WINGDING_DOWN_ARROW = 218;
const int ARROW_WIDTH = 1;
const int LEVEL_INCREMENT = 5;
const double LEVEL_ACCURACY = 0.75;

// --- inputs do usuário ---
input color inputLevelColors = clrDimGray;
input ENUM_THEME_MODE inputThemeMode = NIGHT;
input int inputNumberOfCandles = 120;

// --- declaração de objetos ---
CObjectsHandle* objects = new CObjectsHandle();

//+··································································+
//| função que será chamada quando o indicador for tirado do gráfico |
//+··································································+
void deinit() {
   delete objects;
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
   objects.initialize();
   
   // define a aparência dos buffers
   
   return(INIT_SUCCEEDED);
}

//+··································································+
//| cálculo principal do indicador - criação de buffers aqui         |
//+··································································+
int start() {
   // chamada de variáveis
   checkMaxMinLevel(g_maximumLevel, g_minimumLevel, g_calculateLevel);
   
   if (g_calculateLevel) {
      const double maxLevel = High[ArrayMaximum(High, inputNumberOfCandles)];
      const double minLevel = Low[ArrayMinimum(Low, inputNumberOfCandles)];
      const double distance = (maxLevel - minLevel) / LEVEL_INCREMENT;
      g_maximumLevel = maxLevel + distance;
      g_minimumLevel = minLevel - distance;
   
      for (int i = 0; i <= g_numberOfLevels; i++) {
         const double level = getPriceLevel(g_maximumLevel, g_minimumLevel, g_numberOfLevels, i);
         objects.setPrice(level);
         objects.setColor(inputLevelColors);
         objects.drawObject("level", i, OBJ_HLINE);
      }
      g_calculateLevel = false;
   }
   
   
   // previne o erro 'array out of range'
   const int ic = IndicatorCounted(); if (ic == 0) return(0);
   const int limit = MathMin(ic, inputNumberOfCandles);
   
   // preenche o objeto de processamento de dados com os dados de um determinado indicador
   
   // laço principal do indicador[local onde os buffers estão!!!
   if (g_currentTime != Time[0]) {
      for (int j = 0; j <= g_numberOfLevels; j++) {
         int positiveTouch = 0;
         int negativeTouch = 0;
         const string objectName = objects.getObjectId(j);
         const double priceLevel = ObjectGet(objectName, OBJPROP_PRICE1);
         
         for (int i = limit; i >= 0; i--) {
            const double atr = iATR(NULL, PERIOD_CURRENT, 14, i) / 3;
            const double lowPoint = Low[i] - atr;
            const double highPoint = High[i] + atr;
            
            const bool callPositive = ( Open[i] > priceLevel && 
                                        Close[i] > priceLevel && 
                                        Low[i] < priceLevel );
                                        
            const bool putPositive = ( Open[i] < priceLevel && 
                                       Close[i] < priceLevel && 
                                       High[i] > priceLevel );
                                       
            const bool callNegative = ( Open[i] > priceLevel && 
                                        Close[i] < priceLevel && 
                                        Low[i] < priceLevel );
                                        
            const bool putNegative = ( Open[i] < priceLevel && 
                                       Close[i] > priceLevel && 
                                       High[i] > priceLevel );
            
            if (callPositive || putPositive) positiveTouch++;
            if (callNegative || putNegative) negativeTouch++;
         }
         
         const double totalTouches = positiveTouch + negativeTouch;
         const double positivePercent = (totalTouches != 0.0)? positiveTouch / totalTouches : 0;
         
         if (positivePercent <= LEVEL_ACCURACY) ObjectDelete(objectName);
      }

      g_currentTime = Time[0];
   } else {

   }

   return Bars;
}

//+------------------------------------------------------------------+
//| Função para gerar leveis                                         |
//+------------------------------------------------------------------+
double getPriceLevel(const double maxLevel, const double minLevel, const int numberOfLevels, const int level) {
   if (maxLevel == 0.0 || minLevel == 0.0) return(0.0);
   const double distance = (maxLevel - minLevel) / numberOfLevels;
   const double levelValue = (distance * level) + minLevel;
   return levelValue;
}

//+------------------------------------------------------------------+
//| Checa se o max e min é válido                                    |
//+------------------------------------------------------------------+
void checkMaxMinLevel(double& maxLevel, double& minLevel, bool& calculateLevels) {
   const double close = Close[0];
   const double distance = maxLevel - minLevel;
   
   if (close > maxLevel || close < minLevel) {
      maxLevel = maxLevel + (distance/LEVEL_INCREMENT);
      minLevel = minLevel - (distance/LEVEL_INCREMENT);
      calculateLevels = true;
   }
}




