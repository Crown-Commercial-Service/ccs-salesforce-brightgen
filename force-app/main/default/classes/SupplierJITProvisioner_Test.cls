// Garth James (Salesforce) - 14.10.2016 - Created.

/*****************************************************************************************
Name:  SupplierJITProvisioner_Test()
============================================================================================================
Purpose:                                                            
-------    
Test class for the SupplierJITProvisioner class.

============================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR        DATE        DETAIL                      DESCRIPTION
1.0       Garth James   24/10/2016  INITIAL DEVELOPMENT         Created 
1.1		  Jim MacAulay	27/07/2017	Altered Owner Profile Name since old profile deleted
********************************************************************************************/

@isTest (seeAllData=false)
public class SupplierJITProvisioner_Test {

    // constants
    static String SSO_CONFIG_NAME           = 'SID4GOV';
    static String ACCOUNT_OWNER_ROLE        = 'JIT Supplier Account Owner';
    static String ACCOUNT_OWNER_PROFILE     = 'CCS Digital Services User';
    static String PROVISIONER_PROFILE       = 'CCS System Administrator'; //'CCS JIT User Provisioner';
    static String PORTAL_USER_PROFILE       = 'CCS Customer Community Plus Login User SSO Only';
    static String LOGIN_DOMAIN_SUFFIX       = 'crowncommercial.gov.ssodev';
    static String PROVISIONER_USERNAME      = 'JIT.Provisioner@' + LOGIN_DOMAIN_SUFFIX;
    static String ACCOUNT_OWNER_USERNAME    = 'Account.Owner@' + LOGIN_DOMAIN_SUFFIX;
    static String NEW_ACCOUNT_RECORD_TYPE   = 'Supplier';
    static String FEDERATION_ID_ATTRIBUTE   = 'user_email';
    static String CONTACT_ORIGIN            = 'Community';

    static Id     ssoSAMLConfigId           = [SELECT Id FROM SamlSsoConfig WHERE DeveloperName  = :SSO_CONFIG_NAME][0].Id;
    static String domainSuffix              = LOGIN_DOMAIN_SUFFIX; 
    static Id     ssoCommunityId            = '00eb0000000EfZw';  // UserInfo.getProfileId()doesn't matter which ID is used (for the test) - just needs to be populated with an ID    
 
