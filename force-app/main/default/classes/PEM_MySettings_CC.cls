/*********************************************************************
Name:  PEM_MySettings_CC
Copyright © 2016  Salesforce
=====================================================================

Purpose: This class acts as the controller for the My Settings Component
    	Used to allow Buyers to change their password from the custom My Settings Page
        The custom My Settings page has a Change Password link for Buyers but
        for Suppliers it links off to the SID4GOV site for change password because their 
        identities are managed there.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Steve O'Halloran   2016-11-14   Initial version
*********************************************************************/
public with sharing class PEM_MySettings_CC {
	
    // Picklist item wrapper
    public class picklistItem {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
    }

    // Response wrapper to add custom error messages
    public class PEM_ResponseWrapper {
    
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        @AuraEnabled public Map<String,Object> values;
    
        public PEM_ResponseWrapper(Boolean isSuccess, String message) {
            this.isSuccess = isSuccess;
            this.message = message;
        }
    
        public PEM_ResponseWrapper(Boolean isSuccess, Map<String,Object> values) {
            this.isSuccess = isSuccess;
            this.values = values;
        }
    }    
        
    @AuraEnabled
	public static User getUser() {
		return [SELECT Id, Name, Email, Username, UserType,
				LanguageLocaleKey, LocaleSidKey, TimeZoneSidKey, Is_Supplier__c 
			FROM
				User
			WHERE Id = :UserInfo.getUserId()];
	}

	@AuraEnabled 
	public static User updateUserInfo(User user) {
		update user;
		return user;
	}

	@AuraEnabled
	public static PEM_ResponseWrapper updateUserPassword(String oldPassword, String newPassword, String confirmPassword, User user) {
        
  		if ( newPassword != confirmPassword ) {
  			return new PEM_MySettings_CC.PEM_ResponseWrapper(false, 'Password do not match.');
  		}
		try {
			Site.changePassword(newPassword, confirmPassword, oldPassword);			
		} catch(Exception e) {
			return new PEM_MySettings_CC.PEM_ResponseWrapper(false, e.getMessage());
		}
		return new PEM_MySettings_CC.PEM_ResponseWrapper(true, new Map<String,Object>{'user' => PEM_MySettings_CC.getUser()});
	}

    @AuraEnabled
    public static List<picklistItem> getUserLanguageValues(){
        return PEM_MySettings_CC.getPickListValues(user.LanguageLocaleKey.getDescribe());
    }

    @AuraEnabled
    public static List<picklistItem> getUserLocaleValues(){
        return PEM_MySettings_CC.getPickListValues(user.LocaleSidKey.getDescribe());
    }

    @AuraEnabled
    public static List<picklistItem> getUserTimezoneValues(){
        return PEM_MySettings_CC.getPickListValues(user.TimeZoneSidKey.getDescribe());
    }

    private static List<picklistItem> getPickListValues(Schema.DescribeFieldResult fieldResult) {
        List<picklistItem> options = new List<picklistItem>();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            picklistItem pi = new picklistItem();
            pi.value = f.getValue();
            pi.label = f.getLabel();
            options.add(pi);
        }    
        return options;        
    }
}