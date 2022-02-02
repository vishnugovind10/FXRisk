#define LOTMSGCOLOR Crimson

extern bool   UseFixedPipStopLoss = false; //  Set to true to use FixedPipsForRisk (Uses ATR in this example if false)
extern int    FixedPipsForRisk = 20;       //  Value for user chosen Pip Value example
extern int    TicksInAPip = 0;             //  it is usually 10 or 1; 10 if the broker supports fractional pips.  calculate if 0.  Need more direct formula to get this.
extern int    EquityRiskPercent = 2;       //  Percent of account equity to risk on a trade
extern int    MaxMarginPercentToUse = 30;  //  How much of the maximum Margin available should be used?
extern int    ATRBars = 10;                //  Number of bars to include in the ATR indication.
extern int    debugLevel = 1;              //  display debug info if not 0, program recognizes 0, 1 and 2 (greater than 1)
extern int    timeBetweenUpdates = 10;     //  seconds to wait between executing an update of the RefreshRates.

double riskToTake;   // convert risk Percent to a decimal value and store it here.
double dealerMaxLots; // Make it global just so it can be displayed.
double marginPctToUse;  // used to convert MaxMarginPercentToUse to a decimal value.
string refreshRates;  // see value of RefreshRates()
string lotSizeMessage; // for comment display
int    lastUpdateTime=0;
int    executionTime;
int    commentExecutionTime;
string executionMsgText;

string newLine = "\n";

int init()
{
   riskToTake = EquityRiskPercent;
   riskToTake = riskToTake/100;  // divide by 100 to put int percent into a decimal.
   marginPctToUse = MaxMarginPercentToUse;
   marginPctToUse = marginPctToUse/100;  // divide by 100 to put int percent into a decimal.
   timeBetweenUpdates = timeBetweenUpdates*1000; // change from seconds to milliseconds.
   return(0);
}

int deinit()
{
   ObjectDelete("LotSizeMsg");
   ObjectDelete("EquityRiskMsg");
   ObjectDelete("MarginLotLimitMsg");
   ObjectDelete("ExecutionMessage");
   return(0);
}

int start()
{
   executionTime = GetTickCount();
   double ticksInRisk;  //  Find the # of ticks between the entry and stop loss positions
   if (UseFixedPipStopLoss)
   {
      ticksInRisk = PipsToTicks(FixedPipsForRisk);
   } else
   {
       ticksInRisk = iATR(Symbol(), Period() , ATRBars, 0);
   }

   double lotsToOpen = LotsToOpen(riskToTake, ticksInRisk, marginPctToUse);  // Get the lots that can be opened for a Risk

   // The rest of "start()" is simply for display
    
   // Make ticksInRisk into an integer for display
   double minTickSize = MarketInfo(Symbol(), MODE_TICKSIZE);  // pre-calculate to use in the next line
   if (!minTickSize) // Broker didn't provide a value - Guess at a value
      minTickSize = GetDefaultValue("MODE_TICKSIZE");
   int ticksInRiskCount = MathFloor(ticksInRisk/minTickSize);          // Make an integer of ticksInRisk for display 

   string lotsToTradeText = MakeLotsToTradeText(lotsToOpen,ticksInRiskCount);
   DisplayObject("LotSizeMsg",lotsToTradeText,10,20);
   
   if ( debugLevel > 0 )
   {
      string equityRiskMsg = StringConcatenate("Your Equity Risk Limit is ",MaxtLotsForRisk(riskToTake, ticksInRisk)," lots");
      DisplayObject("EquityRiskMsg",equityRiskMsg,10,40);
      
      string marginLimitMsg = StringConcatenate("Your Margin Risk limit is ",MaxLotsThatCanBeOpened(marginPctToUse)," lots");
      DisplayObject("MarginLotLimitMsg",marginLimitMsg,10,60);
      
      DisplayObject("ExecutionMessage",executionMsgText,10,80);
   }
   DisplayComment();
   executionTime = GetTickCount()-executionTime;
   executionMsgText = StringConcatenate("Execution Time = ",executionTime," milliseconds"); 
   return(0);
}
void DisplayObject(string objectLabel,string displayText, int xPos, int yPos)
{
   if (ObjectFind(objectLabel)!= 0) // Look for the object on the current chart
   {
      ObjectCreate(objectLabel, OBJ_LABEL, 0, 0, 0, 0, 0, 0, 0); // On the Current Chart
      ObjectSet(objectLabel, OBJPROP_CORNER, 1);   // top right Corner
      ObjectSet(objectLabel, OBJPROP_XDISTANCE, xPos);  // justify at xPos from the right
      ObjectSet(objectLabel, OBJPROP_YDISTANCE, yPos);  // place at yPos from the top 
   }
   //bool ObjectSetText( string name, string text, int font_size, string font=NULL, color text_color=CLR_NONE) 
   ObjectSetText(objectLabel, displayText, 11, "Times New Roman", LOTMSGCOLOR);  // display latest calculation
}

