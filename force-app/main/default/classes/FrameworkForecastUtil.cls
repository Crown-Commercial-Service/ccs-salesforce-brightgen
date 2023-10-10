/*********************************************************************
 Name:  FramworkForecastUtil
 Copyright © 2017  Salesforce
 ======================================================
 ======================================================
 Purpose: Framework Forecast utility methods                                                     
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Nic Flook          2017-01-30       Initial version    
   1.1   James Burgess - BG 2017-09-14       US0026             Added field set caching methods and SetAcknowledgedValues
 *********************************************************************/

public with sharing class FrameworkForecastUtil {

    //Record types cache
    public static Map<Schema.SObjectType,Map<String,Id>> rtypesCache;
    public static List<sObject> results;
    static {
        rtypesCache = new Map<Schema.SObjectType,Map<String,Id>>();//convenient map, formatted from results.
        results = new List<sObject>();//contains all recordtypes retrieved via SOQL
    }

    //Field sets cache
    private static List<Schema.FieldSetMember> currentFrameworkForecastFields;
    private static List<Schema.FieldSetMember> acknowledgedFrameworkForecastFields;
   
    /*******************************************************************
    Purpose: get a list of forecast years that have forecast years eligible for budget batch processing
    Parameters: a set of Framework Forecast ids from a url and a record type Id
    Returns: list of Framework Forecast records
    Throws [Exceptions]: N/A
    ********************************************************************/
    public static List<Framework_Forecast_Year__c> getFrameworkForecastYearsForBatch(Set<Id> frameworkForecastId, String rtId) 
    {
        list<Framework_Forecast_Year__c> result;
        
        if(frameworkForecastId != null)
        {
            //get the FrameworkForecast records by record type - dynamic soql would be handy
            result = [
                    SELECT Id, Name, Sector__c, Relative_Forecast_Year__c, M01__c, M02__c, M03__c, M04__c, M05__c, M06__c, M07__c, M08__c, M09__c, 
                           M10__c, M11__c, M12__c, Q1__c, Q2__c, Q3__c, Q4__c, RecordTypeId, RecordType.Name, Annual__c, Forecast__c
                    FROM Framework_Forecast_Year__c
                    WHERE Forecast__c in: frameworkForecastId AND RecordTypeId =: rtId
                    ];
        }
        
        return result;
    }
    
    /*******************************************************************
    Purpose: Returns a map of active, user-available RecordType IDs for a given SObjectType,
             keyed by each RecordType's unique, unchanging DeveloperName 
    Parameters: Framework forecast year object
    Returns: N/A
    Throws [Exceptions]: N/A
    ********************************************************************/
    
    public static Map<String, Id> getRecordTypeIdsByDeveloperName(Schema.SObjectType token) {
    
    // Do we already have a result? 
    Map<String, Id> mapRecordTypes = rtypesCache.get(token);

    // If not, build a map of RecordTypeIds keyed by DeveloperName
    if (mapRecordTypes == null) {
        mapRecordTypes = new Map<String, Id>();
        rtypesCache.put(token,mapRecordTypes);
    } else {
       // If we do, return our cached result immediately!
       return mapRecordTypes;
    }

    // Get the Describe Result
    Schema.DescribeSObjectResult obj = token.getDescribe();

    //Check if we already queried all recordtypes.
    if (results == null || results.isEmpty()) {
    // Obtain ALL Active Record Types
    // (We will filter out the Record Types that are unavailable
    // to the Running User using Schema information)
        String soql = 'SELECT Id, Name, DeveloperName, sObjectType FROM RecordType WHERE IsActive = TRUE';
        try {
            results = Database.query(soql);
        } catch (Exception ex) {
            results = new List<SObject>();
        }
    }

    // Obtain the RecordTypeInfos for this SObjectType token
    Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();
    // Loop through all of the Record Types we found,
    // and weed out those that are unavailable to the Running User
    for (SObject rt : results) { 
        if (recordTypeInfos.get(rt.Id) != null) {
            if (recordTypeInfos.get(rt.Id).isAvailable()) {
                // This RecordType IS available to the running user,
                //      so add it to our map of RecordTypeIds by DeveloperName
                mapRecordTypes.put(String.valueOf(rt.get('DeveloperName')),rt.Id);
            }
            else {
                System.debug('The record type ' + rt.get('DeveloperName') + ' for object ' + rt.get('sObjectType') + ' is not availiable for the user.');
            }
        }
    }

    return mapRecordTypes;
    }
    
    
    
    /*******************************************************************
    Purpose: Template method for creating new Framework Forecast Year records
    Parameters: Framework Forecast Id, Sector value( CG or WPS),  Record Type Id and Relative Forecast Year.
    Returns: New Framework Forecast Year record
    Throws [Exceptions]: N/A
    ********************************************************************/ 
    
    public static Framework_Forecast_Year__c createFrameworkForecastYearTemplate(Id frameworkForecastId, String sector, String rtId, String relativeForecastYear, String relativePlusActual)
    {
        return new Framework_Forecast_Year__c(
                    Forecast__c = frameworkForecastId,
                    Sector__c = sector,
                    RecordTypeId = rtId,
                    Relative_Forecast_Year__c = relativeForecastYear,
                    Relative_Year_Plus_Actual__c = relativePlusActual
                    );
    }
    
    /*******************************************************************
    Purpose: Create all required live records for both CG and WPS sectors for the Forecast Editor
             using the above createFrameworkForecastYearTemplate().
    Parameters: Framework Forecast record Id (the parent) and a live record type Id
    Returns: List of new Framework Forecast Year records
    Throws [Exceptions]: N/A
    ********************************************************************/ 
    
    public static List<Framework_Forecast_Year__c> createFrameworkForecastYears(Id frameworkForecastId, String liveRt)
    {
            List<Framework_Forecast_Year__c> ffLiveForInsert = new List<Framework_Forecast_Year__c>();
            Integer year0 = getYear0(frameworkForecastId);
            
            // Create Year 0-4 records for Central Government
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_CG, liveRt, System.label.FF_Year_0, System.label.FF_Year_0 + ' (' + year0 + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_CG, liveRt, System.label.FF_Year_1, System.label.FF_Year_1 + ' (' + (year0 + 1) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_CG, liveRt, System.label.FF_Year_2, System.label.FF_Year_2 + ' (' + (year0 + 2) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_CG, liveRt, System.label.FF_Year_3, System.label.FF_Year_3 + ' (' + (year0 + 3) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_CG, liveRt, System.label.FF_Year_4, System.label.FF_Year_4 + ' (' + (year0 + 4) + ')'));
            
            // Create Year 0-4 records for Wider Public Sector
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_WPS, liveRt, System.label.FF_Year_0, System.label.FF_Year_0 + ' (' + year0 + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_WPS, liveRt, System.label.FF_Year_1, System.label.FF_Year_1 + ' (' + (year0 + 1) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_WPS, liveRt, System.label.FF_Year_2, System.label.FF_Year_2 + ' (' + (year0 + 2) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_WPS, liveRt, System.label.FF_Year_3, System.label.FF_Year_3 + ' (' + (year0 + 3) + ')'));
            ffLiveForInsert.add(createFrameworkForecastYearTemplate(frameworkForecastId, System.label.FF_Sector_WPS, liveRt, System.label.FF_Year_4, System.label.FF_Year_4 + ' (' + (year0 + 4) + ')'));
            
            return ffLiveForInsert;
    }


    /*******************************************************************
    Purpose: To get Year 0 for the business plan year
    Parameters: Framework Forecast record Id (the parent)
    Returns: Year 0 (Integer)
    Throws [Exceptions]: N/A
    ********************************************************************/ 

    public static Integer getYear0(Id frameworkForecastId){
        Framework_Forecast__c ff = [select Id, Year_0__c from Framework_Forecast__c where Id =:frameworkForecastId];
        return (Integer)ff.Year_0__c;
    }


    /*******************************************************************
    Purpose: Cache the current forecast field sets
    Parameters: N/A
    Returns: List of Schema.FieldSetMembers
    Throws [Exceptions]: N/A
    ********************************************************************/
    public static List<Schema.FieldSetMember> GetCurrentForecastFieldSets()
    {
        if (currentFrameworkForecastFields == null)
        {
            currentFrameworkForecastFields = bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Monthly_Forecast');
            currentFrameworkForecastFields.addAll(bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Quarterly_Forecast'));
            currentFrameworkForecastFields.addAll(bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Annual_Forecast'));
        }
        return currentFrameworkForecastFields;
    }

    /*******************************************************************
    Purpose: Cache the acknowledged forecast field sets
    Parameters: N/A
    Returns: List of Schema.FieldSetMembers
    Throws [Exceptions]: N/A
    ********************************************************************/
    public static List<Schema.FieldSetMember> GetAcknowledgedForecastFieldSets()
    {
        if (acknowledgedFrameworkForecastFields == null)
        {
            acknowledgedFrameworkForecastFields = bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Previous_Acknowledged_Monthly_Forecast');
            acknowledgedFrameworkForecastFields.addAll(bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Previous_Acknowledged_Quarterly_Forecast'));
            acknowledgedFrameworkForecastFields.addAll(bg_FieldSetUtils.GetFieldSet('Framework_Forecast_Year__c', 'Previous_Acknowledged_Annual_Forecast'));
        }
        return acknowledgedFrameworkForecastFields;
    }
    
    /*
    *   Takes a framework forecast year record and uses the defined monthly, quarterly and annual
    *   forecast field sets to set the acknowledged values to the forecast values, returning the
    *   updated framework forecast year record. Relies on the acknowledged and current field sets
    *   being the same length and the corresponding values being ordered the same
    */
    public static void SetAcknowledgedValues(Framework_Forecast_Year__c ffyToUpdate)
    {
        String userName = [SELECT Name FROM User WHERE Id =: UserInfo.getUserId()].Name;
        //System.debug('username' + ' ' + username);
       // ffyToUpdate.Last_Acknowledged_By__c = userName;
       // ffyToUpdate.Last_Acknowledged_Date__c = DateTime.now();

        //Get the field sets for value assignment
        List<Schema.FieldSetMember> currentFields = FrameworkForecastUtil.GetCurrentForecastFieldSets();
        List<Schema.FieldSetMember> previousFields = FrameworkForecastUtil.GetAcknowledgedForecastFieldSets();

        for(Integer i = 0; i < currentFields.size(); i++)
        {
            //Query out the field sets - assumption that they match in length
            String currField = currentFields.get(i).getFieldPath();
            String prevField = previousFields.get(i).getFieldPath();

            ffyToUpdate.put(prevField, ffyToUpdate.get(currField));
            System.debug('Framework Forecast field sets' + ' ' + ffyToUpdate);
        }
    }
}