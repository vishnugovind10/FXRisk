extern int Order_Expire_Time=180;

void ScanTradeForExpiry()
{
    int type   = OrderType();
    bool result = false;
    
  for(int x=0;x<=OrdersTotal();x++)
      {
      OrderSelect(x,SELECT_BY_POS,MODE_TRADES);
      
      int y= TimeCurrent()-OrderOpenTime();
     if (OrderType()<=1 && y>300 && OrderProfit()>10) 
              { 
              switch(type)
               {
                 //Close opened long positions
                 case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                          break;
      
                 //Close opened short positions
                case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                          break;

     
                  }
               
               }
       }
 }
int start()                                     
  {
ScanTradeForExpiry();
  return(0);
}