string MakeLotsToTradeText(double lotsToOpen,int ticksInRiskCount)
{
   string tradeLotsMsg;
   if (!lotsToOpen)  // cannot open any lots with the risk parameters set
   {
      if (UseFixedPipStopLoss)  // different messages for how the risk is expressed
         lotSizeMessage = StringConcatenate("You do not have enough risk capital to trade Any Lots with Risk of ",
            FixedPipsForRisk," pips.");
      else
         lotSizeMessage = StringConcatenate("You do not have enough risk capital to trade Any Lots with Risk of ",
            EquityRiskPercent," percent.");
      tradeLotsMsg = "Trade 0 Lots";    //  Message to display on the screen
   } else  // You can open lots
   {
      if (UseFixedPipStopLoss)  // different messages for how the risk is expressed, Fixed Pips, or a tick calculation (ATR in this code)
         lotSizeMessage = StringConcatenate("You Can Trade Up To ", DoubleToStr(lotsToOpen,3),  //  fixed Pips Risk Message
            " lots with your risk setting of ",FixedPipsForRisk," pips (",ticksInRiskCount," ticks) ",
            EquityRiskPercent," percent equity risk and a maximum of ",MaxMarginPercentToUse, " percent of Margin to use.");
      else
         lotSizeMessage = StringConcatenate("You Can Trade Up To ", DoubleToStr(lotsToOpen,3), //  Calculate risk message
            " lots with your risk setting of ",EquityRiskPercent," percent equity risk,",
            ticksInRiskCount," ticks in the risk, and a maximum of ", MaxMarginPercentToUse, " percent of Margin to use.");
     tradeLotsMsg = StringConcatenate("Trade ", DoubleToStr(lotsToOpen,3)," Lots."); //  Message to display on the screen
   }
   return(tradeLotsMsg);
}