    @testSetup 
    static void createGlobalTestData() {

        Profile accountOwnerProfile     = [SELECT Id FROM Profile WHERE Name = :ACCOUNT_OWNER_PROFILE];
        Profile provisionerProfile      = [SELECT Id FROM Profile WHERE Name = :PROVISIONER_PROFILE];

        UserRole accountOwnerRole       = [SELECT Id FROM UserRole WHERE Name = :ACCOUNT_OWNER_ROLE];

        User accountOwnerUser = new User(); // When the provisioner creates a new account and contact, this will be the user that set as the owner of those records

        accountOwnerUser.FirstName          = 'Account' + UnitTestDataFactory.getRandomString(8);
        accountOwnerUser.LastName           = 'Owner' + UnitTestDataFactory.getRandomString(8);
        accountOwnerUser.Email              = ACCOUNT_OWNER_USERNAME;
        accountOwnerUser.Username           = ACCOUNT_OWNER_USERNAME;
        accountOwnerUser.Alias              = 'Acc' + UnitTestDataFactory.getRandomString(5);
        accountOwnerUser.CommunityNickname  = 'Acc' + UnitTestDataFactory.getRandomString(5);
        accountOwnerUser.ProfileId          = accountOwnerProfile.Id;
        accountOwnerUser.UserRoleId         = accountOwnerRole.Id;
        accountOwnerUser.TimeZoneSidKey     = 'America/Denver';
        accountOwnerUser.LocaleSidKey       = 'en_US';
        accountOwnerUser.EmailEncodingKey   = 'UTF-8';
        accountOwnerUser.LanguageLocaleKey  = 'en_US';

        insert accountOwnerUser;

        User provisionerUser = new User(); // This is the actual user that will run the provisioner class - the equivalent of the 'run as' user in the SamlSsoConfig record

        provisionerUser.FirstName           = 'JIT' + UnitTestDataFactory.getRandomString(8);
        provisionerUser.LastName            = 'Provisioner' + UnitTestDataFactory.getRandomString(8);
        provisionerUser.Email               = PROVISIONER_USERNAME;
        provisionerUser.Username            = PROVISIONER_USERNAME;
        provisionerUser.Alias               = 'JIT' + UnitTestDataFactory.getRandomString(5);
        provisionerUser.CommunityNickname   = 'JIT' + UnitTestDataFactory.getRandomString(5);       
        provisionerUser.ProfileId           = provisionerProfile.Id;
        provisionerUser.UserRoleId          = accountOwnerRole.Id;
        provisionerUser.TimeZoneSidKey      = 'America/Denver';
        provisionerUser.LocaleSidKey        = 'en_US';
        provisionerUser.EmailEncodingKey    = 'UTF-8';
        provisionerUser.LanguageLocaleKey   = 'en_US';

        insert provisionerUser;

        System.runas(accountOwnerUser){

            SAML_SSO_Settings__c accountOwnerUserName    = new SAML_SSO_Settings__c(); 
            SAML_SSO_Settings__c domainSuffux            = new SAML_SSO_Settings__c();
            SAML_SSO_Settings__c profileForCreatedUsers  = new SAML_SSO_Settings__c();
            SAML_SSO_Settings__c accountRecordType       = new SAML_SSO_Settings__c();
            SAML_SSO_Settings__c contactOrigin           = new SAML_SSO_Settings__c();

            accountOwnerUserName.Name       = 'SID4GOV_NEW_ACCOUNT_OWNER_USERNAME';
            accountOwnerUserName.Value__c   = accountOwnerUser.Username;
            accountRecordType.Name          = 'SID4GOV_NEW_ACCOUNT_RECORD_TYPE';
            accountRecordType.Value__c      = NEW_ACCOUNT_RECORD_TYPE;            
            profileForCreatedUsers.Name     = 'SID4GOV_NEW_USER_PROFILE_NAME';
            profileForCreatedUsers.Value__c = PORTAL_USER_PROFILE;
            domainSuffux.Name               = 'SID4GOV_NEW_USER_LOGIN_DOMAIN_SUFFIX';
            domainSuffux.Value__c           = LOGIN_DOMAIN_SUFFIX;
            contactOrigin.Name              = 'SID4GOV_NEW_CONTACT_ORIGIN';
            contactOrigin.Value__c          = CONTACT_ORIGIN;         

            insert accountOwnerUserName; 
            insert accountRecordType;
            insert domainSuffux;
            insert profileForCreatedUsers;
            insert contactOrigin;
        }     
    }
    
// start with the tests
  

/****************************************************************************        
** Test scenario for internal users only - NO PORTAL 
** ...no account or contact expected
****************************************************************************/  
    
    @isTest
    static void testNewInternalUser() {

        //insert supplierSetting; // custom settings created as a static variable above

        SupplierJITProvisioner jitp     = new SupplierJITProvisioner();
        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = null;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];

        // Start Test
        test.startTest();

        System.runAs(provisionerUser) {
        
            User u = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);

            //Test Assertions
            String  testUserName    = attributes.get('user_email').substringBefore('@') + '@' + LOGIN_DOMAIN_SUFFIX;

            System.assertEquals(testUserName, u.UserName);

        }

        // Stop Test
        test.stopTest();         
    }    
    
    
    

/****************************************************************************        
** Test scenario where Account and Contact do not exist
** ...so, create new Account and Contact when provisioning user. 
****************************************************************************/  
    
    @isTest
    static void testNewAccountNewContactNewCommunityUser() {

        //insert supplierSetting; // custom settings created as a static variable above
    
        SupplierJITProvisioner jitp     = new SupplierJITProvisioner();
        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?

        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];
        
        // Start Test
        test.startTest();

        System.runAs(provisionerUser) {        

          User u = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);

          // Collect results
          Contact c = [SELECT LastName, FirstName, Account.Name, Account.DUNS_Number__c, Origin__c FROM Contact WHERE Id = :u.ContactId];
          
          //Test Assertions
          String  testUserName    = attributes.get('user_email').substringBefore('@') + '@' + LOGIN_DOMAIN_SUFFIX;
          Decimal testDunsNumber  = Decimal.valueOf(attributes.get('organisation_duns_number'));

          System.assertEquals(testUserName                        , u.UserName);
          System.assertEquals(attributes.get('user_last_name')    , c.LastName);
          System.assertEquals(attributes.get('organisation_name') , c.Account.Name);
          System.assertEquals(testDunsNumber                      , c.Account.DUNS_Number__c);
          System.assertEquals(CONTACT_ORIGIN                      , c.Origin__c);

        }
        // Stop Test
        test.stopTest();         
    }


 
