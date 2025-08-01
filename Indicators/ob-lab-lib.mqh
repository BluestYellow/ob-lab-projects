//+------------------------------------------------------------------+
//| Biblioteca utilitária para indicadores MetaTrader 4              |
//| Autor: Eduardo AS                                                |
//| Contato: https://t.me/BlueXInd                                   |
//| Grupo:   https://t.me/OB_Lab                                     |
//+------------------------------------------------------------------+
#property strict

// --- enums ---
enum ENUM_THEME_MODE { NIGHT, LIGHT, CUSTOM };

//+---------------------------------------------------------|
//| type: class                                             |
//| responsibility: Manages the chart's visual appearance,  |
//| applying themes and updating the indicator name.        |
//| description:                                            |
//| Utility class for updating color themes and the         |
//| indicator name in the MetaTrader 4 interface.           |
//+---------------------------------------------------------|
class CVisualUpdater {
public:
   static void SetTheme(ENUM_THEME_MODE theme) {
      // Define color palette for all themes
      color deepNight        = C'12,21,33';
      color farWhite         = C'246,223,180';
      color vulkanDimAshes   = C'89,89,89';
      color vulkanAshes      = C'145,145,145';
      color springGreen      = C'0,163,136';
      color mutterGreen      = C'65,117,45';
      color spagettoRed      = C'163,0,31';
      color background       = clrNONE;
      color foreground       = clrNONE;
      color gridColor        = clrNONE;
      color bullColor        = clrNONE;
      color bearColor        = clrNONE;

      // Select colors based on theme mode
      switch (theme) {
         case NIGHT: {
            background = deepNight;
            foreground = farWhite;
            gridColor  = vulkanDimAshes;
            bullColor  = mutterGreen;
            bearColor  = spagettoRed;
            break;
         }
         case LIGHT: {
            background = farWhite;
            foreground = deepNight;
            gridColor  = vulkanAshes;
            bullColor  = mutterGreen;
            bearColor  = spagettoRed;
            break;
         }
         case CUSTOM: {
            background = clrBlack;
            foreground = clrWhite;
            gridColor  = clrDimGray;
            bullColor  = clrGreen;
            bearColor  = clrRed;
            break;
         }
      }

      // Apply selected colors to chart properties
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, background);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, foreground);
      ChartSetInteger(0, CHART_COLOR_GRID, gridColor);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, bullColor);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, bullColor);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, bearColor);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, bearColor);
      ChartSetInteger(0, CHART_COLOR_CHART_LINE, gridColor);
   }

   static void indicatorName(const string text) {
      // Set the indicator short name for display in the chart window
      string fileName = MQLInfoString(MQL_PROGRAM_NAME);
      const string name = fileName + text;
      IndicatorShortName(name);
   }
};

//+-----------------------------------------------------------|
//| type: class                                              |
//| responsibility: Processes and stores indicator data,     |
//| performing calculations such as smoothing, normalization,|
//| min/max, and other mathematical processing.              |
//| description:                                             |
//| Class for handling and calculating indicator data in     |
//| arrays, including smoothing, oscillator calculations,    |
//| and normalization methods.                               |
//+-----------------------------------------------------------|
class CIndicatorDataProcessor {
private:
   double m_array[];
   int    m_arraySize;
   double m_arrayExtraSizeFactor;
   double m_cachedMaximumData;
   double m_cachedMinimumData;
   datetime m_currentDateTime;

   typedef double (*IndicatorData)(const int, const int);

   // Returns the extended array size for safe calculations
   int getExtraArraySize() const {
      return int(m_arraySize * m_arrayExtraSizeFactor);
   }

public:
   // Returns the smoothed value using the specified moving average method
   double getSmoothValue(const int period, const ENUM_MA_METHOD mode, const int shift) const {
      return iMAOnArray(m_array, 0, period, 0, mode, shift);
   }

   // Returns the standard deviation value for the given period and method
   double getStdDevValue(const int period, const ENUM_MA_METHOD mode, const int shift) const {
      return iStdDevOnArray(m_array, 0, period, 0, mode, shift);
   }

