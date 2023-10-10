/*********************************************************************
Name:  PEM_Profile_CC_Test
Copyright © 2016  Salesforce
=====================================================================

Purpose: TEST class for PEM_Profile_CC
This handles user details retrieve for the pfofile menu

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Steve O'Halloran   2016-11-11   Initial version
*********************************************************************/
@IsTest public class PEM_Profile_CC_Test {
	
	@IsTest public static void testGetUserInfo() {
        Test.startTest();
        User u = PEM_Profile_CC.getUserInfo();
        Test.stopTest();
        User currentUser = [select id, name, SmallPhotoUrl, UserType from user where id=:UserInfo.getUserId()][0];
        system.assertEquals(u.Name,currentUser.name, 'Expected the name to match');
        system.assertEquals(u.SmallPhotoUrl,currentUser.SmallPhotoUrl, 'Expected the SmallPhotoUrl to match');        
        system.assertEquals(u.UserType,currentUser.UserType, 'Expected the UserType to match');  
	}

	@IsTest public static void testGetUserWrapper() {
        Org_Settings__c os = new Org_Settings__c();
        os.PEM_SSO_Only__c = true;
        insert os;
        Test.startTest();
        PEM_Profile_CC.UserWrapper uw = new PEM_Profile_CC.UserWrapper();
        uw.user = new User();
        uw.SSOOnly = false;
        uw = PEM_Profile_CC.getUserWrapper();
        Test.stopTest();
        User currentUser = [select id, name, SmallPhotoUrl, UserType from user where id=:UserInfo.getUserId()][0];
        system.assertEquals(uw.user.Name,currentUser.name, 'Expected the name to match');
        system.assertEquals(uw.user.SmallPhotoUrl,currentUser.SmallPhotoUrl, 'Expected the SmallPhotoUrl to match');        
        system.assertEquals(uw.user.UserType,currentUser.UserType, 'Expected the UserType to match');  
        system.assertEquals(uw.SSOOnly,os.PEM_SSO_Only__c, 'Expected SSO Only setting to match'); 
	}    

}