/****************************************************************************         
** Test scenario where Account and Contact already exist
** ...so, DO NOT create new Account or Contact when provisioning user.
** ...also, test call to updateUser method
****************************************************************************/ 
        
    @isTest
    static void testExistingAccountExistingContactNewCommunityUser() {

        //insert supplierSetting; // custom settings created as a static variable above

        SupplierJITProvisioner jitp     = new SupplierJITProvisioner();
        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;

        // Set up test data
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];

        test.startTest();       
        
        System.runAs(provisionerUser) { 

          // create 'existing' account
          Account a = createAccountFromAttributes(attributes);
          
          // create 'existing' contacts
          Contact c1 = createContactFromAttributes(attributes);
          Contact c2 = createContactFromAttributes(attributes);

          // create the account 
          insert a;        
          c1.AccountId  = a.Id;
          c2.AccountId  = a.Id;
          c2.Email      = c1.Email; //c2 will be a duplicate when created

          
          // create the contact - only insert c1 for first test. C2 comes later     
          insert c1; 

          Integer numberOfContactsBefore  = [SELECT count() FROM Contact];
          Integer numberOfAccountsBefore  = [SELECT count() FROM Account];             
          
          // test createUser method
          User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
  
          insert userToTest;            
          
          // Collect results
          Contact contactToTest           = [SELECT LastName, FirstName, Account.Name, Account.DUNS_Number__c FROM Contact WHERE Id = :userToTest.ContactId];
          Integer numberOfContactsAfter   = [SELECT count() FROM Contact];
          Integer numberOfAccountsAfter   = [SELECT count() FROM Account];
          
          //Test Assertions
          String  testUserName    = attributes.get('user_email').substringBefore('@') + '@' + LOGIN_DOMAIN_SUFFIX;
          Decimal testDunsNumber  = Decimal.valueOf(attributes.get('organisation_duns_number'));

          System.assertEquals(testUserName                        , userToTest.UserName);
          System.assertEquals(attributes.get('user_last_name')    , contactToTest.LastName);
          System.assertEquals(attributes.get('organisation_name') , contactToTest.Account.Name);
          System.assertEquals(testDunsNumber                      , contactToTest.Account.DUNS_Number__c);
          
          // Ensure no new account or contact was created (i.e. it matched the ones created before the test)
          System.assertEquals(numberOfContactsBefore, numberOfContactsAfter);
          System.assertEquals(numberOfAccountsBefore, numberOfAccountsAfter); 

          // alter the attributes for the updateUser test
          attributes.put('user_last_name' ,'Reinberg');   // was Steinberg
          attributes.put('user_first_name','Vance');      // was Lance
          
          // test updateUser method
          jitp.updateUser(userToTest.Id, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);

          User userToTest2 = [SELECT FirstName, LastName FROM User WHERE Id = :userToTest.Id];
          System.assertEquals(attributes.get('user_first_name') , userToTest2.FirstName);
          System.assertEquals(attributes.get('user_last_name')  , userToTest2.LastName);

          // test duplicate contacts (doesn't matter if updateUser or createUser - will use updateUser in this case)

          insert c2; // insert the duplicate contact (duplicate of c1 by email address)

          try {
            jitp.updateUser(userToTest.Id, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
          } catch (Exception e) {
            errorOccurred = true;
            System.assertEquals(String.format(Label.SSO_TooManyContactsMatchedByEmail_ui, new List<String> {String.valueOf(attributes.get('user_email'))}), e.getMessage());
          }

          // if error didn't happen, then fail the test
          System.assert(errorOccurred, 'Expected error has not occurred!'); 

          // test no contact matched by email

          c1.Email = c1.Email + '.broken'; // break email addresses so they can't be matched
          c2.Email = c2.Email + '.broken2'; // break email addresses
          
          update c1;
          update c2; 

          // must use updateUser to get this error
          try {
            jitp.updateUser(userToTest.Id, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
          } catch (Exception e) {
            errorOccurred = true;
            System.assertEquals(String.format(Label.SSO_ExistingContactNotMatchedByEmail_ui, new List<String> {String.valueOf(attributes.get('user_email'))}), e.getMessage());
          }

          // if error didn't happen, then fail the test
          System.assert(errorOccurred, 'Expected error has not occurred!'); 

          // finally - test for DUNS mismatch

          c1.Email = attributes.get('user_email'); // fix email addresses

          update c1;

          attributes.put('organisation_duns_number' ,UnitTestDataFactory.getRandomString(8)); // change DUNS Number

          // must use updateUser to get this error
          try {
            jitp.updateUser(userToTest.Id, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
          } catch (Exception e) {
            errorOccurred = true;
            System.assertEquals(String.format(Label.SSO_ExistingAccountNotMatchedByDUNSNumber_ui, new List<String> {String.valueOf(attributes.get('organisation_duns_number'))}), e.getMessage());
          }

          // if error didn't happen, then fail the test
          System.assert(errorOccurred, 'Expected error has not occurred!');           

 
        }  // runAs
        
        test.stopTest(); 
    }


/****************************************************************************        
** Test Validation Handling 
****************************************************************************/

    @isTest
    static void testErrors() {

        //insert supplierSetting; // custom settings created as a static variable above

        SupplierJITProvisioner jitp     = new SupplierJITProvisioner();
        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?

        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) { 
            // Start Test        
            test.startTest();

            Boolean errorOccurred = false;
            
            // check email null

            errorOccurred = false;

            attributes.put('user_email',null);
            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_UserEmailNull_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');            
            
            // check email not present

            errorOccurred = false;

            attributes.remove('user_email');
            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_UserEmailNotSupplied_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');               
            
            attributes.put('user_email','lsteinberg@ccs.sso.test');

            // check duns_number null

            errorOccurred = false;

            attributes.put('organisation_duns_number',null);
            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_DUNSNumberNull_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');   

            // check duns number = 0
            attributes.put('organisation_duns_number','00000');
            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_DUNSNumberNull_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');                         
            
            // check duns_number not present
            attributes.remove('organisation_duns_number');
            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_DUNSNumberNotSupplied_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');               
            
            attributes.put('organisation_duns_number','123456789012');

            // check FederationIdentifier null (note null passed into call)

            errorOccurred = false;

            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, null, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_FederationIdentifierNull_ui, e.getMessage());
            }
            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');                   

            test.stopTest();  
        }
    }

