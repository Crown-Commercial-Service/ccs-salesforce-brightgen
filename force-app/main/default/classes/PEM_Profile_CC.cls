/*********************************************************************
Name:  PEM_Profile_CC
Copyright © 2016  Salesforce
=====================================================================

Purpose: This class acts as the controller for the Profile Menu and User Profile Component.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Steve O'Halloran   2016-11-11   Initial version
*********************************************************************/
public with sharing class PEM_Profile_CC {

    public class UserWrapper {
        @AuraEnabled public User user;
        @AuraEnabled public boolean SSOOnly;
    }
    
    @AuraEnabled
    public static UserWrapper getUserWrapper() {
        boolean SSOOnly = Org_Settings__c.getInstance().PEM_SSO_Only__c;
        User u = [SELECT Id, Name, SmallPhotoUrl, UserType
                  FROM 
                  User
                  WHERE Id = :UserInfo.getUserId()];
        UserWrapper uw = new UserWrapper();
        uw.user = u;
        uw.SSOOnly = SSOOnly;
        return uw;
    }
    
    
	@AuraEnabled
	public static User getUserInfo() {
		return [SELECT Id, Name, SmallPhotoUrl, UserType
			FROM 
				User
			WHERE Id = :UserInfo.getUserId()]; 
	}
}