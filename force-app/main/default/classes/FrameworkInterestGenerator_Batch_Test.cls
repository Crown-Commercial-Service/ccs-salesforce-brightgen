/*********************************************************************
 Name:  FrameworkInterestGenerator_Batch_Test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Test class for FrameworkInterestGenerator_Batch
		ATTENTION! ONE TIME DATA FIX, CAN BE DELETED AFTER USE
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-12-12     Initial version
 *********************************************************************/
@isTest
private class FrameworkInterestGenerator_Batch_Test {
	private final static List<String> frameworkNames = new List<String>{
		'Advertising Agencies',
		'Agency Nurses and Social Workers',
		'Agile Route to Market',
		'Allied Health Professionals/Health Science Service',
		'Allied Health Professionals and Health Science Services Staff',
		'Assistive Technologies-Telecare Telehealth Telecoaching',
		'Automatic Meter Reading (AMR)',
		'Behavioural Insights Consulting and Research',
		'Central Government Travel Management Service',
		'Cipher - Consultancy Services Framework',
		'Civil Service Learning'
	};

	@testSetup
	static void createData() {
		List<Master_Framework__c> frameworks = new List<Master_Framework__c>();
		for(Integer i = 0; i < 10; i++) {
			Master_Framework__c mf = UnitTestDataFactory.createMasterFramework();
			mf.Name = frameworkNames[i];
			frameworks.add(mf);
		}
		insert frameworks;

		frameworkNames.remove(frameworkNames.size()-1);
		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < 50; i++) {
			Account org = UnitTestHelper.createOrganisationAccount('Test Organisation ' + i);
			org.Framework_Interest__c = String.join(frameworkNames, ';');
			accounts.add(org);
		}
		
		insert accounts;
	}

	static testMethod void execute_Test() {
		Test.startTest();
		FrameworkInterestGenerator_Batch crtu = new FrameworkInterestGenerator_Batch();
		Database.executeBatch(crtu);
		Test.stopTest();

		List<Account> accounts = [
			SELECT Id, Framework_Interest__c,
				(SELECT Id, Organisation__c, Framework__c, Framework__r.Name, Comments__c FROM Organisation_Frameworks__r)
			FROM Account
				WHERE RecordType.DeveloperName = 'Organisation'
					AND Framework_Interest__c != null
		];

		for(Account a : accounts) {
			System.assertEquals(10, a.Organisation_Frameworks__r.size(), '10 Organisation Frameworks should be created');
			for(Organisation_Framework__c orgFramework : a.Organisation_Frameworks__r) {
				System.assert(a.Framework_Interest__c.contains(orgFramework.Framework__r.Name), 
					'Organisation Framework should created for each value in Framework Interest picklist');
			}
		}

		List<Note> notes = [
			SELECT Id, ParentId, Body, Title
			FROM Note
				WHERE ParentId IN : accounts
		];
		System.assertEquals(accounts.size(), notes.size(), 'There should be one note added per Organisation\'s ' +
			'successfull Organisation Framework insertions');
	}

	static testMethod void execute_FrameworkMissing() {
		Account a = [SELECT Id, Framework_Interest__c
			FROM Account
				WHERE RecordType.DeveloperName = 'Organisation'
					AND Framework_Interest__c != null
				LIMIT 1
		];

		a.Framework_Interest__c += ';' + frameworkNames[10];
		update a;

		Test.startTest();
		FrameworkInterestGenerator_Batch crtu = new FrameworkInterestGenerator_Batch();
		Database.executeBatch(crtu);
		Test.stopTest();

		a = [
			SELECT Id, Framework_Interest__c,
				(SELECT Id, Organisation__c, Framework__c, Framework__r.Name, Comments__c FROM Organisation_Frameworks__r)
			FROM Account
				WHERE Id = :a.Id
		];

		System.assertEquals(10, a.Organisation_Frameworks__r.size(), '10 Organisation Frameworks should be created');

		List<String> fNames = a.Framework_Interest__c.split(';');
		for(Organisation_Framework__c orgFramework : a.Organisation_Frameworks__r) {
			for(Integer i = 0; i < fNames.size(); i++) {
				if(fNames[i] != orgFramework.Framework__r.Name) {
					continue;
				}
				fNames.remove(i);
			}
		}

		System.assertEquals(1, fNames.size(), 
			'One picklist value doesn\'t have matching Framework so Organisation Framework should be missing');

		List<Note> notes = [
			SELECT Id, ParentId, Body, Title
			FROM Note
				WHERE ParentId = :a.Id
		];
		System.assertEquals(2, notes.size(), 'There should be two notes added ' +
			'one for matching frameworks and another for not matching');
		Boolean isNotMatchedNoteAdded = false;
		for(Note n : notes) {
			if(n.Title.contains('NOT MATCHED')) {
				isNotMatchedNoteAdded = true;
			}
		}
		System.assert(isNotMatchedNoteAdded, 'Note for not matched record should be added');
	}

	static testMethod void execute_Error() {
		Master_Framework__c mf = [SELECT Id FROM Master_Framework__c LIMIT 1];
		Account a = [SELECT Id FROM Account LIMIT 1];
		delete mf;
		Organisation_Framework__c orgFramework = new Organisation_Framework__c(Organisation__c = a.Id,
			Framework__c = mf.Id);

		Test.startTest();
		FrameworkInterestGenerator_Batch crtu = new FrameworkInterestGenerator_Batch();
		crtu.orgFrameworks.add(orgFramework);
		Database.executeBatch(crtu);
		Test.stopTest();

		List<Exception_Log__c> exceptionLogs = [
			SELECT Id, Class_Name__c, Method_Name__c 
			FROM Exception_Log__c
			WHERE Running_User__c =: UserInfo.getUserId()
		];
		for(Exception_Log__c el : exceptionLogs) {
			System.assertEquals(FrameworkInterestGenerator_Batch.class.toString(), el.Class_Name__c, 
				'Exception should be generated by Batch Class');
		}
	}

	static testMethod void test_Schedulable() {
		String cronExp = '0 0 0 15 3 ? 2030';

		Test.startTest();
		String jobId = System.schedule('ScheduleApexClassTest',
			cronExp, new FrameworkInterestGenerator_Batch());

		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
			FROM CronTrigger WHERE id = :jobId
		];
		Test.stopTest();

		System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should be correctly added');
		System.assertEquals(0, ct.TimesTriggered, 'Job shoul not be executed before stop test');
		System.assertEquals('2030-03-15 00:00:00', String.valueOf(ct.NextFireTime), 
			'Next time job should be run should match the date from cron expression');
	 }
}