/****************************************************************************         
** Test scenario where the Custom SEtting desribing the user profile is null
****************************************************************************/ 

    @isTest 
    static void testSupplierCustomSettingNull() {

        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;

        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) {    
            // Start Test        
            test.startTest();

            // set the custom setting value to null
            SAML_SSO_Settings__c profileForCreatedUsers = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_USER_PROFILE_NAME');  
            profileForCreatedUsers.Value__c             = null;     
            update profileForCreatedUsers;    

            // now instantiate the class, as Custom Settings in question are defined as static
            SupplierJITProvisioner jitp                 = new SupplierJITProvisioner();         

            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_SupplierProfileNotDefined_ui, e.getMessage());
            }

            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');               

            test.stopTest();  
        }
    }

/****************************************************************************         
** Test scenario where user profile described cannot be found
****************************************************************************/ 

    @isTest 
    static void testSupplierCustomSettingNotFound() {

        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;
  
        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) { 
          test.startTest();

          // break the profile to search for
          SAML_SSO_Settings__c profileForCreatedUsers   = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_USER_PROFILE_NAME');  
          profileForCreatedUsers.Value__c               = profileForCreatedUsers.Value__c + '_Broken';     
          update profileForCreatedUsers;         

          // now instantiate the class, as Custom Settings in question are defined as static
          SupplierJITProvisioner jitp                   = new SupplierJITProvisioner();    

          try {
              User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
          } catch (Exception e) {
              errorOccurred = true;
              System.assertEquals(String.format(Label.SSO_NoSupplierProfile_ui, new List<String>{String.valueOf(profileForCreatedUsers.Value__c)}), e.getMessage());
          }

          // if error didn't happen, then fail the test
          System.assert(errorOccurred, 'Expected error has not occurred!');                  

          test.stopTest();  
        }
    }        

/****************************************************************************         
** Test scenario where the Custom SEtting desribing the account owner is null
****************************************************************************/ 

    @isTest 
    static void testAccountOwnerCustomSettingNull() {

        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;

        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) {    
            // Start Test        
            test.startTest();

            // set the custom setting value to null
            SAML_SSO_Settings__c accountOwnerUserName = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_ACCOUNT_OWNER_USERNAME');  
            accountOwnerUserName.Value__c             = null;     
            update accountOwnerUserName;    

            // now instantiate the class, as Custom Settings in question are defined as static
            SupplierJITProvisioner jitp                 = new SupplierJITProvisioner();         

            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_SupplierAccountOwnerNotDefined_ui, e.getMessage());
            }

            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');               

            test.stopTest();  
        }
    }

