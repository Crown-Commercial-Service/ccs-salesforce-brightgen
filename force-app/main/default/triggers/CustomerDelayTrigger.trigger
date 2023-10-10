trigger CustomerDelayTrigger on Customer_Delay__c (before insert, before update) {

    BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];


if(trigger.isUpdate)
        {
            //Update is different to Insert - it also includes a check that only Start_Datetime and/or Stop_DateTime have changed ie. Changes to other fields do not trigger.


    for (Customer_Delay__c cdo : Trigger.new){
                
        if (cdo.Start_DateTime__c<>NULL && cdo.Stop_DateTime__c<>NULL

    && ((Trigger.Newmap.get(cdo.ID).Start_DateTime__c<>Trigger.Oldmap.get(cdo.ID).Start_DateTime__c)
        || (Trigger.Newmap.get(cdo.ID).Stop_DateTime__c<>Trigger.Oldmap.get(cdo.ID).Stop_DateTime__c))

            ){
        
        Long l = BusinessHours.diff(bh.ID, cdo.Start_DateTime__c, cdo.Stop_DateTime__c); //this is in Milliseconds - need to use Long as the number can be very large
        long minutes = l / 1000 / 60;
           
        Decimal d = decimal.valueof(minutes); //convert Long into Decimal, so that it can show two-decimal places on the hours and days calculations 
        cdo.Duration_Minutes__c = d;    
            
        d = d / 60; //hours  
        cdo.Duration_Hours__c = d;
        
        d = d / 8; //days 
        cdo.Duration_Days__c = d;    
        
        } // end If        
        
    } //end Loop

 }  //end Update activity


        if(trigger.isInsert)
        {
            //Just run the calculations

    for (Customer_Delay__c cdo : Trigger.new){
                
        if (cdo.Start_DateTime__c<>NULL && cdo.Stop_DateTime__c<>NULL ){
        
        Long l = BusinessHours.diff(bh.ID, cdo.Start_DateTime__c, cdo.Stop_DateTime__c); //this is in Milliseconds - need to use Long as the number can be very large
        long minutes = l / 1000 / 60;
           
        Decimal d = decimal.valueof(minutes); //convert Long into Decimal, so that it can show two-decimal places on the hours and days calculations 
        cdo.Duration_Minutes__c = d;    
            
        d = d / 60; //hours  
        cdo.Duration_Hours__c = d;
        
        d = d / 8; //days 
        cdo.Duration_Days__c = d;    
        
        } // end If        
        
    } //end Loop

}//    end Insert activity
               
  }