//+------------------------------------------------------------------+
//|                                                     CloseAll.mq4 |
//+------------------------------------------------------------------+

#property show_inputs

extern int option = 0;
//+------------------------------------------------------------------+
// Set this prameter to the type of clsoing you want:
// 0- Close all (instant and pending orders) (Default)
// 1- Close all instant orders
// 2- Close all pending orders
// 3- Close by the magic number
// 4- Close by comment
// 5- Close orders in profit
// 6- Close orders in loss
// 7- Close not today orders
//+------------------------------------------------------------------+

extern int magic_number = 0; // set it if you'll use closing option 3 - closing by magic number
extern string comment_text = ""; // set it if you'll use closing option 4 - closing by comment

int start()
  {
   CloseAll();
   return(0);
  }
//+------------------------------------------------------------------+

int CloseAll()
{
   int total = OrdersTotal();
   int cnt = 0;
 
   RefreshRates();
   
   switch (option)
   {
      case 0:
            for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL) //pending orders
                     OrderDelete(OrderTicket());
            }

         break;
      case 1:
            for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
            }
         break;
      case 2:
            for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
            }
         break;
      case 3:
         for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
               if (OrderMagicNumber() == magic_number)
               {
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
               }
            }         
            break;
      case 4:
         for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
               if (OrderComment() == comment_text)
               {
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
               }
            }         
         break;
      case 5:
         for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
               if (OrderProfit() > 0)
               {
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
               }
            }         
         break;
      case 6:
         for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
               if (OrderProfit() < 0)
               {
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
               }
            }         
         break;
      case 7:
         for (cnt = 0 ; cnt <= total ; cnt++)
            {
               OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
               if (TimeDay(OrderOpenTime()) < TimeDay(CurTime()))
               {
                  if(OrderType()==OP_BUY)
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),5,Violet);
                  if(OrderType()==OP_SELL) 
                     OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),5,Violet);
                  if(OrderType()>OP_SELL)
                     OrderDelete(OrderTicket());
               }
            }         
         break;
   }
}