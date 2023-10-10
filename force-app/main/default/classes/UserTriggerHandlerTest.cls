/*********************************************************************
Name:  UserTriggerHandlerTest
Copyright © 2016  Salesforce
=====================================================================

Purpose: This is the Test Class for UserTriggerHandler.
         This Class is a handler for the UserTrigger .
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
 1.2    Simon Coles        2016-11-15   Update to add Org Sector on Create of profile
 1.3    Simon Coles        2016-12-8    Adding Contract User Assignment
*********************************************************************/

@isTest
private class UserTriggerHandlerTest {

    /************************************************************
        Purpose: This method Tests the UserTriggerHandler Trigger is working as expected.
                Create an Organization, Create Contact and Link to the Org, Create a User Linked to the Org and Contact.
                Check that Editing a Community User Profile updates the contact
        Parameters: None
        Returns: Nothing
        Throws:
    *************************************************************/

    @isTest static void Test_InsertNewPortalUser () {

        // Create an Internal User to create the Data (To get round the Portal User must have a role error)
        UserRole r = new UserRole(name = 'TEST ROLE');
        insert(r);

        // Create Admin User with Profile and Role
        User admUser = UnitTestDataFactory.createUserSystemAdmin('System Administrator',r.Id);

        // Create all users with the User created above with a Role.
        System.runAs(admUser) {

            // Create the Org & Link to a new Contact
            Account acct = new Account(Name='Test Portal Account');
            insert acct;

            // Create the Contact & Link to the Org
            Contact con = UnitTestDataFactory.createContact(acct.Id);
            insert con;

            // Create Portal User
            User u = UnitTestDataFactory.createUserPortal(con.Id, 'CCS Customer Community Plus Login User');
            insert u;

            // Check if the Company Name has been copied.
            Contact c1 = [SELECT Id, Portal_Reg_Org_Name__c FROM Contact WHERE Id = :con.Id LIMIT 1];
            System.assertEquals( c1.Portal_Reg_Org_Name__c, u.CompanyName );
        }

    }

    /************************************************************
        Purpose: This method creates, the Org, Contact & Account needed for the Portal User.
                 It then edits the contact to ensure the data is Synced.
        Parameters: None
        Returns: Nothing
        Throws:
    *************************************************************/

    @isTest static void Test_InsertThenSyncUserandContact () {

      // Portal User Type Options = CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess
      // Setup Our User and run the test
      User pu = UnitTestDataFactory.getPortalUser('PowerCustomerSuccess', null, true, PEM_Constants.ccsOrgSector);

      System.assert([select isPortalEnabled from user where id = :pu.id].isPortalEnabled, 'User was not flagged as portal enabled.');

      System.RunAs(pu) {
          // Edit the User
          pu.FirstName = 'New Firstname';
          pu.LastName = 'New Lastname';
          update pu;

          // Check if the User was Updated.
          User pu1 = [SELECT FirstName, ContactId FROM User WHERE Id = :pu.Id LIMIT 1];
          System.assertEquals( pu1.FirstName, 'New Firstname' );
      }

    }

    /************************************************************
        Purpose: This method creates, the Org, Contact & Account needed for the Portal User.
                 It then check if the user is associated with any COntracts via the Contact.
        Parameters: None
        Returns: Nothing
        Throws:
    *************************************************************/