void DisplayComment()
{
   if ( debugLevel>1)
   {
      commentExecutionTime = GetTickCount();
      if ( UpdateOnTime() )
      {
         if ( RefreshRates() )  // Check if MarketInfo had updated since last cached.
            refreshRates = "True";
         else
            refreshRates = "False";
      }
      Comment( // "    ", lotSizeMessage, newLine,
            "MarketInfo Values",newLine,
//            "    MODE_LOW:               ", DoubleToStr(MarketInfo(Symbol(), MODE_LOW),8),", Low day price", newLine,
//            "    MODE_HIGH:              ", DoubleToStr(MarketInfo(Symbol(), MODE_HIGH),8),", High day price", newLine,
//            "    MODE_TIME:              ", DoubleToStr(MarketInfo(Symbol(), MODE_TIME),8),", Last known server time", newLine,
//            "    MODE_POINT:             ", DoubleToStr(MarketInfo(Symbol(), MODE_POINT),8),", Point size in the quote currency", newLine,
//            "    MODE_DIGITS:            ", DoubleToStr(MarketInfo(Symbol(), MODE_DIGITS),8),", Count of digits after decimal point", newLine,
//            "    MODE_SPREAD:            ", DoubleToStr(MarketInfo(Symbol(), MODE_DIGITS),8),", Spread value in points.", newLine,
            "    MODE_STOPLEVEL:         ", DoubleToStr(MarketInfo(Symbol(), MODE_STOPLEVEL),8),", Stop level in points", newLine,
            "    MODE_LOTSIZE:           ", DoubleToStr(MarketInfo(Symbol(), MODE_LOTSIZE),8),", Lot size in the base currency", newLine,
            "    *MODE_TICKVALUE:        ", DoubleToStr(MarketInfo(Symbol(), MODE_TICKVALUE),8), ", Tick value in the deposit currency", newLine,
            "    *MODE_TICKSIZE:         ", DoubleToStr(MarketInfo(Symbol(), MODE_TICKSIZE),8), ", Tick size in the quote currency", newLine,
//            "    MODE_SWAPLONG:          ", DoubleToStr(MarketInfo(Symbol(), MODE_SWAPLONG),8),", Swap of the long position", newLine,
//            "    MODE_SWAPSHORT:         ", DoubleToStr(MarketInfo(Symbol(), MODE_SWAPSHORT),8),", Swap of the short position", newLine,
//            "    MODE_STARTING:          ", DoubleToStr(MarketInfo(Symbol(), MODE_STARTING),8),", Market starting date (usually used for futures", newLine,
//            "    MODE_EXPIRATION:        ", DoubleToStr(MarketInfo(Symbol(), MODE_EXPIRATION),8),", Market expiration date (usually used for futures)", newLine,
//            "    MODE_TRADEALLOWED:      ", DoubleToStr(MarketInfo(Symbol(), MODE_TRADEALLOWED),8),", Trade is allowed for the symbol", newLine,
            "    *MODE_MINLOT:           ", DoubleToStr(MarketInfo(Symbol(), MODE_MINLOT),8),", Minimum permitted amount of a lot", newLine,
//            "    MODE_LOTSTEP:           ", DoubleToStr(MarketInfo(Symbol(), MODE_LOTSTEP),8),", Step for changing lots", newLine,
            "    *MODE_MAXLOT:           ", DoubleToStr(MarketInfo(Symbol(), MODE_MAXLOT),8),", Maximum permitted amount of a lot", newLine,
//            "    MODE_SWAPTYPE:          ", DoubleToStr(MarketInfo(Symbol(), MODE_SWAPTYPE),8),", Swap calculation method", newLine,
//            "    MODE_PROFITCALCMODE:    ", DoubleToStr(MarketInfo(Symbol(), MODE_PROFITCALCMODE),8),", Profit calculation mode (0 - Forex)", newLine,
//            "    MODE_MARGINCALCMODE:    ", DoubleToStr(MarketInfo(Symbol(), MODE_MARGINCALCMODE),8),", Margin calculation mode (0 - Forex)", newLine,
            "    MODE_MARGININIT:        ", DoubleToStr(MarketInfo(Symbol(), MODE_MARGININIT),8),", Initial margin requirements for 1 lot", newLine,
            "    MODE_MARGINMAINTENANCE: ", DoubleToStr(MarketInfo(Symbol(), MODE_MARGINMAINTENANCE),8),", Margin to maintain open positions calculated for 1 lot", newLine,
//            "    MODE_MARGINHEDGED:      ", DoubleToStr(MarketInfo(Symbol(), MODE_MARGINHEDGED),8),", Hedged margin calculated for 1 lot", newLine,
            "    *MODE_MARGINREQUIRED:   ", DoubleToStr(MarketInfo(Symbol(), MODE_MARGINREQUIRED),8),", Free margin required to open 1 lot for buying", newLine,
            "    MODE_FREEZELEVEL:       ", DoubleToStr(MarketInfo(Symbol(), MODE_LOW),8),", Order freeze level in points", newLine,
            "*Account Equity:            ", DoubleToStr(AccountEquity(),8), newLine,
            "*Account Levreage:          ", DoubleToStr(AccountLeverage(),8), newLine,
            "Account Margin:             ", DoubleToStr(AccountMargin(),8), newLine,
            "*Account FreeMargin:        ", DoubleToStr(AccountFreeMargin(),8), newLine,
            "*ATR:                       ", DoubleToStr(iATR(Symbol(), Period() , ATRBars, 0),8), newLine,
            "RefreshRates():             ", refreshRates, newLine,
            "Comment Execution Time:     ", (GetTickCount()-commentExecutionTime)," milliseconds"
          );
   }
}

bool UpdateOnTime()
{
   if ( (GetTickCount()- lastUpdateTime) > timeBetweenUpdates)
   {
      lastUpdateTime = GetTickCount();
      return(true);
   }else
   {
      return(false);
   }
}

