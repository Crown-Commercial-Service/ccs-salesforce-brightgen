/*********************************************************************
Name:  CCSContractTriggerHandler
Copyright © 2016  Salesforce
=====================================================================

Purpose: This Class is a handler for the CCSContractTrigger.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles        2016-11-03   Initial version
*********************************************************************/

public without sharing class CCSContractTriggerHandler {

    // Handlers
    public static void onAfterInsert(List<CCS_Contract__c> triggerNew, Map<id,CCS_Contract__c> triggerOldMap)
    {
      ShareContractCustomerContact(triggerNew, null);
    }

    public static void onAfterUpdate(List<CCS_Contract__c> triggerNew, Map<id,CCS_Contract__c> triggerOldMap)
    {
    	ShareContractCustomerContact(triggerNew, triggerOldMap);
    }

    /************************************************************
	    Purpose: When a contract is inserted or edited and the Status is set to Open,
	    add a Apex sharing to enable the Contract Customer Contact Read only access.
	    If the Status is changed to anything but Open then remove the share.

	    Parameters: inserted / updated Contracts via Trigger.new
	    Returns: Nothing but updates sharing rules records.
	    Throws:
    *************************************************************/

    public static void ShareContractCustomerContact(List<CCS_Contract__c> triggerNew, Map<id,CCS_Contract__c> triggerOldMap) {

	    List<CCS_Contract__c> contractsToProcess = new List<CCS_Contract__c>();
	    // Pair our contract / contacts (users)
	    Map<Id, Set<Id>> contractSharestoDeleteMap = new Map<Id, Set<Id>>();
	    // Only remove old users if we're updating the record.
      if(triggerOldMap != null) {
        // Check to see if either the Status, Customer Contact or Supplier Contact Have Changed
        for(CCS_Contract__c newContract : triggerNew){
          CCS_Contract__c oldContract = triggerOldMap.get(newContract.Id);
          // If Any of these fields change then we need to process only those records
          if((newContract.Customer_Contact__c != oldContract.Customer_Contact__c) || (newContract.Supplier_Contact__c != oldContract.Supplier_Contact__c) || ((oldContract.Status__c == 'Open') || (NewContract.Status__c != 'Open'))) {
						contractsToProcess.add(newContract);
            // Setup a Map of Contract Id & Contacts Assigned
            Set<id> contactList = new Set<Id>();
            contactList.add(newContract.Customer_Contact__c);
            contactList.add(newContract.Supplier_Contact__c);
            contactList.add(oldContract.Customer_Contact__c);
            contactList.add(oldContract.Supplier_Contact__c);
            // Associate the contact with the contract
            contractSharestoDeleteMap.put(newContract.Id, contactList);
          }
        }

        // Only do the following if we have users to remove
        if(!contractSharestoDeleteMap.isEmpty()) {
          // Get the list of users from Contacts
          Set<id> contactList = new Set<Id>();
          for(Id contractIds : contractSharestoDeleteMap.keySet()) {
            for(Id contactIds : contractSharestoDeleteMap.get(contractIds)) {
              contactList.add(contactIds);
            }
          }
          // Make a map of Contact ID's to User Id's
          List<User> userList = new List<User>([Select Id, ContactId FROM User WHERE ContactId IN :contactList]);
          Map<Id,Id> contactUserMap = new Map<Id,Id>();
          for(User user : userList) {
            contactUserMap.put(user.ContactId,user.Id);
          }

          // Check existing shares on each Contract
          List<CCS_Contract__Share> existingShares = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM CCS_Contract__Share WHERE ParentId IN: contractsToProcess AND RowCause = 'ShareOpenContractsToContact__c'];
          List<CCS_Contract__Share> shareReasonToRemove = new List<CCS_Contract__Share>();
          // Loop Round existing shares for the contracts we are processing
          for(CCS_Contract__Share shareReason : existingShares) {
          	// Get the contacts associated with the Contract
            Set<Id> relatedContacts = contractSharestoDeleteMap.get(shareReason.ParentId);
            // Does the current share reason contain any of our contact?
            for(Id relatedContact : relatedContacts) {
              if(shareReason.UserOrGroupId == contactUserMap.get(relatedContact)) {
                shareReasonToRemove.add(shareReason);
              }
          	}
          }
          // Remove Existing Share Reasons
          try {
            Database.delete(shareReasonToRemove,true);
          } catch(Exception e) {
            ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'CCSContractTriggerHandler',
              'ShareContractCustomerContact' , 'Database Delete shareReasonToRemove', e ,'ERROR',null,null,
        			(Integer)DateTime.now().getTime(), 'PEM'
            );
          }
      }
    } else {
        // Contracts to process is every record in the tigger
        contractsToProcess = triggerNew;
    }

    // Loop Contracts only if the Data has changed in Status, Supplier or Customer fields
    Set<Id> contactList = new Set<Id>();
    for(CCS_Contract__c c : contractsToProcess){
      if(c.Status__c == 'Open') {
        if(c.Customer_Contact__c != null) {
            contactList.add(c.Customer_Contact__c);
        }
        contactList.add(c.Supplier_Contact__c);
      }
    }

    // Get a list of Associated Users as we need the User ID to set up the share.
    List<User> userList = new List<User>([Select ContactId, IsActive FROM User WHERE ContactId IN :contactList]);

    // Create a map from Contact & Supplier to User
    Map<Id, Id> contactUserMap = new Map<Id,Id>();
    for(User u : userList){
      // If the user is set to inactive - Don't add them.
      if(u.IsActive) {
          contactUserMap.put(u.ContactId,u.Id);
      }
    }

    // Create new sharing object for the custom object CCS Contract.
    List<CCS_Contract__Share> contractShares = new List<CCS_Contract__Share>();
    CCS_Contract__Share contractShare;

    // Setup our shares only if the Status is Open
    for(CCS_Contract__c contract : contractsToProcess){
      if(contract.Status__c == 'Open') {
        // Do we have the User in the Map - if not they are Inactive so don't add them.
        if(contactUserMap.get(contract.Customer_Contact__c) != null) {
          // Add the Contact Share Record
          contractShare = new CCS_Contract__Share();
          contractShare.ParentId = contract.Id;
          contractShare.UserOrGroupId = contactUserMap.get(contract.Customer_Contact__c);
          contractShare.AccessLevel = 'read';
          contractShare.RowCause = Schema.CCS_Contract__Share.RowCause.ShareOpenContractsToContact__c;
          contractShares.add(contractShare);
        }
        if(contactUserMap.get(contract.Supplier_Contact__c) != null) {
        	// Repeat for Supplier
          contractShare = new CCS_Contract__Share();
          contractShare.ParentId = contract.Id;
          contractShare.UserOrGroupId = contactUserMap.get(contract.Supplier_Contact__c);
          contractShare.AccessLevel = 'read';
          contractShare.RowCause = Schema.CCS_Contract__Share.RowCause.ShareOpenContractsToContact__c;
          contractShares.add(contractShare);
        }
      }
    }

    // Insert sharing records and capture save result
    try {
        Database.insert(contractShares,true);
    } catch(Exception e) {
        ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'CCSContractTriggerHandler',
            'ShareContractCustomerContact' , 'Database Insertion contractShares', e ,'ERROR',null,null,
            (Integer)DateTime.now().getTime(), 'PEM'
        );

    }
  }

}