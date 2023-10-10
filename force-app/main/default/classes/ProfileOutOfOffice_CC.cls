/*********************************************************************
 Name:  ProfileOutOfOffice_CC
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
public with sharing class ProfileOutOfOffice_CC {
	private String outOfOfficeMsg;
	public User currentUser {get; set;}
	public Boolean editMode {
		get {
			if(editMode == null) {
				return false;
			}
			return editMode;
		}
		private set;}

	public ProfileOutOfOffice_CC() {
		Id userId = ApexPages.currentPage().getParameters().get('sfdc.userId');
		this.currentUser = fetchUser(userId);
	}

	public ProfileOutOfOffice_CC(ApexPages.StandardController sc) {
		this.currentUser = fetchUser(((User)sc.getRecord()).Id);
	}

	private User fetchUser(Id userId) {
		if(String.isBlank(userId)) {
			userId = UserInfo.getUserId();
		}
		return [
			SELECT Id, Name, Out_Of_Office_Message__c, Out_Of_Office_Start_Date__c, Out_Of_Office_End_Date__c
			FROM User
			WHERE Id = :userId
		];
	}

	public String getOutOfOfficeMsg() {
		if(currentUser.Out_Of_Office_Message__c == null && editMode) {
			return String.format(Label.Out_of_Office_Default_Msg, new List<String>{currentUser.Name});
		}
		return currentUser.Out_Of_Office_Message__c;
	}

	public void setOutOfOfficeMsg(String msg) {
		outOfOfficeMsg = msg;
	}

	public PageReference edit() {
		editMode = true;
		return null;
	}

	public PageReference save() {
		currentUser.Out_Of_Office_Message__c = outOfOfficeMsg;
		update currentUser;
		editMode = false;
		return null;
	}

	public PageReference cancel() {
		editMode = false;
		return null;
	}
}