double MaxLotsThatCanBeOpened(double maxMarginPct)
{
   double accountFreeMargin = AccountFreeMargin();       //  Total Margin Available
   if (!accountFreeMargin)  // Broker didn't provide a value - Guess at a value
      accountFreeMargin = GetDefaultValue("ACCOUNTFREEMARGIN");
   accountFreeMargin = accountFreeMargin * maxMarginPct;  // reduce to the max desired to use in any trade.
   
   double marginToOpenALot = MarketInfo(Symbol(), MODE_MARGINREQUIRED);  //Margin required to open a lot
   if (!marginToOpenALot)  // Broker didn't provide a value - Guess at a value
      marginToOpenALot = GetDefaultValue("MODE_MARGINREQUIRED");

   double accountLeverage = AccountLeverage();              // Leverage provided for the account
   if (!accountLeverage)  // Broker didn't provide a value - Guess at a value
      accountLeverage = GetDefaultValue("ACCOUNTLEVERAGE");
   
   double minLotSize = MarketInfo(Symbol(), MODE_MINLOT);   // What is the size of the smallest part of a lot available
   if (!minLotSize)  // Broker didn't provide a value - Guess at a value
      minLotSize = GetDefaultValue("MODE_MINLOT");
   
   double maxLotsThatCanBeOpened = (accountFreeMargin/marginToOpenALot); // I'm pretty sure this will be less than MarketInfo(Symbol(), MODE_MAXLOT), but check
   dealerMaxLots = MarketInfo(Symbol(), MODE_MAXLOT);      // Find the maximum lots the broker will allow in an order.
   if (!dealerMaxLots)  // Broker didn't provide a value - Guess at a value
      dealerMaxLots = GetDefaultValue("MODE_MAXLOT");
      
   if (maxLotsThatCanBeOpened > dealerMaxLots)             // Make sure the lots are less than the maximum the broker will allow.
      maxLotsThatCanBeOpened = dealerMaxLots;              // assign the smaller amount.
   
   //Get rid of the digits beyond the mininum Lot Step.
   maxLotsThatCanBeOpened = MathFloor(maxLotsThatCanBeOpened/minLotSize); // Made maximum significant digits be on Whole Number side of decimal point.
   maxLotsThatCanBeOpened = maxLotsThatCanBeOpened * minLotSize;  //  Put fractions of a lot back in decimal.  Now there are no digits beyond smallest allowed.
   return (maxLotsThatCanBeOpened); 
}

double LotsToOpen(double riskLevel, double ticksToRisk, double maxMarginPct)
{  
   double maxLotsThatCanBeOpened = MaxLotsThatCanBeOpened(maxMarginPct);    // Find the maximum # of lots that can be opened with margin parameters
   double lotsForRisk = MaxtLotsForRisk(double riskLevel, double ticksToRisk);
                      // Cannot Open any lots (or part of a lot) with the specified risk
   if ( lotsForRisk > maxLotsThatCanBeOpened )   // Largest Position that can be opened
      lotsForRisk = maxLotsThatCanBeOpened;      // Reduce to the Largest Position that can be opened.

   return(lotsForRisk);
}

double MaxtLotsForRisk(double riskLevel, double ticksToRisk)
{
   double minPartOfLotSize = MarketInfo(Symbol(), MODE_MINLOT); // Smallest part of a lot that can be opened.
   if (!minPartOfLotSize)  // Broker didn't provide a value - Guess at a value
      minPartOfLotSize = GetDefaultValue("MODE_MINLOT");
      
   double oneTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);  // Get the value of a single tick
   if (!oneTickValue)  // Broker didn't provide a value - Guess at a value
      oneTickValue = GetDefaultValue("MODE_TICKVALUE");
   
   double totalRiskEquity = AccountEquity();                    // Get the total account Equity.  Some may choose Open Margin instead.
                                                                // double AccountFreeMargin() gives the total open margin 
   if (!totalRiskEquity) // Broker didn't provide a value - Guess at a value
      totalRiskEquity = GetDefaultValue("ACCOUNTEQUITY");
   
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   if (!tickSize) // Broker didn't provide a value - Guess at a value
      tickSize = GetDefaultValue("MODE_TICKSIZE");
      
   int riskTickCount = ticksToRisk/tickSize; // Make the ticks-to-risk into an Integer
   // the value of one tick - oneTickValue - must be the price movement of a single tick on the mininum part of a lot that can be opened.
   double minMovementCost = riskTickCount * oneTickValue;     // Minumum amount of money for the price movement in the risk.
   double baseCurrencyToRisk = riskLevel * totalRiskEquity;   // Total Money available for the price movememenmt.
   double lotsForRisk = (baseCurrencyToRisk)/minMovementCost; // lots that the risk money can cover.
   
   lotsForRisk = MathFloor(lotsForRisk/minPartOfLotSize) * minPartOfLotSize;   /* removes digits that are too insignificant.
      could use NormalizeDouble, but this allows us to do it without knowing the actual number of significant digits. */
   if ( lotsForRisk < minPartOfLotSize )     // smallest possible part of a lot to open
      lotsForRisk = 0;
   
   return(lotsForRisk); 
 }