   // Calculates the ratio oscillator between two moving averages
   double getRatioOscillator(const int fastPeriod, const int slowPeriod, const ENUM_MA_METHOD mode, const int shift) const {
      const double fastMa = getSmoothValue(fastPeriod, mode, shift);
      const double slowMa = getSmoothValue(slowPeriod, mode, shift);
      // Avoid division by zero
      if (slowMa == 0.0) return 0.0;
      return (fastMa / slowMa) - 1;
   }

   // Calculates a custom triple oscillator value
   double getTriplecillator(const int fastPeriod, const int slowPeriod, const int thirdPeriod, const ENUM_MA_METHOD mode, const int shift) const {
      const double fastMa  = getSmoothValue(fastPeriod, mode, shift);
      const double slowMa  = getSmoothValue(slowPeriod, mode, shift);
      const double thirdMa = getSmoothValue(thirdPeriod, mode, shift);
      // Avoid division by zero
      if (slowMa == 0.0) return thirdMa;
      return ((fastMa / slowMa) - 1) + thirdMa;
   }

   // Returns the normalized value for the given shift
   double getNormalizedData(const double baseValue, const int digits, const int shift) const {
      // Calculate normalization range
      const double range = m_cachedMaximumData - m_cachedMinimumData;
      // Avoid division by zero
      if (range == 0.0) return 0.0;
      // Normalize current value to [0,1] range
      const double normalizedValue  = (m_array[shift] - m_cachedMinimumData) / range;
      const double basedNormValue   = normalizedValue * baseValue;
      return NormalizeDouble(basedNormValue, digits);
   }

   // Returns the value at the specified shift
   double getValue(const int shift) const {
      return m_array[shift];
   }

   // Returns the minimum value in the data array
   double getMinimumData() const {
      const int arraySize = getExtraArraySize() - 1;
      const int index = ArrayMinimum(m_array, arraySize);
      return m_array[index];
   }

   // Returns the minimum value in the data array (with limit)
   double getMinimumData(const int limit) const {
      const int index = ArrayMinimum(m_array, limit);
      return m_array[index];
   }

   // Returns the maximum value in the data array
   double getMaximumData() const {
      const int arraySize = getExtraArraySize() - 1;
      const int index = ArrayMaximum(m_array, arraySize);
      return m_array[index];
   }

   // Returns the maximum value in the data array (with limit)
   double getMaximumData(const int limit) const {
      const int index = ArrayMaximum(m_array, limit);
      return m_array[index];
   }

   // Updates the internal data array with new indicator values
   void setIndicatorData(IndicatorData indicator, const int period) {
      // Only update if the bar has changed
      if (m_currentDateTime != Time[0]) {
         const int arraySize = ArraySize(m_array);
         const int ic        = IndicatorCounted();
         const int limit     = MathMin(ic, arraySize);

         // Fill the array with indicator values
         for (int i = limit - 1; i >= 0; i--) {
            m_array[i] = indicator(period, i);
         }

         // Cache min/max for normalization
         m_cachedMaximumData = getMaximumData();
         m_cachedMinimumData = getMinimumData();
         m_currentDateTime   = Time[0];
      } else {
         // Update only the latest value if bar hasn't changed
         m_array[0] = indicator(period, 0);
      }
   }

   // Initializes the internal data array with the specified size and series order
   int initialize(const int arraySize, const bool setAsSeries) {
      m_arraySize = arraySize;
      const int extraArraySize = getExtraArraySize();
      ArrayResize(m_array, extraArraySize);
      ArraySetAsSeries(m_array, setAsSeries);
      ArrayInitialize(m_array, EMPTY_VALUE);
      return ArraySize(m_array);
   }

   // Constructor: initializes internal state
   CIndicatorDataProcessor() {
      m_currentDateTime       = 0;
      m_arraySize             = -1;
      m_arrayExtraSizeFactor  = 1.33;
      m_cachedMaximumData     = 0.0;
      m_cachedMinimumData     = 0.0;
   }

