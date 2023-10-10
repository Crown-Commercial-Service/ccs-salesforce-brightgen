/*********************************************************************
 Name:  FrameworkGenerateBudget
 Copyright © 2017  Salesforce
 ======================================================
 ======================================================
 Purpose: Receive framework Ids and a selected business plan year from a custom button popup and kick off the FrameworkForecastYearBudget_Batch process                                                      
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Nic Flook   		2017-01-30     	 Initial version 	
 *********************************************************************/

global with sharing class FrameworkGenerateBudget {

    public static void callBudgetBatch(List<Id> selectedFrameworkIds, string selectedYear) {

        Database.executeBatch(new FrameworkForecastYearBudget_Batch(selectedFrameworkIds, selectedYear), 100);
    }
}