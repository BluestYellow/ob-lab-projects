//+------------------------------------------------------------------+
//| Biblioteca utilitária para indicadores MetaTrader 4              |
//| Autor: Eduardo AS                                                |
//| Contato: https://t.me/BlueXInd                                   |
//| Grupo:   https://t.me/OB_Lab                                     |
//+------------------------------------------------------------------+
#property strict

// --- enums ---
enum ENUM_THEME_MODE {NIGHT, LIGHT, CUSTOM};

//+---------------------------------------------------------|
//| type: class                                             |
//| responsibility: Manages the chart's visual appearance,  |
//| applying themes and updating the indicator name.        |
//| description:                                            |
//| Utility class for updating color themes and the         |
//| indicator name in the MetaTrader 4 interface.           |
//+---------------------------------------------------------|
class CVisualUpdater {
   public: static void SetTheme(ENUM_THEME_MODE theme) {
      // Define color palette for all themes
      color deepNight = C'0,31,63';
      color farWhite = C'242,242,242';
      color vulkanDimAshes = C'89,89,89';
      color vulkanAshes = C'145,145,145';
      color springGreen = C'0,163,136';
      color mutterGreen = C'65,117,45';
      color spagettoRed = C'163,0,31';
      color background = clrNONE;
      color foreground = clrNONE;
      color gridColor = clrNONE;
      color bullColor = clrNONE;
      color bearColor = clrNONE;
      
      // Select colors based on theme mode
      switch (theme) {
         case NIGHT: {
            background = deepNight;
            foreground = farWhite;
            gridColor = vulkanDimAshes;
            bullColor = springGreen;
            bearColor = spagettoRed;
            break;
         }
         
         case LIGHT: {
            background = farWhite;
            foreground = deepNight;
            gridColor = vulkanAshes;
            bullColor = mutterGreen;
            bearColor = spagettoRed;
            break;
         }
         
         case CUSTOM: {
            background = clrBlack;
            foreground = clrWhite;
            gridColor = clrDimGray;
            bullColor = clrGreen;
            bearColor = clrRed;
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

   public: static void indicatorName(const string text) {
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
   private: double m_array[];
   private: int m_arraySize;
   private: double m_arrayExtraSizeFactor;
   private: double m_cachedMaximumData;
   private: double m_cachedMinimumData;
   private: datetime m_currentDateTime;
   private: typedef double (*IndicatorData)(const int, const int);

   // Returns the smoothed value using the specified moving average method
   public: double getSmoothValue(const int period, const ENUM_MA_METHOD mode, const int shift) const {
      return iMAOnArray(m_array, 0, period, 0, mode, shift);
   }

   // Returns the standard deviation value for the given period and method
   public: double getStdDevValue(const int period, const ENUM_MA_METHOD mode, const int shift) const {
      return iStdDevOnArray(m_array, 0, period, 0, mode, shift);
   }

   // Calculates the ratio oscillator between two moving averages
   public: double getRatioOscillator(const int fastPeriod, const int slowPeriod, const ENUM_MA_METHOD mode, const int shift) const {
      const double fastMa = getSmoothValue(fastPeriod, mode, shift);
      const double slowMa = getSmoothValue(slowPeriod, mode, shift);
      
      // Avoid division by zero
      if (slowMa == 0.0) return 0.0;
      
      return (fastMa / slowMa) - 1;
   }

   // Calculates a custom triple oscillator value
   public: double getTriplecillator(const int fastPeriod, const int slowPeriod, const int thirdPeriod, const ENUM_MA_METHOD mode, const int shift) const {
      const double fastMa = getSmoothValue(fastPeriod, mode, shift);
      const double slowMa = getSmoothValue(slowPeriod, mode, shift);
      const double thirdMa = getSmoothValue(thirdPeriod, mode, shift);
      
      // Avoid division by zero
      if (slowMa == 0.0) return thirdMa;
      
      return ((fastMa / slowMa) - 1) + thirdMa;
   }

   // Returns the normalized value for the given shift
   public: double getNormalizedData(const double baseValue, const int digits, const int shift) const {
      // Calculate normalization range
      const double range = m_cachedMaximumData - m_cachedMinimumData;
      
      // Avoid division by zero
      if (range == 0.0) return 0.0;
      
      // Normalize current value to [0,1] range
      const double normalizedValue = (m_array[shift] - m_cachedMinimumData) / range;
      const double basedNormValue = normalizedValue * baseValue;
      
      return NormalizeDouble(basedNormValue, digits);
   }

   // Returns the value at the specified shift
   public: double getValue(const int shift) const {
      return m_array[shift];
   }

   // Returns the minimum value in the data array
   public: double getMinimumData() const {
      const int arraySize = getExtraArraySize() - 1;
      const int index = ArrayMinimum(m_array, arraySize);
      
      return m_array[index];
   }

   // Returns the maximum value in the data array
   public: double getMaximumData() const {
      const int arraySize = getExtraArraySize() - 1;
      const int index = ArrayMaximum(m_array, arraySize);
      
      return m_array[index];
   }

   // Updates the internal data array with new indicator values
   public: void setIndicatorData(IndicatorData indicator, const int period) {
      // Only update if the bar has changed
      if (m_currentDateTime != Time[0]) {
         const int arraySize = ArraySize(m_array);
         const int ic = IndicatorCounted();
         const int limit = MathMin(ic, arraySize);
         
         // Fill the array with indicator values
         for (int i = limit - 1; i >= 0; i--) {
            m_array[i] = indicator(period, i);
         }
         
         // Cache min/max for normalization
         m_cachedMaximumData = getMaximumData();
         m_cachedMinimumData = getMinimumData();
         m_currentDateTime = Time[0];
      } else {      
         // Update only the latest value if bar hasn't changed
         m_array[0] = indicator(period, 0);
      }
   }

   // Initializes the internal data array with the specified size and series order
   public: int initialize(const int arraySize, const bool setAsSeries) {
      m_arraySize = arraySize;
      const int extraArraySize = getExtraArraySize();
      
      ArrayResize(m_array, extraArraySize);
      ArraySetAsSeries(m_array, setAsSeries);
      ArrayInitialize(m_array, EMPTY_VALUE);
      
      return ArraySize(m_array);
   }

   // Returns the original array size before extra allocation
   private: int getOriginalArraySize() const {
      return int(m_arraySize / m_arrayExtraSizeFactor);
   }

   // Returns the extended array size for safe calculations
   private: int getExtraArraySize() const {
      return int(m_arraySize * m_arrayExtraSizeFactor);
   }

   // Constructor: initializes internal state
   public: CIndicatorDataProcessor() {
      m_currentDateTime = 0;
      m_arraySize = -1;
      m_arrayExtraSizeFactor = 1.33;
      m_cachedMaximumData = 0000000;
      m_cachedMinimumData = 9999999;
   }

   // Destructor: resets state and frees memory
   public: ~CIndicatorDataProcessor() {
      m_currentDateTime = 0;
      m_arraySize = -1;
      m_cachedMaximumData = 0000000;
      m_cachedMinimumData = 9999999;
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
   // Class members
   private: double m_buffer[];
   private: int m_indicatorBuffer;

   // Initializes the indicator buffer and sets its properties
   public: int initialize(int &bufferIndex, const string bufferLabel) {
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

   // Sets the visual style for the indicator buffer
   public: void setBufferStyle(const int type, const int style, const int width, const int arrowCode, const color clr) const {
      SetIndexStyle(m_indicatorBuffer, type, style, width, clr);
      if (type == DRAW_ARROW) SetIndexArrow(m_indicatorBuffer, arrowCode);
   }

   // Returns the buffer value at shift if condition is true, otherwise returns falseValue
   public: double getValue(const bool condition, const double falseValue, const int shift) const {
      return (condition) ? m_buffer[shift] : falseValue;
   }

   // Returns the buffer value at the specified shift
   public: double getValue(const int shift) const {
      return m_buffer[shift];
   }

   // Sets the buffer value at shift if condition is true, otherwise sets EMPTY_VALUE
   public: void setValue(const double value, const bool condition, const int shift) {
      m_buffer[shift] = (condition) ? value : EMPTY_VALUE;
   }

   // Sets the buffer value at the specified shift
   public: void setValue(const double value, const int shift) {
      m_buffer[shift] = value;
   }

   // Constructor: initializes buffer index
   public: CIndicatorBuffers() {
      m_indicatorBuffer = -1;
   }
};

//+------------------------------------------------------------------+
//| class to handle draw objects on the chart                        |
//+------------------------------------------------------------------+
class CObjectsHandle {
   // class private members
   private: string m_objectsName[], m_text, m_font;
   private: datetime m_time1;
   private: string m_objectName;
   private: double m_price1, m_price2, m_angle;
   private: color m_mainColor;
   private: bool m_back;
   private: int m_mainWidth, m_fontSize, m_subWindow;
   
   // Destructor
   public: ~CObjectsHandle() {
      const int numberOfObjects = ArraySize(m_objectsName);
      for (int i = 0; i <= numberOfObjects - 1; i++) {
         ObjectDelete(0, m_objectsName[i]);
      }
      
      ArrayResize(m_objectsName, 0);
      ArrayFree(m_objectsName);
   }
   
   // Initalizer
   public: void initialize() {
      m_subWindow = 0;
      m_text = NULL;
      m_font = NULL;
      m_time1 = 0;
      m_fontSize = 11;
      m_price1 = 0;
      m_price2 = 0;
      m_angle = 0.0;
      m_mainColor = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
      m_mainWidth = 1;
      m_back = true;
   }

   // Provides a write acess to the objects properties
   public: 
           void setPrice(const double price) {
              m_price1 = price;
           }
           void setSubWindow(const int subWindow) {
              m_subWindow = subWindow;
           }
           void setText(const string text) {
              m_text = text;
           }
           void setFont(const string font) {
             m_font = font;
           }
           void setFontSize(const int fontSize) {
             m_fontSize = fontSize;
           }
           void setAngle(const double angle) {
              m_angle = angle;
           }
           void setWidth(const int width) {
              m_mainWidth = width;
           }
           void setColor(const color clr) {
              m_mainColor = clr;
           }
           void setTime(const datetime time) {
              m_time1 = time;
           }
           void setBack(const bool back) {
              m_back = back;
           }

   // Create objects on chart
   public: void draw(const string label, const int index, const int objType) {
      const string objectName = getObjectName(index, label, objType);
      
      ObjectCreate(0, objectName, objType, m_subWindow, 0, 0);
      ObjectSet(objectName, OBJPROP_SELECTABLE, false);
      ObjectSet(objectName, OBJPROP_HIDDEN, true);
      ObjectSet(objectName, OBJPROP_WIDTH, m_mainWidth);
      ObjectSet(objectName, OBJPROP_COLOR, m_mainColor);
      ObjectSet(objectName, OBJPROP_BACK, m_back);
         
      // Object propertie selector based on object type
      switch (objType) {
         // hline properties
         case (OBJ_HLINE): {
            ObjectSet(objectName, OBJPROP_PRICE1, m_price1);
         }
         
         // vline properties
         case (OBJ_VLINE): {
            ObjectSet(objectName, OBJPROP_TIME1, m_time1);
         }
         
         // text properties
         case (OBJ_TEXT): {
            ObjectSet(objectName, OBJPROP_PRICE1, m_price1);
            ObjectSet(objectName, OBJPROP_TIME1, m_time1);
            ObjectSet(objectName, OBJPROP_ANGLE, m_angle);
            ObjectSetText(objectName, m_text, m_fontSize, m_font, m_mainColor);
         }
      }
      
      // registe the current object
      registerObject(objectName);
   }
   
   // Provides a acess do objects array list
   public: string getObjectId(const int shift) {
      if (shift > ArraySize(m_objectsName) - 1) return(NULL);
      const string objectName = m_objectsName[shift];
      
      return objectName;
   }

   // Provides a object registor
   private: void registerObject(const string objectName) {
      const int numberOfObjects = ArraySize(m_objectsName);
      ArrayResize(m_objectsName, numberOfObjects + 1);
      m_objectsName[numberOfObjects] = objectName;
   }
   
   // Get objects name for consistency
   private: string getObjectName(const int index, const string label, const int objType) const {
      return StringFormat("%s::%d - %d", label, index, objType);
   }

};


//+------------------------------------------------------------------+
//| Mars - money management                                          |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
