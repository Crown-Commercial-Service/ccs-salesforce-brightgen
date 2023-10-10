/*********************************************************************
Name:  PEM_MySettings_CC_Test
Copyright © 2016  Salesforce
=====================================================================

Purpose: This Test class for the My Settings and Change Password Component controller : PEM_MySettings_CC.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Steve O'Halloran   2016-11-17   Initial version
*********************************************************************/
@IsTest public class PEM_MySettings_CC_Test {
    
	@IsTest public static void testGetUser() {
        Test.startTest();
        User u = PEM_MySettings_CC.getUser();
        Test.stopTest();
        User currentUser = [select id, name from user where id=:UserInfo.getUserId()][0];
        system.assertEquals(u.Name,currentUser.name, 'Expected the name to match');
	}	
    
	@IsTest public static void testGetUserLanguages() {
        Test.startTest();
        List<PEM_MySettings_CC.picklistItem> items = PEM_MySettings_CC.getUserLanguageValues();
        Test.stopTest();
        system.assert(items.size()>0, 'Expected > 0 user picklist languages');
        PEM_MySettings_CC.picklistItem item = items[0];
        system.assertNotEquals(item.value, null, 'The picklist value should not be null');
        system.assertNotEquals(item.label, null, 'The picklist label should not be null');
	}

	@IsTest public static void testGetUserLocale() {
        Test.startTest();
        List<PEM_MySettings_CC.picklistItem> items = PEM_MySettings_CC.getUserLocaleValues();
        Test.stopTest();
        system.assert(items.size()>0, 'Expected > 0 user picklist locale');
        PEM_MySettings_CC.picklistItem item = items[0];
        system.assertNotEquals(item.value, null, 'The picklist value should not be null');
        system.assertNotEquals(item.label, null, 'The picklist label should not be null');
	}

	@IsTest public static void testGetUserTimezone() {
        Test.startTest();
        List<PEM_MySettings_CC.picklistItem> items = PEM_MySettings_CC.getUserTimezoneValues();
        Test.stopTest();
        system.assert(items.size()>0, 'Expected > 0 user picklist timezone');
        PEM_MySettings_CC.picklistItem item = items[0];
        system.assertNotEquals(item.value, null, 'The picklist value should not be null');
        system.assertNotEquals(item.label, null, 'The picklist label should not be null');
	}    

	@IsTest public static void testUpdateUserInfo() {
        Test.startTest();
        User u = PEM_MySettings_CC.getUser();
        u.AboutMe = 'test';
		PEM_MySettings_CC.updateUserInfo(u);      
        Test.stopTest();
        User currentUser = [select id, AboutMe from user where id=:UserInfo.getUserId()][0];
        system.assertEquals(currentUser.AboutMe, 'test', 'Expected the name to match');
	}    
    
	@IsTest public static void testUpdateUserPasswordDoNotMatch() {
        Test.startTest();
        User u = PEM_MySettings_CC.getUser();
        PEM_MySettings_CC.PEM_ResponseWrapper response = PEM_MySettings_CC.updateUserPassword('oldPassword', 'newPassword', 'confirmPassword', u);
        Test.stopTest();
        system.assertEquals(response.isSuccess, false, 'The passwords do not match so update should fail');
        system.assertNotEquals(response.message, null, 'The error message should not be null');
    }  
    
	@IsTest public static void testUpdateUserPasswordMatch() {
        Test.startTest();
        User u = PEM_MySettings_CC.getUser();
        PEM_MySettings_CC.PEM_ResponseWrapper response = PEM_MySettings_CC.updateUserPassword('oldPassword', 'newPassword', 'newPassword', u);
        Test.stopTest();
        system.assertEquals(response.isSuccess, true, 'The password match so update should pass');
        system.assertEquals(response.message, null, 'The error message should be null');
    }

	@IsTest public static void testUpdateUserPasswordMatchShort() {
        Test.startTest();
        User u = PEM_MySettings_CC.getUser();
        PEM_MySettings_CC.PEM_ResponseWrapper response = PEM_MySettings_CC.updateUserPassword('.', '.', '.', u);
        Test.stopTest();
        system.assertEquals(response.isSuccess, true, 'The password match so update should pass');
        system.assertEquals(response.message, null, 'The error message should be null');
    }    
    
}