   // Destructor: resets state and frees memory
   ~CIndicatorDataProcessor() {
      m_currentDateTime   = 0;
      m_arraySize         = -1;
      m_cachedMaximumData = 0.0;
      m_cachedMinimumData = 0.0;
      ArrayFree(m_array);
   }
};

//+---------------------------------------------------------|
//| type: class                                             |
//| responsibility: Manages indicator buffers in MetaTrader |
//| 4, including initialization, style configuration, and   |
//| read/write access to buffer values.                     |
//| description:                                            |
//| Class for handling indicator buffers, simplifying       |
//| integration with the MetaTrader 4 API.                  |
//+---------------------------------------------------------|
class CIndicatorBuffers {
private:
   double m_buffer[];
   double m_candleHigh[];
   double m_candleLow[];
   double m_candleOpen[];
   double m_candleClose[];
   int    m_highIndex;
   int    m_lowIndex;
   int    m_openIndex;
   int    m_closeIndex;
   int    m_indicatorBuffer;
   int    m_candleWidth;
   bool   m_candleInicialization; // Typo preserved as per original

   // Initializes the indicator buffer and sets its properties
   int initializeCandle(int &bufferIndex, const string bufferLabel, const int type) {
      const string bufferName = StringFormat("%s::'%d'", bufferLabel, bufferIndex);
      m_indicatorBuffer = bufferIndex;
      IndicatorBuffers(bufferIndex + 1);

      switch(type) {
          case 0: // High
              ArrayResize(m_candleHigh, 0);
              ArraySetAsSeries(m_candleHigh, true);
              SetIndexBuffer(m_indicatorBuffer, m_candleHigh);
              break;
          case 1: // Low
              ArrayResize(m_candleLow, 0);
              ArraySetAsSeries(m_candleLow, true);
              SetIndexBuffer(m_indicatorBuffer, m_candleLow);
              break;
          case 2: // Open
              ArrayResize(m_candleOpen, 0);
              ArraySetAsSeries(m_candleOpen, true);
              SetIndexBuffer(m_indicatorBuffer, m_candleOpen);
              break;
          case 3: // Close
              ArrayResize(m_candleClose, 0);
              ArraySetAsSeries(m_candleClose, true);
              SetIndexBuffer(m_indicatorBuffer, m_candleClose);
              break;
      }

      SetIndexLabel(m_indicatorBuffer, bufferName);
      SetIndexEmptyValue(m_indicatorBuffer, EMPTY_VALUE);
      bufferIndex++;
      return bufferIndex;
   }

   // Sets the visual style for the indicator buffer with external buffer index
   void setCandleBufferStyle(const int indicatorBuffer, const int type, const int style, const int width, const int arrowCode, const color clr) const {
      SetIndexStyle(indicatorBuffer, type, style, width, clr);
      if (type == DRAW_ARROW) SetIndexArrow(indicatorBuffer, arrowCode);
   }

public:
   // Initializes the indicator buffer and sets its properties
   int initialize(int &bufferIndex, const string bufferLabel) {
      const string bufferName = StringFormat("%s::'%d'", bufferLabel, bufferIndex);
      m_indicatorBuffer = bufferIndex;
      IndicatorBuffers(bufferIndex + 1);
      ArrayResize(m_buffer, 0);
      ArraySetAsSeries(m_buffer, true);
      SetIndexBuffer(m_indicatorBuffer, m_buffer);
      SetIndexLabel(m_indicatorBuffer, bufferName);
      SetIndexEmptyValue(m_indicatorBuffer, EMPTY_VALUE);
      bufferIndex++;
      return bufferIndex;
   }

