/*********************************************************************
 Name:  COW_RealignLaterStagesControllerTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: test for controller                                                          
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-29		Initial version 	
   1.1 	 Cezary Zeleznicki	2016-11-04	  	Procuremenet RT change
   1.2   Cezary Zeleznicki 	2016-11-09		Simplified Stage dates US1645
 *********************************************************************/
@isTest
private class COW_RealignLaterStagesControllerTest {
	
	static final String ORG_NAME = 'Test Org';
	
	@testSetup
	static void setupTest()
	{
		// create custom settings
		insert UnitTestHelper.createOpsWorkflowStages();
		insert UnitTestHelper.createOpsWorkflowTemplates();
		
		Account org = UnitTestHelper.createOrganisationAccount(ORG_NAME);
		insert org;
		Case c = UnitTestHelper.createProcurementCase(org.Id);
		insert c;
	}
	
	static testMethod void testDateRealignStandardStages_plannedDatesOnlyStartDate()
	{
		List<Procurement_Stage__c> stages = [
			SELECT Id, Duration_Override__c, Procurement__c,
				Planned_Start_Date__c, Planned_End_Date__c 
			FROM Procurement_Stage__c ORDER BY Seq__c ASC
		];
		Date startDate = Date.newInstance(2016, 2, 1);
		Procurement_Stage__c thisStage = stages.get(1);	// second stage
		thisStage.Planned_Start_Date__c = startDate;	// start date on second stage
		update thisStage;
		// set 2.nd stage as current stage
		Test.setCurrentPage(Page.COW_RealignLaterStages);
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM, (String) thisStage.Id);
		
		Test.startTest();
		COW_RealignLaterStagesController ctrl = new COW_RealignLaterStagesController();
		// this should have found the current stage without any errors
		System.assert(ctrl.getAllowRealign(), 'We should be allowed to realign.');
		ctrl.realignLaterStages();
		Test.stopTest();
		
