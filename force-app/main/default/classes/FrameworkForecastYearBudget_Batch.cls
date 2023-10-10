/*********************************************************************
 Name:  FrameworkForecastYearBudget_Batch
 Copyright © 2017  Salesforce
 ======================================================
 ======================================================
 Purpose: Batch class to create or replace budget forecast records executed from a custom button                                                      
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Nic Flook   		2017-01-30     	 Initial version 	
 *********************************************************************/
 
global class FrameworkForecastYearBudget_Batch Implements Database.Batchable<Sobject>, Database.Stateful{

    global final String query;
    global final String liveRt;
    global final String budgetRt;
    global final string[] frameworkIds;
    global String businessPlanYear;

    global FrameworkForecastYearBudget_Batch(String[] selectedFrameworkIds, String selectedYear)
    {
    	// Assign the passed parameter to a global variable 
    	businessPlanYear = selectedYear;
    	
		// Get record types for our framework forecast years
		Map<String,Id> ffYearRecordTypes = FrameworkForecastUtil.getRecordTypeIdsByDeveloperName(Framework_Forecast_Year__c.SObjectType);
			
		liveRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Live);
		budgetRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Budget);
		
        this.frameworkIds = selectedFrameworkIds;
        
        // grab all the forecasts that need budget records to be created by querying the forecast object - move to utils and include set creator
       	List<Framework_Forecast__c> forecastsForBatchList = [SELECT ID 
        					FROM Framework_Forecast__c 
        					WHERE Live_Record_Count__c > 0 AND Business_Plan_Year__c =: businessPlanYear AND Framework__c in: frameworkIds];
        					
        // Put the resulting framework forecast records into a set of Ids
		Set<Id> forecastIds = (new Map<Id,SObject>(forecastsForBatchList)).keySet();
      
        // This will be our final query that will get all of our forecast year records
        query = 	'SELECT ID, Name, Business_Plan_Year__c' +
        			' FROM Framework_Forecast__c' + 
        			' WHERE Live_Record_Count__c > 0 AND Business_Plan_Year__c = :businessPlanYear AND Framework__c IN :frameworkIds';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Framework_Forecast__c> scope)
    {
         //Set a setpoint so we can rollback if anything fails
         system.Savepoint sp = Database.setSavepoint();
       	
         boolean removeSuccess = false;
         String errMsg = '';
        
    	try
    	{
	        // GET A LIST OF RECORDS TO REMOVE
	        
	         // Use the forecastYears to make a set for an argument to get forecastYearIds - 
	     	Set<Id> forecastYearIds = (new Map<Id,SObject>(scope)).keySet();
	       	
	       	List<Framework_Forecast_Year__c> budgetYearsforProcessing = FrameworkForecastUtil.getFrameworkForecastYearsForBatch(forecastYearIds, budgetRt);
	        
	        // Remove existing budget forecasts and replace them with new clones
	        delete budgetYearsForProcessing;
	        
	        removeSuccess = true;
    
    	}
        catch(Exception e)
        {
        	
        	// Back to the save point if something has gone wrong.
        	Database.rollback(sp);
        	callException(e.getmessage());
        	
        }
        	
        
        if(removeSuccess)
        {	
       			try
       			{
       			 	// Create or update a budget forecast
		        	set<Id> forecastYearIds = (new Map<Id,SObject>(scope)).keySet();
		         
		        	// GET A LIST OF RECORDS TO CLONE
		       		List<Framework_Forecast_Year__c> liveYearsForProcessing = FrameworkForecastUtil.getFrameworkForecastYearsForBatch(forecastYearIds, liveRt);
		        
		        	// The result here will be inserted by the try catch
		   			List<Framework_Forecast_Year__c> budgetYearsForInsert = new List<Framework_Forecast_Year__c>();
		       	       
		       		//cloning Related Framework Forecast Records eligible for snapshotting: needs to be updated to include a dynamic soql for all fields
		       
		     		for(Framework_Forecast_Year__c f : liveYearsForProcessing)
		       		{
		         		Framework_Forecast_Year__c ffClone = f.clone(false,true);
		         
		         		ffClone.RecordTypeId = budgetRt;
		         		budgetYearsForInsert.add(ffClone);
		       	 	}
			       
			    	insert budgetYearsForInsert;
       			}
       			catch(Exception e)
       			{	
       				// Back to the save point if something has gone wrong.
        			Database.rollback(sp);
					callException(e.getmessage());
       			}	 
        }
	}

    global void finish(Database.BatchableContext BC){}
    
	@TestVisible private void callException(String errMsg) 
	{
		ExceptionLoggingHelper.createErrorLog(UserInfo.getUserId(), FrameworkForecastYearBudget_Batch.class.toString(), '', errMsg, new ForecastYearBudgetException(errMsg),'ERROR', null, null, (Integer)DateTime.now().getTime(), null);
	}
	
	public class ForecastYearBudgetException extends Exception {}

}