   // Provides a fast candle creation method
   void setCandle(int &bufferIndex, const color candleColor, const bool plotStick, const bool condition, const int shift) {
      const int zoom = (int)ChartGetInteger(0, CHART_SCALE);
      if (zoom != m_candleWidth) {
         string candleName = NULL;
         // Initialize only once
         if (m_candleInicialization) {
            // Create high
            if (plotStick) {
               m_highIndex = bufferIndex;
               candleName = "high::" + IntegerToString(bufferIndex);
               initializeCandle(bufferIndex, candleName, 0);
               // Create low
               m_lowIndex = bufferIndex;
               candleName = "low::" + IntegerToString(bufferIndex);
               initializeCandle(bufferIndex, candleName, 1);
            }
            // Create open
            m_openIndex = bufferIndex;
            candleName = "open::" + IntegerToString(bufferIndex);
            initializeCandle(bufferIndex, candleName, 2);
            // Create close
            m_closeIndex = bufferIndex;
            candleName = "close::" + IntegerToString(bufferIndex);
            initializeCandle(bufferIndex, candleName, 3);
            // Close initialization
            m_candleInicialization = false;
         }

         // Configure candle style based on zoom
         int candleWidth = 1; // Default
         switch (zoom) {
            case 5: candleWidth = 16; break;
            case 4: candleWidth = 8;  break;
            case 3: candleWidth = 4;  break;
            case 2: candleWidth = 2;  break;
            case 1:
            case 0: candleWidth = 1;  break;
         }

         const color stickColor = (color)ChartGetInteger(0, CHART_COLOR_CHART_LINE);
         setCandleBufferStyle(m_highIndex, DRAW_HISTOGRAM, 0, 1, 0, stickColor);
         setCandleBufferStyle(m_lowIndex, DRAW_HISTOGRAM, 0, 1, 0, stickColor);
         setCandleBufferStyle(m_openIndex, DRAW_HISTOGRAM, 0, candleWidth, 0, candleColor);
         setCandleBufferStyle(m_closeIndex, DRAW_HISTOGRAM, 0, candleWidth, 0, candleColor);
         m_candleWidth = zoom;
      }

      if (plotStick) m_candleHigh[shift] = High[shift];
      if (plotStick) m_candleLow[shift]  = Low[shift];
      m_candleOpen[shift]  = (condition) ? Open[shift] : EMPTY_VALUE;
      m_candleClose[shift] = (condition) ? Close[shift] : EMPTY_VALUE;
   }

   // Sets the visual style for the indicator buffer
   void setBufferStyle(const int type, const int style, const int width, const int arrowCode, const color clr) const {
      SetIndexStyle(m_indicatorBuffer, type, style, width, clr);
      if (type == DRAW_ARROW) SetIndexArrow(m_indicatorBuffer, arrowCode);
   }

   // Returns the buffer value at shift if condition is true, otherwise returns falseValue
   double getValue(const bool condition, const double falseValue, const int shift) const {
      return (condition) ? m_buffer[shift] : falseValue;
   }

   // Returns the buffer value at the specified shift
   double getValue(const int shift) const {
      return m_buffer[shift];
   }

   // Sets the buffer value at shift if condition is true, otherwise sets EMPTY_VALUE
   void setValue(const double value, const bool condition, const int shift) {
      m_buffer[shift] = (condition) ? value : EMPTY_VALUE;
   }

   // Sets the buffer value at the specified shift
   void setValue(const double value, const int shift) {
      m_buffer[shift] = value;
   }

   // Constructor: initializes buffer index
   CIndicatorBuffers() {
      m_candleWidth           = 100;
      m_indicatorBuffer       = -1;
      m_candleInicialization  = true; // Typo preserved as per original
   }
};

//+------------------------------------------------------------------+
//| class to handle draw objects on the chart                        |
//+------------------------------------------------------------------+
class CObjectsHandle {
private:
   string   m_objectsName[];
   string   m_text, m_font;
   datetime m_time1, m_time2;
   string   m_objectName;
   double   m_price1, m_price2, m_angle;
   color    m_mainColor;
   bool     m_back, m_ray;
   int      m_mainWidth, m_fontSize, m_subWindow;

   // Provides an object register
   void registerObject(const string objectName) {
      const int numberOfObjects = ArraySize(m_objectsName);
      ArrayResize(m_objectsName, numberOfObjects + 1);
      m_objectsName[numberOfObjects] = objectName;
   }

