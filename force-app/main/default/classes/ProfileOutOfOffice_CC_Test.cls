/*********************************************************************
 Name:  ProfileOutOfOffice_CC_Test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller for ProfileOutOfOffice page
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-20     Initial version
 *********************************************************************/
@isTest
private class ProfileOutOfOffice_CC_Test {
	private static final String STANDARD_USER = 'Standard User';
	
	@testSetup
	static void createData() {
		User u = UnitTestDataFactory.createUserSystemAdmin('Standard User');
		u.IsActive = true;
		insert u;
	}

	static testMethod void test_getOutOfOfficeMsg() {
		User u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER
				AND IsActive = true
			LIMIT 1
		];
		String defMsg = String.format(Label.Out_of_Office_Default_Msg, new List<String>{u.Name});
		PageReference pageRef = Page.ProfileOutOfOffice;
		pageRef.getParameters().put('sfdc.userId', String.valueOf(u.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ProfileOutOfOffice_CC poo = new ProfileOutOfOffice_CC();
		poo.edit();
		String msgFromController = poo.getOutOfOfficeMsg();
		Test.stopTest();

		System.assertEquals(defMsg, msgFromController, 'Out of office message should be equal to default');
	}

	static testMethod void test_getOutOfOfficeMsg_StController() {
		User u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER 
				AND IsActive = true
			LIMIT 1
		];
		ApexPages.StandardController sc = new ApexPages.StandardController(u);
		String defMsg = String.format(Label.Out_of_Office_Default_Msg, new List<String>{u.Name});
		PageReference pageRef = Page.ProfileOutOfOffice;
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ProfileOutOfOffice_CC poo = new ProfileOutOfOffice_CC(sc);
		poo.edit();
		String msgFromController = poo.getOutOfOfficeMsg();
		Test.stopTest();

		System.assertEquals(defMsg, msgFromController, 'Out of office message should be equal to default');
	}

	static testMethod void test_getOutOfOfficeMsg_FromUser() {
		User u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER 
				AND IsActive = true
			LIMIT 1
		];
		String userOutMsg = 'I am out of office';
		u.Out_Of_Office_Message__c = userOutMsg;
		update u;
		ApexPages.StandardController sc = new ApexPages.StandardController(u);
		PageReference pageRef = Page.ProfileOutOfOffice;
		pageRef.getParameters().put('sfdc.userId', String.valueOf(u.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ProfileOutOfOffice_CC poo = new ProfileOutOfOffice_CC(sc);
		String msgFromController = poo.getOutOfOfficeMsg();
		Test.stopTest();

		System.assertEquals(userOutMsg, msgFromController, 'User set out of office message should be returned');
	}

	static testMethod void test_getOutOfOfficeMsg_CurrentUser() {
		User u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER
				AND IsActive = true
			LIMIT 1
		];
		String defMsg = String.format(Label.Out_of_Office_Default_Msg, new List<String>{u.Name});
		PageReference pageRef = Page.ProfileOutOfOffice;
		Test.setCurrentPage(pageRef);

		Test.startTest();
		String msgFromController;
		System.runAs(u) {
			ProfileOutOfOffice_CC poo = new ProfileOutOfOffice_CC();
			poo.edit();
			msgFromController = poo.getOutOfOfficeMsg();
		}
		Test.stopTest();

		System.assertEquals(defMsg, msgFromController, 'Default message with current user should be returned');
	}

	static testMethod void test_save() {
		User u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER
				AND IsActive = true
			LIMIT 1
		];
		String customMsg = 'Hi, I am off';
		PageReference pageRef = Page.ProfileOutOfOffice;
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(u);
		ProfileOutOfOffice_CC poo = new ProfileOutOfOffice_CC(sc);
		Boolean editModeStart = poo.editMode;
		poo.edit();
		Boolean editModeAfterSet = poo.editMode;
		poo.cancel();
		poo.setOutOfOfficeMsg(customMsg);
		poo.save();
		Test.stopTest();

		u = [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c 
			FROM User
			WHERE Profile.Name = :STANDARD_USER
				AND IsActive = true
			LIMIT 1
		];

		System.assertNotEquals(true, editModeStart, 'Edit mode should be off on load');
		System.assertEquals(true, editModeAfterSet, 'Edit mode should be on after executing edit method');
		System.assertEquals(customMsg, u.Out_Of_Office_Message__c, 'Field should be updated with custom message');
	}
}