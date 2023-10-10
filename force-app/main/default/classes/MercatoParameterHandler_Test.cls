@isTest
private class MercatoParameterHandler_Test {

  static String MERCATO_SP_PARAMETER_ACTIVE_FLAG              = 'MERCATO_SP_PARAMETER_ACTIVE_FLAG';
  static String MERCATO_SP_PARAMETER_LAST_UPDATED_DATE        = 'MERCATO_SP_PARAMETER_LAST_UPDATED_DATE';
  static String MERCATO_SP_PARAMETER_ORGANIZATION_NAME        = 'MERCATO_SP_PARAMETER_ORGANIZATION_NAME';
  static String MERCATO_SP_PARAMETER_ORGANIZATION_URN         = 'MERCATO_SP_PARAMETER_ORGANIZATION_URN';
  static String MERCATO_SP_PARAMETER_USER_FAMILY_NAME         = 'MERCATO_SP_PARAMETER_USER_FAMILY_NAME';
  static String MERCATO_SP_PARAMETER_USER_GIVEN_NAME          = 'MERCATO_SP_PARAMETER_USER_GIVEN_NAME';
  static String MERCATO_SP_PARAMETER_EMAIL_ADDRESS            = 'MERCATO_SP_PARAMETER_EMAIL_ADDRESS';

  static String MERCATO_SP_PARAMETER_ACTIVE_FLAG_VALUE        = 'user_active_flag';
  static String MERCATO_SP_PARAMETER_LAST_UPDATED_DATE_VALUE  = 'user_last_updated_date';
  static String MERCATO_SP_PARAMETER_ORGANIZATION_NAME_VALUE  = 'organization_name';
  static String MERCATO_SP_PARAMETER_ORGANIZATION_URN_VALUE   = 'organization_urn';
  static String MERCATO_SP_PARAMETER_USER_FAMILY_NAME_VALUE   = 'user_family_name';
  static String MERCATO_SP_PARAMETER_USER_GIVEN_NAME_VALUE    = 'user_given_name';
  static String MERCATO_SP_PARAMETER_EMAIL_ADDRESS_VALUE      = 'user_email';

  static String ADMINISTRATOR_PROFILE                         = 'System Administrator';
  static String COMMUNITY_PROFILE                             = 'Customer Community Plus Login User';
  static String INTERNAL_ACCOUNT_NAME                         = 'Crown Commercial Service';
    
  static String URN_FIELD                    = 'Account_URN__c';

