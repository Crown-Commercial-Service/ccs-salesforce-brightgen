/*********************************************************************
 Name:  ProcurementStageTriggerHelperTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: tests for ProcurementStageTriggerHelper															
 -------															
 ======================================================
 ======================================================
 History															
 -------															
 VERSION  AUTHOR			DATE			 DETAIL				Description
   1.0   Klea Kolaric		2016-03-07		Initial version 	
   1.1	 Cezary Zeleznicki 	2016-11-04		Procurement RT change
   1.2	 Cezary Zeleznicki	2016-11-09		Simplified Stage dates US1645
 *********************************************************************/
 
@isTest
private class ProcurementStageTriggerHelperTest {
	
	static final String ORG_NAME = 'Test Org';
	
	@testSetup
	static void setupTest()
	{
		// create custom settings
		insert UnitTestHelper.createOpsWorkflowStages();
		insert UnitTestHelper.createOpsWorkflowTemplates();
		
		Account org = UnitTestHelper.createOrganisationAccount(ORG_NAME);
		insert org;
		Case c = UnitTestHelper.createProcurementCase(org.id);
		insert c;
		
		Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
		system.assertEquals(numOfStages,[select count() from Procurement_Stage__c where Procurement__c = :c.Id],
							'Case trigger should have created stages.');
	}
	
	static testMethod void testBulkUpdate_200records_pass()
	{
		Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
		Account org = [select Id from Account where Name = :ORG_NAME limit 1];
		delete [select id from Case];	// clean cases
		List<Case> cases = new List<Case>();
		
		Integer totalRecords = 60;
		Integer numOfNeededCases = totalRecords / numOfStages;	// integer division
		for(Integer i=0; i<numOfNeededCases; i++)
		{
			Case c = UnitTestHelper.createProcurementCase(org.Id);
			cases.add(c);
		}
		insert cases;
		system.assertEquals(totalRecords,[select count() from Procurement_Stage__c]);
		
		// set stage two start date
		Date startDate = Date.newInstance(2030,02,09);	// Thursday, 3rd March 2016
		List<Procurement_Stage__c> stages2 = [select id, Planned_Start_Date__c from Procurement_Stage__c where Stage_Id__c = 'S02'];
		for(Procurement_Stage__c s2 : stages2) s2.Planned_Start_Date__c = startDate;
		
		Test.startTest();
		update stages2;
		Test.stopTest();
	}
	
