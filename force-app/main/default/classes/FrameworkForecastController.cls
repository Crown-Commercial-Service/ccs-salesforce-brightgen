/*********************************************************************
 Name:  FrameworkForecastController
 Copyright © 2017  Salesforce
 ======================================================
 ======================================================
 Purpose: Provide custom controller support for maintaining Framework Forecast Year records through a visualforce UI.                                                      
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Nic Flook   		2017-01-30     	 Initial version 	
 *********************************************************************/

public with sharing class FrameworkForecastController {
    
    public Framework_Forecast__c frameworkForecast {get; set;}
   
	// A list of Forecast Year actual records
   	public List<Framework_Forecast_Year__c> ffActuals{get; set;}
   	
   	// A list of Forecast Year live records
   	public List<Framework_Forecast_Year__c> ffLive{get; set;}
   	
   	// A list of Forecast Year budget records
   	public List<Framework_Forecast_Year__c> ffBudget{get; set;}
   	
   	public Id frameworkForecastId {get;set;}
   	public String liveRt {get;set;}
	public String actualRt {get;set;}
	public String budgetRt {get;set;}
    public Boolean hasForecastYears {get;set;}
   	public List<Framework_Forecast_Year__c> relativeYears {get;set;}
	public FrameworkForecastController() {
	
		// Get record types for our framework forecast years
		Map<String,Id> ffYearRecordTypes = FrameworkForecastUtil.getRecordTypeIdsByDeveloperName(Framework_Forecast_Year__c.SObjectType);
			
		liveRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Live);
		actualRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Actual);
		budgetRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Budget);
					
		// Define hasForecastYears as false for safety - at least they can't 
		// create new forecast live records and we can assess whether there is anything to edit later		
		hasForecastYears = false; 
		
		
		// Get the Framework Forecast Id from the current page parameter
		
		frameworkForecastId = ApexPages.currentPage().getParameters().get('frameworkForecastId');
			
		if(frameworkForecastId != null)
		{
			// Get the framework forecast object for the current Id
			frameworkForecast = getFrameworkForecastById(frameworkForecastId);
			
			if(frameworkForecast.Live_Record_Count__c >= 1)
			{
				// set hasForecastYear to true
				hasForecastYears = true;
			}
				
			// Call edit forecast method to manage forecast records for editing
			editForecast(frameworkForecastId);
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, system.Label.FF_No_Framework_Forecast_Error));
		}
	}
	
	/*******************************************************************
	Purpose: Load an exisiting framework forecast for editing or create a new one 
			 If hasForecastYears is true we want to display the edit mode component
			 and have each collection of records available to view or edit 
	Parameters: FrameworkForecast Id
	Returns: N/A
	Throws [Exceptions]: N/A
	********************************************************************/

	public void editForecast(Id frameworkForecastId)
	{
		if(hasForecastYears) 
		{	
			// Retrieve a list of live records by record type
			ffLive = getFrameworkForecastYearRecordsbyRecordType(frameworkForecastId, liveRt);		
			
			// if budget snapshot records exist grab those too
			if(frameworkForecast.Budget_Record_Count__c >= 1)
			{	
				
				// Retireve a list of budget records by record type
				ffBudget = getFrameworkForecastYearRecordsbyRecordType(frameworkForecastId, budgetRt);
			}
		
			// if actuals records exist grab them
			if(frameworkForecast.Actual_Record_Count__c >= 1)  
			{
				// Retireve a list of actuals records by record type
				ffActuals = getFrameworkForecastYearRecordsbyRecordType(frameworkForecastId, actualRt);
			}
			
		}
		else 
		{
				
			// Call Util method to Create a new set of Live forecast records, 5 for CG and 5 for WPS
			ffLive = FrameworkForecastUtil.createFrameworkForecastYears(frameworkForecastId, liveRt);
            
            // Call Method to create a set of actuals records ready for future uploads by the data team
			createActualsforInsert(ffLive);
			
		}
		
		// call method to return a list of years to segement data on our visual force page whther it be live or existing
		if(ffLive != null && !ffLive.isEmpty())
		{
			getRelativeYearsForDisplay(ffLive);
		}	
	}
	
	/*******************************************************************
	Purpose: Take the Year 0 records from the live insert list and create their Actuals counter parts
			 these are to be inserted on successful insert of the Live record
	Parameters: List of newly created live records with no forecast budget values.
	Returns: N/A
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public List<Framework_Forecast_Year__c> createActualsForInsert(List<Framework_Forecast_Year__c> ffLiveForClone)
	{	
		if(frameworkForecast.Actual_Record_Count__c == 0 && ffLiveForClone != null && !ffLiveforClone.isEmpty())
	     {
	     	// Yes we can create actual records because no others exist
		     	  
             	ffActuals = new List<Framework_Forecast_Year__c>();
             
		       	// cloning Related Framework Forecast Records eligible for snapshotting: needs to be updated to include a dynamic soql for all fields
		       
		       	for(Framework_Forecast_Year__c f : ffLiveforClone)
		       	{
		         	
		         	if(f.Relative_Forecast_Year__c == system.Label.FF_Year_0)
		         	{
		         		Framework_Forecast_Year__c ffCopy = f.clone(false,true);
		         
		         		ffCopy.RecordTypeId = actualRt;
		         		ffActuals.add(ffCopy);
		         	}
		       	}      
		 }
		
		return ffActuals;
	}
	
	/*******************************************************************
	Purpose: Creates a list of relative forecast year string values based on live records
	Parameters: List of newly created live records with relative forecast year values
	Returns: Set of strings
	Throws [Exceptions]: N/A
	********************************************************************/
	
  	public void getRelativeYearsForDisplay(List<Framework_Forecast_Year__c> ffToDisplay) 
  	{
  		System.debug('CRS ' + ffToDisplay);
	  	// check that our arguments contain values before setting up the years for display	
	  	if(ffToDisplay != null && !ffToDisplay.isEmpty())
	  	{
		
		    // dynamically create set of unique Relative Years from query
		    Set<Framework_Forecast_Year__c> forecastYearsSet = new Set<Framework_Forecast_Year__c>();
		    Set<String> relativeYearSet = new Set<String>();
		    for (Framework_Forecast_Year__c ffy : ffToDisplay)
		    {
		    	//make sure we don't add the same year more than once
		    	if (!relativeYearSet.contains(ffy.Relative_Forecast_Year__c)){
					forecastYearsSet.add(ffy);
					relativeYearSet.add(ffy.Relative_Forecast_Year__c);
		    	}	  
			    // convert the set into a List so that we can sort the values  
			    relativeYears = new List<Framework_Forecast_Year__c>(forecastYearsSet);
			    relativeYears.sort();



		    }
	     	
	  	}
  	}
	
	/*******************************************************************
	Purpose: Saves a new collection of live forecast records
	Parameters: N/A
	Returns: Parent Framework Forecast page reference 
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public pageReference saveNewForecast() 
	{
		PageReference pageRef = null;
		
		//Set a savepoint so we can rollback if anything fails
        System.Savepoint sp = Database.setSavepoint();
        
        try 
        {	
        	// Try to insert our live records
        	insert ffLive; 
        	
        	// Try to insert our actual records
            insert ffactuals;
            
            pageRef = redirectToForecast();
        }
        catch(Exception ex) 
        {
        	// Back to the save point if something has gone wrong.
        	Database.rollback(sp);
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, system.Label.FF_Forecast_Not_Saved_Error));
			
			system.debug(loggingLevel.Error, '### In Method saveNewForecast(): ' + ex.getMessage());
        }
        
		return pageRef;
	}  
	
	/*******************************************************************
	Purpose: Saves an existing collection of live forecast records
	Parameters: N/A
	Returns: Parent Framework Forecast page reference
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public pageReference saveForecast() 
	{
		PageReference pageRef = null;
		
		//Set a savepoint so we can rollback if anything fails
        system.Savepoint sp = Database.setSavepoint();
       
        try 
        {	
        	// Try to insert our live records
        	update ffLive; 
        	
        	pageRef = redirectToForecast();	
        }
        catch(Exception ex) 
        {
        	// Back to the save point if something has gone wrong.
        	Database.rollback(sp);
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, system.Label.FF_Forecast_Not_Saved_Error));
			
			system.debug(loggingLevel.Error, '### In Method saveForecast(): ' + ex.getMessage());
        }
        
		return pageRef;
	}  
	
	/*******************************************************************
	Purpose: Retrieve the framework forecast years for the forecast in context
	Parameters: Record type as category for the required list and forecast Id
	Returns: List of framework forecast records
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public static List<Framework_Forecast_Year__c> getFrameworkForecastYearRecordsByRecordType(Id frameworkForecastId, String rtId) 
	{
		List<Framework_Forecast_Year__c> result;
		
		//get the FrameworkForecast records by record type
		
		if(frameworkForecastId != null && rtId != null){
		result = [
					SELECT Id, Name, Sector__c, Relative_Forecast_Year__c, M01__c, M02__c, M03__c, M04__c, M05__c, M06__c, M07__c, M08__c, M09__c, 
						   M10__c, M11__c, M12__c, Q1__c, Q2__c, Q3__c, Q4__c, RecordTypeId, RecordType.Name, Annual__c, Forecast__c, Actual_Forecast_Year__c
					FROM Framework_Forecast_Year__c
					WHERE Forecast__c =: frameworkForecastId AND RecordTypeId =: rtId
					ORDER BY Actual_Forecast_Year__c
				];
		}
		
		return result;
	}
	
	/*******************************************************************
	Purpose: Retrieve the Framework Forecast in context
	Parameters: Forecast Id from custom button or code
	Returns: List of framework forecast records
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public Framework_Forecast__c getFrameworkForecastById(Id frameworkForecastId) 
	{
		Framework_Forecast__c result;
       
        result =  [
        			SELECT  Id, Name, Business_Plan_Year__c, Framework__c, Framework__r.Name, Actual_Record_Count__c, Budget_Record_Count__c, Live_Record_Count__c, Year_0__c
                  	FROM    Framework_Forecast__c
                  	WHERE   Id = :frameworkForecastId
                  ];

        return result;
	}
	
    /*******************************************************************
	Purpose: Set a page reference for the orginal Framework Forecast
	Parameters: Forecast Id from custom button or code
	Returns: Framework Forecast page reference
	Throws [Exceptions]: N/A
	********************************************************************/
	
	public PageReference redirectToForecast()
	{
		PageReference recordPage = new PageReference('/' + frameworkForecastId);
    	return recordPage;
	}


		    
}