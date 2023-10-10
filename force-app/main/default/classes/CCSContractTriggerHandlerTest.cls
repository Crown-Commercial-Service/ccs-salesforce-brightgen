/*********************************************************************
Name:  CCSContractTriggerHandlerTest
Copyright © 2016  Salesforce
=====================================================================

Purpose: This is the Test Class for CCSContractTriggerHandlerTest.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles        2016-11-30   Initial version
*********************************************************************/

@isTest
private class CCSContractTriggerHandlerTest {

    /************************************************************
        Purpose: Test Records are shared After Edit
        Parameters: None
        Returns: Nothing
        Throws:
    *************************************************************/

    @isTest static void Test_VisibleContractsToPortalUser () {

        // Setup Our User and run the test
        // Create a Portal User linked to Contact and Associate with Account (Organisation)
        Id orgRecordType = UnitTestDataFactory.ACCOUNT_ORG_RT_ID;
        User orgUser = UnitTestDataFactory.createOrgContactPortalUser('PowerCustomerSuccess', null, true, PEM_Constants.ccsOrgSector, orgRecordType);
        Contact orgContact = [SELECT FirstName, LastName, AccountId from Contact WHERE Id = :orgUser.ContactId];
        Account orgAccount = [SELECT Name, RecordTypeId from Account WHERE Id = :orgContact.AccountId];

        // Create a Portal User linked to Contact and Associate with Account (Supplier)
        Id supRecordType = UnitTestDataFactory.ACCOUNT_SUP_RT_ID;
        User supUser = UnitTestDataFactory.createOrgContactPortalUser('PowerCustomerSuccess', null, true, PEM_Constants.ccsOrgSector, supRecordType);
        Contact supContact = [SELECT FirstName, LastName, AccountId from Contact WHERE Id = :supUser.ContactId];
        Account supAccount = [SELECT Name, RecordTypeId from Account WHERE Id = :supContact.AccountId];

        // Create Our Contract and Associate our Users - CCS Contract Status = Pending (Default)
        CCS_Contract__c ccsContract = UnitTestDataFactory.createContract(orgAccount.Id, orgContact.Id, supAccount.Id, supContact.Id);
        Insert ccsContract;

        // Run this as the Org User - should NOT be able to see Contract created Above
        System.RunAs(orgUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure no Users are found.
            System.assertEquals( 0, ccsContractCount, 'Check the Org User to make sure contracts are not visible.' );
        }

        // Run this as the Supplier User - should NOT be able to see Contract created Above
        System.RunAs(supUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure no Users are found.
            System.assertEquals( 0, ccsContractCount, 'Check the Supplier User to make sure contracts are not visible.' );
        }

        // Create Level 4 Code (so it passes existing validation rule)
        Category__c ccsCategory = UnitTestDataFactory.createCategory();
        insert(ccsCategory);
        Level_4_Categorisation_Code_for_Contract__c ccsLevel4Code = UnitTestDataFactory.createCatContract (ccsCategory.Id,ccsContract.Id);
        insert(ccsLevel4Code);

        // Change the Contract to Open & Set Level 4 Codes
        ccsContract.Status__c = 'Open';
        update ccsContract;

        // Run this as the Org User - should be able to see Contract created Above
        System.RunAs(orgUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure we can see our Contract
            System.assertEquals( 1, ccsContractCount, 'Check the Org User to make sure they can see the contract assigned.' );
        }

        // Run this as the Supplier User - should be able to see Contract created Above
        System.RunAs(supUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure we can see our Contract
            System.assertEquals( 1, ccsContractCount, 'Check the Sup User to make sure they can see the contract assigned.' );
        }

        // Change the Contract to Terminated - Both Share reasons should be removed.
        ccsContract.Status__c = 'Terminated';
        update ccsContract;

        // Run this as the Org User - should NOT be able to see Contract created Above
        System.RunAs(orgUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure no Users are found.
            System.assertEquals( 0, ccsContractCount, 'Check the Org User to make sure contracts are not visible.' );
        }

        // Run this as the Supplier User - should NOT be able to see Contract created Above
        System.RunAs(supUser) {
            Integer ccsContractCount = [SELECT Count() FROM CCS_Contract__c WHERE Id = :ccsContract.Id];
            // Check to make sure no Users are found.
            System.assertEquals( 0, ccsContractCount, 'Check the Supplier User to make sure contracts are not visible.' );
        }

    }
}