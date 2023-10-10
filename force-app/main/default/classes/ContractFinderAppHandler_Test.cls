@isTest
private class ContractFinderAppHandler_Test {
    
    static String ADMINISTRATOR_PROFILE                         = 'System Administrator';
    static String COMMUNITY_PROFILE                             = 'Customer Community Plus Login User';
    static String INTERNAL_ACCOUNT_NAME                         = 'Crown Commercial Service';    
    static String URN_FIELD                    = 'Account_URN__c';
    
    @testSetup
    static void createGlobalTestData() {
        
        
        // Create the internal CCS Account to refer to
        Account ccsInternalAccount  = new Account();
        ccsInternalAccount.Name     = INTERNAL_ACCOUNT_NAME;
        insert ccsInternalAccount;
        
        Org_Settings__c orgSettings = new Org_Settings__c();
        orgSettings.Internal_Account_Id__c = ccsInternalAccount.Id;
        insert orgSettings;
        
    }  
    
    @isTest 
    static void testCustomAttributes() {
        
        Org_Settings__c orgSettings = Org_Settings__c.getOrgDefaults();
        
        ConnectedApplication testConnectedApp = [SELECT Id FROM ConnectedApplication LIMIT 1];  
        
        Id internalAccId = orgSettings.Internal_Account_Id__c;
        String internalAccountQuery = 'SELECT Id, Name, ' + URN_FIELD + ' FROM Account WHERE Id = :internalAccId';   
        List<Account> internalAccountList = Database.query(internalAccountQuery);
        Account internalAccount = internalAccountList.get(0);
        
        List<UserRole> InternalRoles   = [SELECT Id FROM UserRole WHERE PortalRole = null ]; // account owner must have a role (any one) for community activity, so setting just in case and for future tests
        List<String> roleIds = new List<String>();
        for (UserRole ur : InternalRoles){
            roleIds.add(ur.Id);
        }
        
        // Create the community user as part of a runAs in order to avoid mixed DML error
        System.runAs(UnitTestDataFactory.createUserSystemAdmin(ADMINISTRATOR_PROFILE)) {
            
       		User accountOwnerUser   = [SELECT Id FROM User WHERE isActive = true AND UserRoleId in :roleIds LIMIT 1];
       		// Create an account for the community user. Note that the account owner MUST have a role  
     	    String testAccountName  = 'Test Account ' + UnitTestDataFactory.getRandomString(8);	
        	Account testAcc = UnitTestDataFactory.createSupplierAccount(testAccountName);
        	testAcc.OwnerId = accountOwnerUser.Id;
       	    insert testAcc;
            Contact communityContact = UnitTestDataFactory.createContact(testAcc.Id); 
            insert communityContact; 
            
            User communityUser = UnitTestDataFactory.createUserSystemAdmin('CCS Customer Community Plus Login User SSO Only');
            communityUser.ContactId = communityContact.Id;
            insert communityUser;  
            
            Map<String, String> inputAttributes  = new Map<String, String>();
            Map<String, String> outputAttributes = new Map<String, String>();
            
            test.startTest();   
            
            ContractFinderAppHandler contractFinderAttributes = new ContractFinderAppHandler();
            // test outputs for internal user
            outputAttributes = contractFinderAttributes.customAttributes(accountOwnerUser.Id, testConnectedApp.Id, inputAttributes, null);
            System.assert(outputAttributes.containsKey('organisation_duns_number'));
            
            System.assertEquals(internalAccount.get('Account_URN__c'), outputAttributes.get('organisation_urn'));
            
            // test outputs for community user
            outputAttributes = contractFinderAttributes.customAttributes(communityUser.Id, testConnectedApp.Id, inputAttributes, null); 
            System.assert(outputAttributes.containsKey('organisation_duns_number'));
            
            System.assertEquals(String.valueOf(testAcc.DUNS_Number__c), outputAttributes.get('organisation_duns_number'));
            
            // Test output for CCS record not found
            orgSettings.Internal_Account_Id__c = '0039E00000DlZBv'; // Set CCS record to some random value
            update orgSettings;
            outputAttributes = contractFinderAttributes.customAttributes(accountOwnerUser.Id, testConnectedApp.Id, inputAttributes, null);
            
            System.assertEquals('232204180', outputAttributes.get('organisation_duns_number'));

            test.stopTest();
        }
    }  
}