extern int Order_Expire_Time=180;

void ScanTradeForExpiry()
{
  for(int x=0;x<=OrdersTotal();x++)
      {
      OrderSelect(x,SELECT_BY_POS,MODE_TRADES);
      
      int y= TimeCurrent()-OrderOpenTime();
     if (OrderType()>1 && y>300 ) 
              OrderDelete(OrderTicket()); 
       }
 }
int start()                                     
  {
ScanTradeForExpiry();
  return(0);
}

