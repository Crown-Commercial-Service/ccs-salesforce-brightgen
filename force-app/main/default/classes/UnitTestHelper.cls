/*
Name:  UnitTestHelper.cls
Copyright © 2014  Methods Digital
======================================================
======================================================
Purpose:
-------
Helper class providing utility properties/methodsfor unit test methods.
======================================================
======================================================
History
------- 
Ver. Author        		Date        	Detail
1.0  Mark Cane&    		2014-12-05  	Initial development. 
2.0  Klea Kolaric  		2016-03-03  	Will use for futher development. 
3.0  Cezary Zeleznicki 	2016-11-03		Procurement RT change
3.1	 Nic Flook			2016-31-01		Added support for Framework Forecast record creation
3.2  Simon Kaya			2017-11-29	Added method for creating users for freeze test
3.3 Zahir Basith		2023-11-07 Added test method for policy record type and entitlement process for policy
*/
@isTest
public with sharing class UnitTestHelper {
	
	public static final Id ACCOUNT_ORG_RT_ID = mRecordTypes.get('Account').get('Organisation'); //Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
	public static final Id CASE_PROC_RT_ID = mRecordTypes.get('Case').get('Procurement'); //Schema.SObjectType.Case.getRecordTypeInfosByName().get('Procurement').getRecordTypeId();
	
	public static Map <String, Map <String, Id>> mRecordTypes {
		get {
			if (mRecordTypes == null){
				mRecordTypes = new Map <String, Map <String, Id>>();
				List <String> liObjests = new List <String> {'Account', 'Case'};
				for (RecordType rt : [select Id, SobjectType, DeveloperName from RecordType where SobjectType in :liObjests]){
					if (!mRecordTypes.containsKey(rt.SobjectType)){
						mRecordTypes.put(rt.SobjectType, new Map <String, Id> ());
					}
					mRecordTypes.get(rt.SobjectType).put(rt.DeveloperName, rt.Id);
				}
			}
			return mRecordTypes;
		}
		set;
	}

	public static Account createOrganisationAccount(String accountName)
	{
		Account org = new Account(RecordTypeId = ACCOUNT_ORG_RT_ID);
		org.Name = accountName;
		org.Status__c = 'Active';
		org.Sector__c = 'Health';
		return org;
	}
	
	public static Contact createContact(Id accountId)
	{
		Contact c = new Contact();
		c.AccountId = accountId;
		c.Salutation = 'Mr';
		c.FirstName = 'Splashy';
		c.LastName = 'Pants';
		c.Email = 'mr.splashypants@greenpeace.xyz';
		return c;
	}
	
	public static Case createProcurementCase(Id accountId)
	{
		Case c = new Case(RecordTypeId = mRecordTypes.get('Case').get('Procurement_Call_Off_Competition'));
		c.AccountId = accountId;
		c.Origin = 'Phone';
		c.Status = 'In Progress';
		c.Priority = 'Green';
		c.Subject = 'Test Case';
		c.Description = 'test case description';
		return c;
	}
    
	public static Case createPolicyCase(Id accountId)
	{
		Case c = new Case(RecordTypeId = mRecordTypes.get('Case').get('Policy_Legal_Case'));
		c.AccountId = accountId;
		c.Origin = 'Phone';
		c.Status = 'Open';
		c.Priority = 'Green';
		c.Subject = 'Test Case';
		c.Description = 'test case description';
		return c;
	}    

	public static Case createEnquiryCase(Id accountId)
	{
		Case c = new Case(RecordTypeId = mRecordTypes.get('Case').get('Enquiry'));
		c.AccountId = accountId;
		c.Origin = 'Phone';
		c.Status = 'In Progress';
		c.Priority = 'Green';
		c.Subject = 'Test Case';
		c.Description = 'test case description';
		return c;
	}
	
	public static List<Ops_Workflow_Stages__c> createOpsWorkflowStages()
	{
		List<Ops_Workflow_Stages__c> opwsList = new List<Ops_Workflow_Stages__c>();
		// stage duration comes from Ops_Workflow_Templates__c so i'm not setting it
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S01', Stage_Name__c = 'Early Engagement'));
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S02', Stage_Name__c = 'ITT - Development'));
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S03', Stage_Name__c = 'Pre-Tender Approval'));
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S04', Stage_Name__c = 'ITT - Live'));
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S05', Stage_Name__c = 'Evaluation'));
		opwsList.add(new Ops_Workflow_Stages__c(Name = 'S06', Stage_Name__c = 'Award Recommendation'));
		//opwsList.add(new Ops_Workflow_Stages__c(Name = 'S07', Stage_Name__c = 'Post-Tender Approval'));
		//opwsList.add(new Ops_Workflow_Stages__c(Name = 'S08', Stage_Name__c = 'Awarded - Closing Actions'));
		return opwsList;
	}
	
	public static List<Ops_Workflow_Templates__c> createOpsWorkflowTemplates()
	{
		List<Ops_Workflow_Templates__c> opwtList = new List<Ops_Workflow_Templates__c>();
		// stage duration comes from Ops_Workflow_Templates__c so i'm not setting it
		String callOffRecTypeName = 'Procurement_Call_Off_Competition';
		opwtList.add(createOpsWorkflowTemplate('S01','T1',1,'Call Off',2,false,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S02','T2',2,'Call Off',2,true,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S03','T3',3,'Call Off',2,false,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S04','T4',4,'Call Off',2,false,true,true,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S05','T5',5,'Call Off',2,false,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S06','T6',6,'Call Off',2,false,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S07','T7',7,'Call Off',2,false,false,false,false, callOffRecTypeName));
		opwtList.add(createOpsWorkflowTemplate('S08','T8',8,'Call Off',2,false,false,false,true, callOffRecTypeName));
		return opwtList;
	}
	
	private static Ops_Workflow_Templates__c createOpsWorkflowTemplate(String stageId, String name, Decimal seq, String templateName, 
		Decimal stageDuration, Boolean startSLA1, Boolean startSLA2, Boolean endSLA1, Boolean endSLA2, String rtName)
	{
		return new Ops_Workflow_Templates__c(Stage_Id__c = stageId,
												Name = name,
												Seq__c = seq, 
												Template_Name__c = templateName, 
												Stage_Duration__c = stageDuration,
												Start_SLA1__c = startSLA1,
												Start_SLA2__c = startSLA2,
												End_SLA1__c = endSLA1,
												End_SLA2__c = endSLA2,
												Record_Type_Name__c = rtName);
	}

	private static Framework_Forecast_Year__c createAllFrameworkForecastYearTemplate(Id frameworkForecastId, String sector, String rtId, String relativeForecastYear)
	{
		return new  Framework_Forecast_Year__c(
                	Forecast__c = frameworkForecastId,
                	Sector__c = sector,
                	RecordTypeId = rtId,
                	Relative_Forecast_Year__c = relativeForecastYear
                	);
	}
	
	public static List<Framework_Forecast_Year__c> createAllFrameworkForecastYears(Id frameworkForecastId)
	{
			// We have to get the record types from the utility method as the records must be created before the constructor called.
			Map<String,Id> ffYearRecordTypes = FrameworkForecastUtil.GetRecordTypeIdsByDeveloperName(Framework_Forecast_Year__c.SObjectType);
			
			String liveRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Live);
			String actualRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Actual);
			String budgetRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Budget);
			
			List<Framework_Forecast_Year__c> affyForInsert = new List<Framework_Forecast_Year__c>();
			
			// Create Year 0-4 records for Central Government Live
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, liveRt, system.Label.FF_Year_0));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, liveRt, system.Label.FF_Year_1));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, liveRt, system.Label.FF_Year_2));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, liveRt, system.Label.FF_Year_3));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, liveRt, system.Label.FF_Year_4));
			
			// Create Year 0-4 records for Wider Public Sector Live
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, liveRt, system.Label.FF_Year_0));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, liveRt, system.Label.FF_Year_1));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, liveRt, system.Label.FF_Year_2));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, liveRt, system.Label.FF_Year_3));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, liveRt, system.Label.FF_Year_4));
			
			// Create Year 0-4 records for Central Government Budget
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, budgetRt, system.Label.FF_Year_0));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, budgetRt, system.Label.FF_Year_1));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, budgetRt, system.Label.FF_Year_2));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, budgetRt, system.Label.FF_Year_3));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, budgetRt, system.Label.FF_Year_4));
			
			// Create Year 0-4 records for Wider Public Sector Budget
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, budgetRt, system.Label.FF_Year_0));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, budgetRt, system.Label.FF_Year_1));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, budgetRt, system.Label.FF_Year_2));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, budgetRt, system.Label.FF_Year_3));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, budgetRt, system.Label.FF_Year_4));
			
			// Create Year 0-4 records for Central Govt and Wider Public Sector Actual
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_CG, actualRt, system.Label.FF_Year_0));
			affyForInsert.add(createAllFrameworkForecastYearTemplate(frameworkForecastId, system.Label.FF_Sector_WPS, actualRt, system.Label.FF_Year_0));
			
			return affyForInsert;
	}
	
	public static String getSelectedDate()
	{
		return 'FY' + string.valueof(Date.Today().Year()).substring(2,4) + '/' + string.valueof(Date.Today().Year()+1).substring(2,4);
	}

	public static void createOpps(Integer num)
	{
		List<Opportunity> oppList = new List<Opportunity>();

		for (Integer i = 0; i< num; i++){
			Opportunity opp = new Opportunity(Name='Test Opp ' + i, StageName = 'Prospecting', CloseDate = Date.Today());
			oppList.add(opp);
		}

		insert oppList;
	}
	
	public static User createUser(Integer userNo, ID profile)
	{
		return new User(
			profileID = profile,
			LastName = 'TestUser'+userNo,
			Email = userNo+'test@test.com',
			Username = userNo+'_yjhE6iG6brvnazQi@test.test',
			Alias = userNo+'test',
			EmailEncodingKey = 'UTF-8',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'GMT',
			LanguageLocaleKey = 'en_US');
	}
}