		stages = [
			SELECT Id, Planned_Start_Date__c, Planned_End_Date__c, Default_Duration__c, 
			Duration_Override__c, Next_Stage__r.Planned_Start_Date__c, Seq__c 
			FROM Procurement_Stage__c 
			WHERE Id IN :stages ORDER BY Seq__c ASC
		];
		stages.remove(0);	// remove first stage
		for(Procurement_Stage__c stage : stages)
		{
			Integer d = stage.Duration_Override__c != null ? stage.Duration_Override__c.intValue() : stage.Default_Duration__c.intValue();
			System.assertEquals(DateUtils.addWorkingDays(stage.Planned_Start_Date__c, d), stage.Planned_End_Date__c,
				'Planned end date should be set correctly on stage with sequence ' + stage.Seq__c);
				
			if(stage.Next_Stage__r.Planned_Start_Date__c != null)
			{
				System.assertEquals(stage.Next_Stage__r.Planned_Start_Date__c, DateUtils.addWorkingDays(stage.Planned_End_Date__c,2),
				'Next stage planned start date should be aligned with stage planned end date on stage with sequence ' + stage.Seq__c);
			}
		}
	}
	
	static testMethod void testErrorMessages_variousFaultyScenarios_correctErrorMessageDisplayed()
	{
		List<Procurement_Stage__c> stages = [
			SELECT Id, Planned_Start_Date__c, Planned_End_Date__c, Duration_Override__c, 
				Procurement__c, Seq__c 
			FROM Procurement_Stage__c ORDER BY Seq__c ASC
		];
		Procurement_Stage__c thisStage = stages.get(2);
		
		Test.setCurrentPage(Page.COW_RealignLaterStages);
		Integer i=1;
		
		Test.startTest();
		// no record id provided
		COW_RealignLaterStagesController ctrl = new COW_RealignLaterStagesController();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Page message should be added to page.');
		System.assert(!ctrl.getAllowRealign(), 'Realign not allowed if there are error messages.');
		
		// no sequence
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM, (String) thisStage.id);
		thisStage.Seq__c = null;
		update thisStage;
		ctrl = new COW_RealignLaterStagesController();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Page message should be added to page.');
		thisStage.Seq__c = 30;
		update thisStage;
		
		// no start date
		ctrl = new COW_RealignLaterStagesController();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Page message should be added to page.');
		thisStage.Planned_Start_Date__c = Date.newInstance(2016, 2, 1);
		update thisStage;
		
		// stage completed
		thisStage.Completed__c = true;
		update thisStage;
		ctrl = new COW_RealignLaterStagesController();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Page message should be added to page.');
		
		// last stage
		thisStage = stages.get(stages.size()-1);
		thisStage.Planned_Start_Date__c = Date.newInstance(2016, 2, 1).addDays(8);
		thisStage.Planned_End_Date__c = thisStage.Planned_Start_Date__c.addDays(2);
		thisStage.Duration_Override__c = DateUtils.calculateDuration(thisStage.Planned_Start_Date__c, thisStage.Planned_End_Date__c);
		update thisStage;
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM, (String) thisStage.Id);
		ctrl = new COW_RealignLaterStagesController();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Warning ("confirm action") page message should be added to page.');
		ctrl.realignLaterStages();
		System.assertEquals(i++, ApexPages.getMessages().size(), 'Page message should be added to page.');
		
		Test.stopTest();
		
		// debug messages
		for(ApexPages.Message msg : ApexPages.getMessages())
		{
			System.debug(msg.getSummary());
		}
		
	}
	
	static testMethod void testOverrideDuration_calculateDurationIfEndDateProvided_putInOverrideDurationIfChangedAndNotDefault()
	{
		Procurement_Stage__c lastStage = [
			SELECT Id, Planned_Start_Date__c, Planned_End_Date__c, Default_Duration__c, 
				Duration_Override__c, Next_Stage__c 
			FROM Procurement_Stage__c 
			ORDER BY Seq__c DESC LIMIT 1
		];	// get last stage
		System.assertEquals(null, lastStage.Next_Stage__c, 'Last stage should not have next stage.');
		
		COW_RealignLaterStagesController ctrl;
		Test.setCurrentPage(Page.COW_RealignLaterStages);
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM,(string) lastStage.Id);
		
		Test.startTest();
		// #1: Duration_Override__c = x; Default_Duration__c = y; currentDuration = z; -> Duration_Override__c = z
		lastStage.Planned_Start_Date__c = Date.newInstance(2016, 2, 1);
		lastStage.Duration_Override__c = lastStage.Default_Duration__c + 1;
		lastStage.Planned_End_Date__c = DateUtils.addWorkingDays(lastStage.Planned_Start_Date__c, lastStage.Duration_Override__c.intValue() + 1);
		update lastStage;
		ctrl = new COW_RealignLaterStagesController();
		ctrl.realignLaterStages();
		Decimal newDurationOverride = [SELECT Duration_Override__c FROM Procurement_Stage__c WHERE Id = :lastStage.Id].Duration_Override__c;
		System.assertEquals(lastStage.Duration_Override__c + 1, newDurationOverride, 'Duration Override should change when dates do not correspond.');
		
		
		// #2: Duration_Override__c = x; Default_Duration__c = y; currentDuration = y; -> Duration_Override__c = null (we can use dafault duration)
		lastStage.Duration_Override__c = newDurationOverride;
		lastStage.Planned_End_Date__c = DateUtils.addWorkingDays(lastStage.Planned_Start_Date__c, lastStage.Default_Duration__c.intValue());
		update lastStage;
		ctrl = new COW_RealignLaterStagesController();
		ctrl.realignLaterStages();
		newDurationOverride = [SELECT Duration_Override__c FROM Procurement_Stage__c WHERE Id = :lastStage.Id].Duration_Override__c;
		System.assertEquals(null, newDurationOverride, 'Duration Override will be null if dates correspond to Default Duration.');
		
		// #3: Duration_Override__c = null; Default_Duration__c = x; currentDuration = x; -> no action
		lastStage.Duration_Override__c = newDurationOverride;
		update lastStage;
		ctrl = new COW_RealignLaterStagesController();
		ctrl.realignLaterStages();
		newDurationOverride = [SELECT Duration_Override__c FROM Procurement_Stage__c WHERE Id = :lastStage.Id].Duration_Override__c;
		System.assertEquals(null, newDurationOverride, 'If Default Duration coresponds to dates no change to empty Default Override.');    	
		
		// #4: Duration_Override__c = x; Default_Duration__c = y; currentDuration = x; -> no action
		lastStage.Duration_Override__c = lastStage.Default_Duration__c + 1;
		lastStage.Planned_End_Date__c = DateUtils.addWorkingDays(lastStage.Planned_Start_Date__c, lastStage.Duration_Override__c.intValue());
		update lastStage;
		ctrl = new COW_RealignLaterStagesController();
		ctrl.realignLaterStages();
		newDurationOverride = [SELECT Duration_Override__c FROM Procurement_Stage__c WHERE Id = :lastStage.Id].Duration_Override__c;
		System.assertEquals(lastStage.Duration_Override__c, newDurationOverride, 'If Durration Override coresponds to dates it\'s not updated.');
		
		Test.stopTest();
		
		for(ApexPages.Message msg : ApexPages.getMessages())
		{
			if(msg.getSeverity() == ApexPages.Severity.ERROR)
			{
				System.assertEquals(COW_RealignLaterStagesController.MSG_NOLATERSTAGES, msg.getSummary(),
					'Error messages should inform us no action was taken.');
			}
		}
	}
	
	static testMethod void testErrorMessages_saveFailed_errorMessageShown()
	{
		Procurement_Stage__c lastStage = [SELECT Id, Planned_Start_Date__c FROM Procurement_Stage__c ORDER BY Seq__c DESC LIMIT 1];	// get last stage
		lastStage.Planned_Start_Date__c = Date.newInstance(2016, 2, 1);
		update lastStage;
		
		Test.setCurrentPage(Page.COW_RealignLaterStages);
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM, (String) lastStage.Id);
		COW_RealignLaterStagesController ctrl = new COW_RealignLaterStagesController();
		// now that record is in controller, delet it from the database to cause a save error
		delete lastStage;
		
		Test.startTest();
		Pagereference pr = ctrl.realignLaterStages();
		Test.stoptest();
		
		System.assertEquals(null, pr, 'Unsuccessful save should return null.');
		System.assertEquals(2, ApexPages.getMessages().size(), 'Error message should be added to page on top of existing warning.');
	}

	static testMethod void realignLaterStages_LaterStagesNotCalculated() {
		List<Procurement_Stage__c> stages = [SELECT Id, Planned_Start_Date__c FROM Procurement_Stage__c ORDER BY Seq__c ASC];
		stages[0].Planned_Start_Date__c = null;
		update stages[0];
		
		Test.setCurrentPage(Page.COW_RealignLaterStages);
		ApexPages.currentPage().getParameters().put(COW_RealignLaterStagesController.RECORDID_PARAM, (String) stages[0].Id);
		COW_RealignLaterStagesController ctrl = new COW_RealignLaterStagesController();
		
		Test.startTest();
		Pagereference pr = ctrl.realignLaterStages();
		Test.stoptest();
		List<Procurement_Stage__c> nextStages = [SELECT Id, Planned_Start_Date__c FROM Procurement_Stage__c WHERE Id != :stages[0].Id];
		for(Procurement_Stage__c ps : nextStages) {
			System.assertEquals(null, ps.Planned_Start_Date__c, 'Next stage dates not calculated.');
		}
	}
}