    @isTest static void Test_ShareContractsWithUser () {
      // Create an Internal User to create the Data
      UserRole r = new UserRole(name = 'TEST ROLE');
      insert(r);

      // Create Admin User with Profile and Role
      User admUser = UnitTestDataFactory.createUserSystemAdmin('System Administrator',r.Id);

      // Create all users with the User created above with a Role.
      System.runAs(admUser) {

          // Create a Customer Org and Contact
          Id orgRecordType = UnitTestDataFactory.ACCOUNT_ORG_RT_ID;
          Account acctOrg = new Account(Name='Test Org Account', RecordTypeId = orgRecordType);
          insert acctOrg;
          Contact conOrg = UnitTestDataFactory.createContact(acctOrg.Id);
          insert conOrg;

          // Create a Supplier Org & Contact
          Id supRecordType = UnitTestDataFactory.ACCOUNT_SUP_RT_ID;
          Account acctSup = new Account(Name='Test Sup Account', RecordTypeId = supRecordType);
          insert acctSup;
          Contact supOrg = UnitTestDataFactory.createContact(acctSup.Id);
          insert supOrg;

          // Create a set of Contracts Set
          Integer count = 0;
          List<CCS_Contract__c> contractList = new List<CCS_Contract__c>();
          while (count < 5) {
            CCS_Contract__c contract = UnitTestDataFactory.createContract(acctOrg.Id, conOrg.Id, acctSup.Id, supOrg.Id);
            contractList.add(contract);
            count++;
          }
          Insert contractList;

          // Create Level 4 Code (se we can set the contracts to Open)
          Category__c ccsCategory = UnitTestDataFactory.createCategory();
          insert(ccsCategory);

          // Update the contracts
          List<Level_4_Categorisation_Code_for_Contract__c> Level4List = new List<Level_4_Categorisation_Code_for_Contract__c>();
          for(CCS_Contract__c c : contractList) {
            Level_4_Categorisation_Code_for_Contract__c ccsLevel4Code = UnitTestDataFactory.createCatContract (ccsCategory.Id,c.Id);
            Level4List.add(ccsLevel4Code);
          }
          insert(Level4List);

          // Set the Contracts to Open
          for(CCS_Contract__c c : contractList) {
            c.Status__c = 'Open';
          }
          update contractList;

          // We now have a Set of contracts, assigned to Customer and Supplier Contacts that are not portal users.
          // Check to make sure none of the Contacts have existing Shares
          Integer ccsExistingShares = [SELECT Count() FROM CCS_Contract__Share];
          // Check to make sure we can see our Contract
          System.assertEquals( 5, ccsExistingShares, 'Check existing shares, should only be 5 assigned to owner.' );

          // Create Customer User from Contact
          User orgUser = UnitTestDataFactory.createUserPortal(conOrg.Id, 'CCS Customer Community Plus Login User SSO Only');
          User supUser = UnitTestDataFactory.createUserPortal(supOrg.Id, 'CCS Customer Community Plus Login User');
        

          Test.startTest();
          insert orguser;
          insert supUser;
          Test.stopTest();

          // Check to make sure none of the Contacts have existing Shares
          Integer ccsNewShares = [SELECT Count() FROM CCS_Contract__Share WHERE RowCause != 'Owner'];
          // Check to make sure we can see our Contract
          System.assertEquals( 10, ccsNewShares, 'Check existing shares, should only be 10 Assigned.  (5 contracts with 2 shares on each)' );

          // Login as each User and Check they can see their records;
          // Run this as the Org User - should NOT be able to see Contract created Above
          System.RunAs(orgUser) {
              Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id IN :contractList];
              // Check to make sure no Users are found.
              System.assertEquals( 5, ccsContractCount, 'Check the Org User to make sure they can see the contracts.' );
          }

          // Run this as the Supplier User - should NOT be able to see Contract created Above
          System.RunAs(supUser) {
              Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id IN :contractList];
              // Check to make sure no Users are found.
              System.assertEquals( 5, ccsContractCount, 'Check the Supplier User to make sure they can see the contracts.' );
          }

          // Edit the User and make them inactive.
          orgUser.isActive = false;
          Update orgUser;

          // Make them active again
          orgUser.isActive = true;
          Update orgUser;

          // Login as each User and Check they can see their records;
          // Run this as the Org User - should NOT be able to see Contract created Above
          System.RunAs(orgUser) {
              Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id IN :contractList];
              // Check to make sure no Users are found.
              System.assertEquals( 5, ccsContractCount, 'Check the Org User to make sure they can see the contracts.' );
          }

          // Run this as the Supplier User - should NOT be able to see Contract created Above
          System.RunAs(supUser) {
              Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id IN :contractList];
              // Check to make sure no Users are found.
              System.assertEquals( 5, ccsContractCount, 'Check the Supplier User to make sure they can see the contracts.' );
          }

      }
    }

}