/****************************************************************************         
** Test scenario where account owner described cannot be found
****************************************************************************/ 

    @isTest 
    static void testAccountOwnerCustomSettingNotFound() {

        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;
  
        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) { 
          test.startTest();

          // break the profile to search for
          SAML_SSO_Settings__c accountOwnerUserName   = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_ACCOUNT_OWNER_USERNAME');  
          accountOwnerUserName.Value__c               = accountOwnerUserName.Value__c + '_Broken';     
          update accountOwnerUserName;         

          // now instantiate the class, as Custom Settings in question are defined as static
          SupplierJITProvisioner jitp                   = new SupplierJITProvisioner();    

          try {
              User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
          } catch (Exception e) {
              errorOccurred = true;
              System.assertEquals(String.format(Label.SSO_NoAccountOwner_ui, new List<String>{String.valueOf(accountOwnerUserName.Value__c)}), e.getMessage());
          }

          // if error didn't happen, then fail the test
          System.assert(errorOccurred, 'Expected error has not occurred!');                  

          test.stopTest();  
        }
    }

/****************************************************************************         
** Test scenario where the Custom SEtting desribing the email/userid domain is null
****************************************************************************/ 

    @isTest 
    static void testLoginDomainSuffixCustomSettingNull() {

        Id samlSsoProviderId            = ssoSAMLConfigId;
        Id communityId                  = ssoCommunityId;
        Id portalId                     = null;
        Map<String, String> attributes  = createInitialSAMLAttributeSet();
        String federationIdentifier     = attributes.get(FEDERATION_ID_ATTRIBUTE);
        String rawAssertion             = null; // meant to be base64 encoded SAML assertion, doesn't seem necessary for test?
        Boolean errorOccurred           = false;

        // get the provisioner user
        User provisionerUser = [SELECT Id FROM User WHERE Username = :PROVISIONER_USERNAME];   
        
        System.runAs(provisionerUser) {    
            // Start Test        
            test.startTest();

            // set the custom setting value to null
            SAML_SSO_Settings__c domainSuffux = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_USER_LOGIN_DOMAIN_SUFFIX');  
            domainSuffux.Value__c             = null;     
            update domainSuffux;    

            // now instantiate the class, as Custom Settings in question are defined as static
            SupplierJITProvisioner jitp       = new SupplierJITProvisioner();         

            try {
                User userToTest = jitp.createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, rawAssertion);
            } catch (Exception e) {
                errorOccurred = true;
                System.assertEquals(Label.SSO_NoDomainSuffix_ui, e.getMessage());
            }

            // if error didn't happen, then fail the test
            System.assert(errorOccurred, 'Expected error has not occurred!');               

            test.stopTest();  
        }
    }


    /****************************************************************************     
    ** Start: Data setup methods for SupplierJITProvisioner_Test   
    ****************************************************************************/ 

    
    static Map<String, String> createInitialSAMLAttributeSet() {
        
        Map<String, String> attributeSet = new Map<String, String>();
        
        attributeSet.put('user_login'               ,'lsteinberg@ccs.sso.test');
        attributeSet.put('user_unique_id'           ,'1111111111');
        attributeSet.put('user_email'               ,'lsteinberg@ccs.sso.test');    
        attributeSet.put('user_last_name'           ,'Steinberg');
        attributeSet.put('user_first_name'          ,'Lance');
        attributeSet.put('user_position'            ,'VAMP Driver');
        attributeSet.put('user_title'               ,'Mr');
        attributeSet.put('organisation_name'        ,'G.I. Joe');
        attributeSet.put('user_telephone'           ,'01919 312 451');
        attributeSet.put('user_mobile'              ,'03423 443 213');  
        attributeSet.put('user_extension'           ,'');
        attributeSet.put('organisation_duns_number' ,'123456789');
        attributeSet.put('organisation_unique_id'   ,'123456789012');
        
        return attributeSet;
    }
    
    static Contact createContactFromAttributes(Map<String, String> attributeSet) {
        Contact c                 = UnitTestDataFactory.createContact();
        c.Email                   = attributeSet.get('user_email');
        c.FirstName               = attributeSet.get('user_first_name');
        c.LastName                = attributeSet.get('user_last_name');
        c.Title                   = attributeSet.get('user_position');
        
        return c;
    }

    
    static Account createAccountFromAttributes(Map<String, String> attributeSet) {
        Account a                 = UnitTestDataFactory.createSupplierAccount(attributeSet.get('organisation_name'));       
        a.DUNS_Number__c          = Decimal.valueOf(attributeSet.get('organisation_duns_number'));
        
        return a;
    }
    
}