double PipsToTicks(int FixedPipsForRisk)
{
   double ticksInAPip = TicksInOnePip();  /* Get the Number of ticks in One Pip.  Should be 1 (traditional) or 10 (fractional).
     Market Makers are offering Fractional Pip accounts, and calling those Pips.  I'd like to keep with a common
     definition (value) of a pip everywhere - generally the 5th significant digit in a price quote on the major
     currency pairs */
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   if (!tickSize) // Broker didn't provide a value - Guess at a value
      tickSize = GetDefaultValue("MODE_TICKSIZE");
   return((FixedPipsForRisk*ticksInAPip) * tickSize);  
}

int TicksInOnePip()
{  //  there should be a programatic way to get this for an account.
   // shouldn't have to guess based on Digits or $, or rely on user input.
   if (!TicksInAPip)  // no user supplied value, guess on one.
   {
      if ( (Digits==5) || (Digits==3) )
      {
         return(10);
      } else
      {
        return(1);
      }
   } else            // return the user supplied value.
   {
      if (TicksInAPip >0)
         return(TicksInAPip);
      else
         return(10);
   }
}

double GetDefaultValue(string valueToGet)  
{
   double returnValue;
   if ( valueToGet == "ACCOUNTFREEMARGIN" )
   {
         returnValue = 100;  // No Way I know of to Guess
         if (debugLevel > 0)
            Print("AccountFreeMargin() returned 0, assigned ",returnValue);
   } else if ( valueToGet == "MODE_MARGININIT" )
   {
      returnValue = MarketInfo(Symbol(),MODE_MARGINREQUIRED);
      if (!returnValue) //  Still no value assigned
         returnValue = 100000/50;  // Probably provides at least 50:1 leverage
      if (debugLevel > 0)
         Print("MarketInfo MODE_MARGININIT returned 0, assigned ",returnValue);
   }else if ( valueToGet == "MODE_MARGINREQUIRED" )
   {
      returnValue = 100000/50;  // Probably provides at least 50:1 leverage
      if (debugLevel > 0)
         Print("MarketInfo MODE_MARGINREQUIRED returned 0, assigned ",returnValue);
   } else if ( valueToGet == "MODE_MINLOT" )
   {
         if ( (Digits == 5) || (Digits == 3) )
            returnValue = 0.01;
         else
            returnValue = 0.1;
         if (debugLevel > 0)
            Print("MarketInfo MODE_MINLOT returned 0, assigned ",returnValue);
   } else if ( valueToGet == "MODE_MAXLOT" )
   {
         returnValue = 10;
         if (debugLevel > 0)
            Print("MarketInfo MODE_MAXLOT returned 0, assigned ",returnValue);
   } else if ( valueToGet == "MODE_TICKVALUE" )
   {
         returnValue = MathPow(10,-Digits);
         if (debugLevel > 0)
            Print("MarketInfo MODE_TICKVALUE returned 0, assigned ",returnValue);
   } else if ( valueToGet == "MODE_TICKSIZE" )
   {
         returnValue = MathPow(10,-Digits);
         if (debugLevel > 0)
            Print("MarketInfo MODE_TICKSIZE returned 0, assigned ",returnValue);
   } else if ( valueToGet == "ACCOUNTEQUITY" )
   {
         returnValue = 1000;
         if (debugLevel > 0)
            Print("AccountEquity() returned 0, assigned ",returnValue);
   } else if ( valueToGet == "ACCOUNTLEVERAGE" )
   {
         returnValue = 50;
         if (debugLevel > 0)
            Print("AccountLeverage() returned 0, assigned ",returnValue);
   } else // default
   {
         returnValue = 0;
         Print("Default, theres nothing for it (",valueToGet,") returning ",returnValue);
   }
   return(returnValue);
}
//+------------------------------------------------------------------+

