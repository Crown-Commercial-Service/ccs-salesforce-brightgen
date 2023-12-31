/*********************************************************************
 Name:  CasesRecordTypeUpdater_Batch_Test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Test class for CasesRecordTypeUpdater_Batch
					ATTENTION! ONE TIME DATA FIX, CAN BE DELETED AFTER USE
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-11-08     Initial version
 *********************************************************************/
@isTest
private class CasesRecordTypeUpdater_Batch_Test {
	static final String CASE_QUERY = 'SELECT Id, RecordTypeId, Procurement_Route1__c, RecordType.DeveloperName ' +
		'FROM Case ' +
		'WHERE Procurement_Route1__c != null';

	@testSetup
	static void createData() {
		Id procRecTypeId = [
			SELECT Id, SobjectType, DeveloperName 
			FROM RecordType 
			WHERE SobjectType = 'Case'
				AND DeveloperName = 'Procurement'
		].Id;
		insert UnitTestHelper.createOpsWorkflowStages();
		insert UnitTestHelper.createOpsWorkflowTemplates();
		
		Account org = UnitTestHelper.createOrganisationAccount('Test Organisation');
		insert org;

		List<Case> cases = new List<Case>();
		for(Integer i = 0; i < 20; i++) {
			Case c = UnitTestHelper.createProcurementCase(org.id);
			c.RecordTypeId = procRecTypeId;
			c.put('Procurement_Route1__c', 'Call Off (Competition)');
			cases.add(c);
		}
		insert cases;
	}

	static testMethod void execute_Test() {
		Test.startTest();
		CasesRecordTypeUpdater_Batch crtu = new CasesRecordTypeUpdater_Batch();
		Database.executeBatch(crtu);
		Test.stopTest();

		List<Case> casesAfterUpdate = (List<Case>)Database.query(CASE_QUERY);

		for(Case c : casesAfterUpdate) {
			System.assertEquals('Procurement_Call_Off_Competition', c.RecordType.DeveloperName,
				'Record Type should be changed to new one');
		}
	}

	static testMethod void execute_Error() {
		insert new Org_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Entitlement_ID__c = '1234');
		Test.startTest();
		CasesRecordTypeUpdater_Batch crtu = new CasesRecordTypeUpdater_Batch();
		Database.executeBatch(crtu);
		delete [SELECT Id FROM Case LIMIT 1];
		Test.stopTest();

		List<Exception_Log__c> exceptionLogs = [
			SELECT Id, Class_Name__c, Method_Name__c 
			FROM Exception_Log__c
			WHERE Running_User__c =: UserInfo.getUserId()
		];
		for(Exception_Log__c el : exceptionLogs) {
			System.assertEquals(CasesRecordTypeUpdater_Batch.class.toString(), el.Class_Name__c, 
				'Exception should be generated by Batch Class');
		}
	}

	static testMethod void test_Schedulable() {
		String cronExp = '0 0 0 15 10 ? 2030';

		Test.startTest();
		String jobId = System.schedule('ScheduleApexClassTest',
			cronExp, new CasesRecordTypeUpdater_Batch());

		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
			FROM CronTrigger WHERE id = :jobId
		];
		Test.stopTest();

		System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should be correctly added');
		System.assertEquals(0, ct.TimesTriggered, 'Job shoul not be executed before stop test');
		System.assertEquals('2030-10-15 00:00:00', String.valueOf(ct.NextFireTime), 
			'Next time job should be run should match the date from cron expression');
	 }
}