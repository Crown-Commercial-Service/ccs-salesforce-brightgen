/*********************************************************************
Name:  UserTriggerHandler
Copyright © 2016  Salesforce
=====================================================================

Purpose: This Class is a handler for the UserTriggerHandler Trigger.
When a portal user is created, update the contact record and set the Company Name specified at registration
into the Portal_Reg_Org_Name__c Field.
Once the user has been update with the Portal_Reg_Org_Name__c Field, Create a Case using Process Builder.

A secondary purpose is when a Portal User makes changes to their user profile, keep the Contact
fields Synced.

Adding another method to ensure Contracts Users are associated with are shared correctly.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles        2016-11-03   Initial version
 1.1    Simon Coles        2016-11-10   Adding update to Sync user data with Contact.
 1.2    Simon Coles        2016-11-15   Check Org Sector and assign appropriate Liscence
 1.3    Simon Coles        2016-12-8    Adding Contract User Assignment
*********************************************************************/

public without sharing class UserTriggerHandler {

    // Handlers
    public static void onAfterInsert(List<User> triggerNew)
    {
      // Disable with custom setting
      if (!TriggerSwitchService.isTriggerSwitchOff('UserContactRegistration')) {
        updateContact(triggerNew);
      }
      // Disable with custom setting
      if (!TriggerSwitchService.isTriggerSwitchOff('ShareContractsWithUser')) {
        ShareContractsWithUser(triggerNew);
      }
    }

    public static void onAfterUpdate(List<User> triggerNew)
    {
      // Disable by a custom setting
      if (!TriggerSwitchService.isTriggerSwitchOff('SyncUserandContact')) {
        SyncUserandContact(triggerNew);
      }
      // Disable with custom setting
      if (!TriggerSwitchService.isTriggerSwitchOff('ShareContractsWithUser')) {
        ShareContractsWithUser(triggerNew);
      }
    }

    public static void onBeforeInsert(List<User> triggerNew)
    {
      // Disable by a custom setting
      if (!TriggerSwitchService.isTriggerSwitchOff('CheckUserOrgSector')) {
        //CheckUserOrgSector(triggerNew);
      }
    }

    /************************************************************
        Purpose: This method receives a list of new users being added.  For each user we check that they are a portal User
                 and copy the Company Name entered on registration to the associated Contact record.
        Parameters: new Users via Trigger.new
        Returns: Nothing but updates associated contact records.
        Throws:
    *************************************************************/

    public static void updateContact(List<User> triggerNew) {
      List<Contact> contactList = new List<Contact>(); // Set up our list of contact to add.

      // Loop through each user and update the Organisation name from the Registration Page.
      for(User user : triggerNew ){
          // Only do this check if portal user created with contact.
          if((user.contactId != null ) && (user.isPortalEnabled == true) && (user.companyName != null)) {
              // Setup our list of Contacts to update
              Contact con = new Contact( Id = user.contactId, Portal_Reg_Org_Name__c = user.companyName );
              contactList.add(con);
          }
      }

      // Update Records
      upsert contactList;
    }

    /************************************************************
        Purpose: This method receives a list of new users being added.  For each user we check that they are a portal User
                 and copy the Company Name entered on registration to the associated Contact record.
        Parameters: updated Users via Trigger.new
        Returns: Nothing but updates associated contact records.
        Throws:
    *************************************************************/

    public static void SyncUserandContact(List<User> triggerNew) {

      // Only complete this if its a Portal User
      if((UserInfo.getUserType() == 'CustomerSuccess') || (UserInfo.getUserType() == 'PowerCustomerSuccess')) {
        // Set up our list of contact to update.
        List<Contact> contactList = new List<Contact>();

        // Loop through each user
        for(User user : triggerNew ){
            // Only do this check if portal user created with contact.
            if((user.contactId != null ) && (user.isPortalEnabled == true)) {
                // Setup our list of Contacts to update
                // Only Update the contact details if they are populated with Data
                Contact con = new Contact( Id = user.contactId);
                if(user.firstName != null) { con.FirstName = user.firstName; }
                if(user.lastName != null) { con.LastName = user.lastName; }
                if(user.title != null) { con.Title = user.title; }
                if(user.phone != null) { con.Phone = user.phone; }
                if(user.MobileNumber__c != null) { con.MobilePhone = user.MobileNumber__c; }
                contactList.add(con);
            }
        }
        // Update Records
        update contactList;
      }

    }

    /************************************************************
        Purpose: This method receives a list of new users being added.  For each user, check which Sector
                 The Org belong and assign the correct liscense.
        Parameters: updated Users via Trigger.new
        Returns: Nothing but updates associated contact records.
        Throws:
    *************************************************************/

    public static void CheckUserOrgSector(List<User> triggerNew) {

      // Get the Contact ID then Check the Org Sector
      List<id> contactIds = new List<id>();

      // Loop through each user and get the ContactID
      for(User user : triggerNew ){
        contactIds.add(user.ContactId);
      }

      // Get a List of Contacts and Sector, Loop and if Sector is Government, Add them to a list.
      List<Contact> contactList = [SELECT Id, Sector__c FROM Contact WHERE Id IN :contactIds];

      Set<Id> govContacts = new Set<Id>();
      for(Contact contact : contactList ){
        // If the Sector is Central Government then add them to the list.
        if(contact.Sector__c == PEM_Constants.ccsOrgSector) {
          govContacts.add(contact.Id);
        }
      }

      // Get ID of Plus User
      Profile p = [select id from profile where name= :PEM_Constants.ccsPlusLicense];

      // Update the Liscence for the Contacts that match
      for(User user : triggerNew ){
        if(govContacts.contains(user.ContactId)) {
          user.profileId = p.id;
        }
      }

    }

    /************************************************************
        Purpose: This method processes the user being added.  If the user is portal user,
        then make sure any Contracts the User Contact is connected is shared if the User is Active.
        Parameters: updated Users via Trigger.new
        Returns: Nothing but updates associated contact records.
        Throws:
    *************************************************************/

    public static void ShareContractsWithUser(List<User> triggerNew) {
        // Loop round the users being created
        Map<Id,Id> ContactUserMap = new Map<Id,Id>();
        for(User u : triggerNew) {
          // Get the associated Contact and if they user is Active, add it to the list to process
          if(u.isActive) {
            ContactUserMap.put(u.ContactId,u.Id);
          }
        }

        // For each contact, check to see if they are assigned to any Open Contracts
        List<Contact> contactList = new List<Contact>([Select Id FROM Contact WHERE Id IN :ContactUserMap.keyset()]);
        // Get Open Contracts where the User is either the Customer or Supplier
        List<CCS_Contract__c> contractList = new List<CCS_Contract__c>([Select Id, Customer_Contact__c, Supplier_Contact__c FROM CCS_Contract__c WHERE Status__c = 'Open' AND (Customer_Contact__c IN :contactList OR Supplier_Contact__c IN :contactList)]);

        // Loop through Contract List and Add the Share for the User
        Map<Id,Id> ContractMapShareMap = new Map<Id,Id>();
        for (CCS_Contract__c c :contractList) {
          // if Customer OR Supplier matches contact in UserContactMap then add share
          if(ContactUserMap.containsKey(c.Customer_Contact__c)) {
            ContractMapShareMap.put(c.Id, ContactUserMap.get(c.Customer_Contact__c));
          } else if(ContactUserMap.containsKey(c.Supplier_Contact__c)) {
            ContractMapShareMap.put(c.Id, ContactUserMap.get(c.Supplier_Contact__c));
          }
        }
        insertCCSContracts (ContractMapShareMap);

    }

    /************************************************************
        Purpose: This method inserts the Share Reasons.  It need to be in an @Future method to
        prevent Mixed DML operation errors.
        Parameters: CCS Sharess to add
        Returns:
        Throws:
    *************************************************************/
    @future
    Public static void insertCCSContracts (Map<Id,Id> ContractMapShareMap) {
      // Loop through and add the shares
      List<CCS_Contract__Share> contractShares = new List<CCS_Contract__Share>();
      CCS_Contract__Share contractShare;
      for (Id contractId : ContractMapShareMap.keyset()) {
        contractShare = new CCS_Contract__Share();
        contractShare.ParentId = contractId;
        contractShare.UserOrGroupId = ContractMapShareMap.get(contractId);
        contractShare.AccessLevel = 'read';
        contractShare.RowCause = Schema.CCS_Contract__Share.RowCause.ShareOpenContractsToContact__c;
        contractShares.add(contractShare);
      }

      // Insert sharing records and capture save result
      try {
        Database.insert(contractShares,true);
      } catch(Exception e) {
        ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'UserTriggerHandler',
            'ShareContractsWithUser' , 'Database Insertion ShareContractsWithUser', e ,'ERROR',null,null,
            (Integer)DateTime.now().getTime(), 'PEM');
      }
    }

}