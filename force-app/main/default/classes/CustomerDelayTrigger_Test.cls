@isTest
public class CustomerDelayTrigger_Test {
    
    static testMethod void validateCustomerDelay(){   
        
        //New Test Account
        Account acc = new Account(Name = 'New Test Account', Sector__c = 'Wider Public Sector', Status__c = 'Active');
        
        insert acc;

        Contact con = new Contact(FirstName = 'Amorous', LastName = 'Aardvark', Email = 'tristam.hardman@crowncommercial.gov.uk', AccountID = acc.ID );
        
        insert con;
        
        Case cas = new Case(ContactID = con.ID, AccountID = acc.ID, Status = 'In Progress');  //Status is newly added to test
        
        insert cas;
        
        //Create a new Customer Delay
        Customer_Delay__c cusdel1 = new Customer_Delay__c();
        cusdel1.Procurement__c = cas.ID;
        cusdel1.Start_DateTime__c = DateTime.newInstance(2018,11,7,0,0,0); //A Wednesday
        insert cusdel1;
        
        
        //The newly create Customer Delay only has a Start_DateTime - so the Duration should still be NULL.
        cusdel1 = [SELECT Start_DateTime__c, Stop_DateTime__c, Duration_Days__c, Duration_Hours__c FROM Customer_Delay__c WHERE ID =:cusdel1.ID ];
        system.debug(cusdel1.Start_DateTime__c);
        system.debug(cusdel1.Stop_DateTime__c);
        system.debug(cusdel1.Duration_Days__c);
        system.assertEquals(cusdel1.Duration_Days__c, NULL);
        system.assertEquals(cusdel1.Duration_Hours__c, NULL);
        
        //Now update the Stop_DateTime - this should cause the Trigger to calculate the Duration fields.
        //Customer Delay must also be closed - There is a Validation that prevents a Stop Date being populated unless Status is closed.
        cusdel1.Stop_DateTime__c = DateTime.newInstance(2018,11,14,0,0,0); //One calendar week later = 5 working days = 40 working hours
        cusdel1.Status__c = 'Closed';
        cusdel1.Customer_Delay_Reason__c = 'Customer_Unavailable'; //Added due to failure found when deploying to QA
        
        update cusdel1;
        
        cusdel1 = [SELECT Start_DateTime__c, Stop_DateTime__c, Duration_Days__c, Duration_Hours__c FROM Customer_Delay__c WHERE ID =:cusdel1.ID ];
        
        system.debug(cusdel1.Start_DateTime__c);
        system.debug(cusdel1.Stop_DateTime__c);
        system.debug(cusdel1.Duration_Days__c);
        system.assertEquals(cusdel1.Duration_Days__c, 5);
        system.assertEquals(cusdel1.Duration_Hours__c, 40);
         
        
        //Now update both the Start_DateTime and Stop_DateTime and check that the Durations recalculate correctly
        cusdel1.Start_DateTime__c = DateTime.newInstance(2018,11,8,0,0,0); //A Thursday
        cusdel1.Stop_DateTime__c = DateTime.newInstance(2018,11,22,0,0,0); //Two calendars week later = 10 working days = 80 working hours
        
        update cusdel1;
        
        cusdel1 = [SELECT Start_DateTime__c, Stop_DateTime__c, Duration_Days__c, Duration_Hours__c FROM Customer_Delay__c WHERE ID =:cusdel1.ID ];
        
        system.debug(cusdel1.Start_DateTime__c);
        system.debug(cusdel1.Stop_DateTime__c);
        system.debug(cusdel1.Duration_Days__c);
        system.assertEquals(cusdel1.Duration_Days__c, 10);
        system.assertEquals(cusdel1.Duration_Hours__c, 80);
        
        
        //Now create another customer delay, but this time with both Start_DateTime and Stop_Date populated from the outset
        //This would only happen if the user used "New" button (which will be hidden) or "Save & New" (which cannot be hidden)
        //This will test the 'Insert' element of the Trigger
        Customer_Delay__c cusdel2 = new Customer_Delay__c();
        cusdel2.Procurement__c = cas.ID;  //Status of cusdel1 is closed
        cusdel2.Start_DateTime__c = DateTime.newInstance(2018,11,8,0,0,0); //A Thursday
        cusdel2.Stop_DateTime__c = DateTime.newInstance(2018,11,22,0,0,0); //Two calendars week later = 10 working days = 80 working hours
        cusdel2.Status__c = 'Closed';
        cusdel2.Customer_Delay_Reason__c = 'Customer_Unavailable'; //Added due to failure found when deploying to QA
        
        insert cusdel2;
        
        cusdel2 = [SELECT Start_DateTime__c, Stop_DateTime__c, Duration_Days__c, Duration_Hours__c FROM Customer_Delay__c WHERE ID =:cusdel2.ID ];
      
        system.debug(cusdel2.Start_DateTime__c);
        system.debug(cusdel2.Stop_DateTime__c);
        system.debug(cusdel2.Duration_Days__c);
        system.assertEquals(cusdel2.Duration_Days__c, 10);
        system.assertEquals(cusdel2.Duration_Hours__c, 80);
    }

}