  @testSetup
  static void createGlobalTestData() {

    // create the necessary Custom Settings
    List<Openid_SSO_Settings__c> listOfSSOCustomSettings = new List<Openid_SSO_Settings__c>();

    Openid_SSO_Settings__c userActiveFlag       = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c userLastUpdatedDate  = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c organizationName     = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c organizationURN      = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c userFamilyName       = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c userGivenName        = new Openid_SSO_Settings__c();
    Openid_SSO_Settings__c userEmail            = new Openid_SSO_Settings__c();

    userActiveFlag.Name           = MERCATO_SP_PARAMETER_ACTIVE_FLAG;
    userActiveFlag.Value__c       = MERCATO_SP_PARAMETER_ACTIVE_FLAG_VALUE;

    userLastUpdatedDate.Name      = MERCATO_SP_PARAMETER_LAST_UPDATED_DATE;
    userLastUpdatedDate.Value__c  = MERCATO_SP_PARAMETER_LAST_UPDATED_DATE_VALUE;

    organizationName.Name         = MERCATO_SP_PARAMETER_ORGANIZATION_NAME;
    organizationName.Value__c     = MERCATO_SP_PARAMETER_ORGANIZATION_NAME_VALUE;

    organizationURN.Name          = MERCATO_SP_PARAMETER_ORGANIZATION_URN;
    organizationURN.Value__c      = MERCATO_SP_PARAMETER_ORGANIZATION_URN_VALUE;

    userFamilyName.Name           = MERCATO_SP_PARAMETER_USER_FAMILY_NAME;
    userFamilyName.Value__c       = MERCATO_SP_PARAMETER_USER_FAMILY_NAME_VALUE;

    userGivenName.Name            = MERCATO_SP_PARAMETER_USER_GIVEN_NAME;
    userGivenName.Value__c        = MERCATO_SP_PARAMETER_USER_GIVEN_NAME_VALUE; 

    userEmail.Name                = MERCATO_SP_PARAMETER_EMAIL_ADDRESS;
    userEmail.Value__c            = MERCATO_SP_PARAMETER_EMAIL_ADDRESS_VALUE;

    listOfSSOCustomSettings.add(userActiveFlag);
    listOfSSOCustomSettings.add(userLastUpdatedDate);
    listOfSSOCustomSettings.add(organizationName);
    listOfSSOCustomSettings.add(organizationURN);
    listOfSSOCustomSettings.add(userFamilyName);
    listOfSSOCustomSettings.add(userGivenName);   
    listOfSSOCustomSettings.add(userEmail);                   

    insert listOfSSOCustomSettings;   

    
   }  
    // Create the internal CCS Account to refer to
    static void createCSSAccount(){
   
    Account ccsInternalAccount  = new Account();
    ccsInternalAccount.Name = INTERNAL_ACCOUNT_NAME;
    insert ccsInternalAccount;

    Org_Settings__c orgSettings = new Org_Settings__c();
    orgSettings.Internal_Account_Id__c = ccsInternalAccount.Id;
    insert orgSettings;
    }
    

  
  @isTest 
  static void testCustomAttributes() {

    // Create the community user as part of a runAs in order to avoid mixed DML error
      System.runAs(UnitTestDataFactory.createUserSystemAdmin(ADMINISTRATOR_PROFILE)) {
      List<UserRole> InternalRoles   = [SELECT Id FROM UserRole WHERE PortalRole = null ]; // account owner must have a role (any one) for community activity, so setting just in case and for future tests
      List<String> roleIds = new List<String>();
         for (UserRole ur : InternalRoles)
         {
             roleIds.add(ur.Id);
         }
          
      User accountOwnerUser   = [SELECT Id FROM User WHERE isActive = true AND UserRoleId in :roleIds LIMIT 1];

    // Create an account for the community user. Note that the account owner MUST have a role  
      String testAccountName  = 'Test Account ' + UnitTestDataFactory.getRandomString(8);
      Account testAcc = UnitTestDataFactory.createSupplierAccount(testAccountName);
      testAcc.OwnerId = accountOwnerUser.Id;
      insert testAcc;

    // Create the community contact
      Contact communityContact = UnitTestDataFactory.createContact(testAcc.Id); 
      insert communityContact;     
   
      
      User communityUser = UnitTestDataFactory.createUserSystemAdmin('CCS Customer Community Plus Login User SSO Only');
      communityUser.ContactId = communityContact.Id;
      insert communityUser;  

      Map<String, String> inputAttributes  = new Map<String, String>();
      inputAttributes.put('userFamilyName','MERCATO_SP_PARAMETER_USER_FAMILY_NAME');
      Map<String, String> outputAttributes = new Map<String, String>();
          
      Account ccsInternalAccount  = new Account();
      ccsInternalAccount.Name = INTERNAL_ACCOUNT_NAME;
      insert ccsInternalAccount;

      Org_Settings__c orgSettings1 = new Org_Settings__c();
      orgSettings1.Internal_Account_Id__c = ccsInternalAccount.Id;
      insert orgSettings1;
      

      Org_Settings__c orgSettings = Org_Settings__c.getOrgDefaults();

      ConnectedApplication testConnectedApp = [SELECT Id FROM ConnectedApplication LIMIT 1];  
    

      Account intAccount = [SELECT Id, Name, Account_URN__c FROM Account WHERE Id = :orgSettings.Internal_Account_Id__c]; 
      Id internalAccId = orgSettings.Internal_Account_Id__c;
      String internalAccountQuery = 'SELECT Id, Name, Account_URN__c FROM Account WHERE Id = :internalAccId';   
      List<Account> internalAccountList = Database.query(internalAccountQuery);
      Account internalAccount=null;
        if(internalAccountList.size()>0)
           {
               internalAccount = internalAccountList.get(0);
           }
      

        test.startTest();   

        MercatoParameterHandler mercatoAttributes = new MercatoParameterHandler();  

        // test outputs for internal user
        outputAttributes = mercatoAttributes.customAttributes(accountOwnerUser.Id, testConnectedApp.Id,inputAttributes, null);
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ACTIVE_FLAG_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_LAST_UPDATED_DATE_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ORGANIZATION_NAME_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ORGANIZATION_URN_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_USER_FAMILY_NAME_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_USER_GIVEN_NAME_VALUE));  
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_EMAIL_ADDRESS_VALUE)); 
        System.assertEquals(internalAccount.get('Account_URN__c'), outputAttributes.get(MERCATO_SP_PARAMETER_ORGANIZATION_URN_VALUE));


        // test outputs for community user
        outputAttributes = mercatoAttributes.customAttributes(communityUser.Id, testConnectedApp.Id, inputAttributes, null); 
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ACTIVE_FLAG_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_LAST_UPDATED_DATE_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ORGANIZATION_NAME_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_ORGANIZATION_URN_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_USER_FAMILY_NAME_VALUE));
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_USER_GIVEN_NAME_VALUE)); 
        System.assert(outputAttributes.containsKey(MERCATO_SP_PARAMETER_EMAIL_ADDRESS_VALUE));
        System.assertEquals(testAccountName, outputAttributes.get(MERCATO_SP_PARAMETER_ORGANIZATION_NAME_VALUE));
        test.stopTest();
    }
  }
}