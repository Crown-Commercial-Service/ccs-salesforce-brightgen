/*********************************************************************
 Name:  FrameworkBudgetButtonController
 Copyright © 2017  Salesforce
 ======================================================
 ======================================================
 Purpose: Custom controller to support framework budget custom button values                                                      
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Nic Flook   		2017-01-30     	 Initial version 	
 *********************************************************************/
 
global with sharing class FrameworkBudgetButtonController {
    
    global String selectedYear {get; set;}
    global boolean showBatchExecutedMessage {get;set;}
  	global String[] selectedFrameworkIds {
        get {
            	if(selectedFrameworkIds == null) 
            	{
                	String s = ApexPages.currentPage().getParameters().get('ids');
                	if(s != null) 
                	{
                    	selectedFrameworkIds = s.split(',');
                	}
                	else 
                	{
                    	selectedFrameworkIds = new String[] {};
               		}
            }
            return selectedFrameworkIds;
        }
        private set;
    }
    
    
	/*******************************************************************
	Purpose: Get the business years and make them available to a picklist in the custom button vf page
	Parameters: N/A
	Returns: businessPlanYears
	Throws [Exceptions]: N/A
	********************************************************************/

    public List<SelectOption> getBusinessPlanYears()
	{
  		List<SelectOption> options = new List<SelectOption>();
        
   		Schema.DescribeFieldResult fieldResult =
 		Framework_Forecast__c.Business_Plan_Year__c.getDescribe();
   		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
  		for( Schema.PicklistEntry f : ple)
   		{
      		options.add(new SelectOption(f.getLabel(), f.getValue()));
   		}   
   	
   		return options;
	}
	
	/*******************************************************************
	Purpose: Kick off the batch process to create the budget records for selected frameworks and business plan year
	Parameters: N/A
	Returns: N/A
	Throws [Exceptions]: N/A
	********************************************************************/
     
    public void createBudgetRecords()
    {
    	showBatchExecutedMessage = false;
    	
    	if(selectedYear != null && selectedFrameworkIds != null)
    	{
    		FrameworkGenerateBudget.callBudgetBatch(selectedFrameworkIds, selectedYear);
    	
    		showBatchExecutedMessage = true;
    	}
    }
}