	/*static testMethod void testUpdateTrigger_dateCalculationStandardStages_datesSetOnStages()
	{
		// once we set start date (but not end date!) on stage 2 we should get start/end dates to calculate for all later stages
		List<Procurement_Stage__c> stages = [select id, Original_Date__c, Stage_Id__c from Procurement_Stage__c order by Seq__c asc];
		for(Procurement_Stage__c stage : stages)
		{
			if(stage.Stage_Id__c == 'S01')
				system.assertNotEquals(null,stage.Original_Date__c, 'First stage start date should be case created date..');
			else
				system.assertEquals(null,stage.Original_Date__c, 'Start date should be blank.');
		}
		
		Date startDate = Date.newInstance(2016,3,3);	// Thursday, 3rd March 2016
		stages.get(1).Original_Date__c = startDate;	// start date on second stage
		
		Test.startTest();
		update stages.get(1);	// update only second stage
		Test.stopTest();
		
		Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
		stages = [select id, Original_Date__c, Stage_Id__c, Original_End_Date__c from Procurement_Stage__c
					where Original_Date__c != null and Original_End_Date__c != null order by Seq__c asc];
		system.assertEquals(numOfStages,stages.size(), 'All stages should have start and end date set.');
		system.assertEquals(stages.get(0).Original_End_Date__c,stages.get(1).Original_Date__c, 'First stage should end on day second stage starts.');
	}
	
	static testMethod void testUpdateTrigger_dateCalculationMixedStages_datesSetOnStages()
	{
		Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
		
		// once we set start date (but not end date!) on stage 2 we should get start/end dates to calculate for all later stages
		List<Procurement_Stage__c> stages = [select id, Original_Date__c, Original_End_Date__c, Procurement__c, Next_Stage__c, Duration_Override__c, 
												Seq__c from Procurement_Stage__c order by Seq__c asc];
		// create new stage in between stages 3 and 4
		insert new Procurement_Stage__c(
						Procurement__c = stages.get(0).Procurement__c,
						Duration_Override__c = 3,
						Next_Stage__c = stages.get(3).id,
						Seq__c = (stages.get(2).Seq__c + stages.get(3).Seq__c).intValue() / 2);
						
		stages = [select id, Original_Date__c, Original_End_Date__c, Procurement__c, Next_Stage__c, Duration_Override__c, Seq__c
					from Procurement_Stage__c order by Seq__c asc];
		// change next stage on stage 3
		stages.get(2).Next_Stage__c = stages.get(3).Id;
		// change duration of stage 2
		stages.get(1).Duration_Override__c = 10;
		update stages;
		system.assertEquals(numOfStages+1,stages.size(),'All stages were created');
		
		Date startDate = Date.newInstance(2016,3,3);	// Thursday, 3rd March 2016
		stages.get(1).Original_Date__c = startDate;	// start date on second stage
		
		Test.startTest();
		update stages.get(1);	// update only second stage
		Test.stopTest();
		
		system.assertEquals(numOfStages,[select count() from Procurement_Stage__c 
			where Seq__c >= :stages.get(1).Seq__c and Original_Date__c != null and Original_End_Date__c != null],
			'All stages at or after position 2 should have start and end date set.');
			
		stages = [select id, Original_Date__c, Original_End_Date__c, Procurement__c, Next_Stage__c, Duration_Override__c, Seq__c, Stage_ID__c 
					from Procurement_Stage__c order by Seq__c asc];
		system.assertEquals(DateUtils.addWorkingDays(stages.get(1).Original_Date__c,stages.get(1).Duration_Override__c.intValue()),
			stages.get(1).Original_End_Date__c,
			'Stage 2 should be using Duration Override instead of duration specified in template.');
		system.assertEquals(null,stages.get(3).Stage_ID__c,'Custom stage should be on 4th position.');
		system.assertEquals(DateUtils.addWorkingDays(stages.get(2).Original_End_Date__c,2),stages.get(3).Original_Date__c,
			'Custom stage should start a day after the previous one ends.');
		system.assertEquals(DateUtils.addWorkingDays(stages.get(3).Original_End_Date__c,2),stages.get(4).Original_Date__c,
			'Custom stage should end a day before the next stage starts.');
	}*/
	
	static testMethod void testUpdateTrigger_calculateDuration_durationSetCorrectly()
	{
		List<Procurement_Stage__c> stages = [select id, Actual_Start_Date__c, Actual_End_Date__c, Delivery_Duration__c, 
												Seq__c from Procurement_Stage__c order by Seq__c asc];
		for(Procurement_Stage__c ps : stages)
			system.assertEquals(null,ps.Delivery_Duration__c, 'No stage should have duration set.');
		
		Date startDate = Date.newInstance(2023,02,09);	// February 1st, 2016 was a work day (monday)
			
		for(Integer i=0; i<stages.size(); i++)
		{
			stages.get(i).Actual_Start_Date__c = i == 0 ? startDate : DateUtils.addWorkingDays(stages.get(i-1).Actual_End_Date__c,2);
			stages.get(i).Actual_End_Date__c = DateUtils.addWorkingDays(stages.get(i).Actual_Start_Date__c,i+1);
		}
		
		Test.startTest();
		update stages;
		Test.stopTest();
		
		 stages = [select id, Delivery_Duration__c,	Seq__c from Procurement_Stage__c where id in :stages order by Seq__c asc];
		 for(Integer i=0; i<stages.size(); i++)
		 {
		 	system.assertEquals(i+1,stages.get(i).Delivery_Duration__c, 'Duration should be calculated correctly on stage seq=' + stages.get(i).Seq__c);
		 }
	}
    
}