   // Get objects name for consistency
   string getObjectName(const int index, const string label, const int objType) const {
      return StringFormat("%s::%d - %d", label, index, objType);
   }

public:
   // Destructor
   ~CObjectsHandle() {
      const int numberOfObjects = ArraySize(m_objectsName);
      for (int i = 0; i < numberOfObjects; i++) { // Changed loop condition
         ObjectDelete(0, m_objectsName[i]);
      }
      ArrayResize(m_objectsName, 0);
      ArrayFree(m_objectsName);
   }

   // Initializer
   void initialize() {
      m_subWindow = 0;
      m_text      = NULL;
      m_font      = NULL;
      m_time1     = 0;
      m_time2     = 0;
      m_fontSize  = 11;
      m_price1    = 0;
      m_price2    = 0;
      m_angle     = 0.0;
      m_mainColor = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
      m_mainWidth = 1;
      m_back      = true;
      m_ray       = true;
   }

   // Provides write access to the objects properties
   void setPrice(const double price)                        { m_price1 = price; }
   void setPrice(const double price1, const double price2)  { m_price1 = price1; m_price2 = price2;}
   void setSubWindow(const int subWindow)                   { m_subWindow = subWindow; }
   void setText(const string text)                          { m_text = text; }
   void setFont(const string font)                          { m_font = font; }
   void setFontSize(const int fontSize)                     { m_fontSize = fontSize; }
   void setAngle(const double angle)                        { m_angle = angle; }
   void setWidth(const int width)                           { m_mainWidth = width; }
   void setColor(const color clr)                           { m_mainColor = clr; }
   void setTime(const datetime time)                        { m_time1 = time; }
   void setTime(const datetime time1, const datetime time2) { m_time1 = time1; m_time2 = time2;}
   void setBack(const bool back)                            { m_back = back; }

   // Create objects on chart
   void draw(const string label, const int index, const int objType) {
      const string objectName = getObjectName(index, label, objType);

      if (ObjectFind(0, objectName) == -1) {
         ObjectCreate(0, objectName, objType, m_subWindow, 0, 0);
         ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objectName, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, objectName, OBJPROP_WIDTH, m_mainWidth);
         ObjectSetInteger(0, objectName, OBJPROP_COLOR, m_mainColor);
         ObjectSetInteger(0, objectName, OBJPROP_BACK, m_back);
      } else {
         // Object property selector based on object type
         switch (objType) {
            // hline properties
            case OBJ_HLINE: {
               ObjectSetDouble(0, objectName, OBJPROP_PRICE1, m_price1);
               break;
            }
            
            // vline properties
            case OBJ_VLINE: {
               ObjectSetInteger(0, objectName, OBJPROP_TIME1, m_time1);
               break;
            }
            
            // trend properties
            case OBJ_TREND: {
               ObjectSetDouble(0, objectName, OBJPROP_PRICE1, m_price1);
               ObjectSetDouble(0, objectName, OBJPROP_PRICE2, m_price2);
               ObjectSetInteger(0, objectName, OBJPROP_TIME1, m_time1);
               ObjectSetInteger(0, objectName, OBJPROP_TIME2, m_time2);
               ObjectSetInteger(0, objectName, OBJPROP_RAY, m_ray);
               break;
            }
            
            // text properties
            case OBJ_TEXT: {
               ObjectSetDouble(0, objectName, OBJPROP_PRICE1, m_price1);
               ObjectSetInteger(0, objectName, OBJPROP_TIME1, m_time1);
               ObjectSetDouble(0, objectName, OBJPROP_ANGLE, m_angle);
               ObjectSetString(0, objectName, OBJPROP_TEXT, m_text);
               ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, m_fontSize);
               if(m_font != NULL && m_font != "") {
                   ObjectSetString(0, objectName, OBJPROP_FONT, m_font);
               }
               ObjectSetInteger(0, objectName, OBJPROP_COLOR, m_mainColor); // Re-set color for text object
               break;
            }
         }
      }
      
      // Register the current object
      registerObject(objectName);
   }

   // Provides access to objects array list
   string getObjectId(const int shift) {
      if (shift >= ArraySize(m_objectsName)) return(NULL); // Changed condition
      const string objectName = m_objectsName[shift];
      return objectName;
   }
};
