// Garth James (Salesforce) - 14.10.2016 - Created.

/*****************************************************************************************
Name:  EmployeeGoogleRegistrationHandler_Test()
============================================================================================================
Purpose:                                                            
-------    
Test class for the EmployeeGoogleRegistrationHandler_Test class.

============================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR        DATE        DETAIL                      DESCRIPTION
1.0       Garth James   15/11/2016  INITIAL DEVELOPMENT         Created 
********************************************************************************************/

@isTest (seeAllData=false)
public class EmployeeGoogleRegistrationHandler_Test {

  static String PROVISIONER_PROFILE                 = 'System Administrator';
  static String STANDARD_PROFILE                    = 'Standard User';
  static String AUTH_PROVIDER                       = 'Google';  

  static String ALLOWED_DOMAINS                     = 'EMPLOYEE_IDP_ALLOWED_DOMAINS_LIST';
  static String OPENID_UID_ATTRIBUTE_NAME           = 'EMPLOYEE_IDP_PARAMETER_UID';
  static String OPENID_DOMAIN_ATTRIBUTE_NAME        = 'EMPLOYEE_IDP_PARAMETER_HOSTED_DOMAIN';

  static String ALLOWED_DOMAINS_VALUE               = 'crowncommercial.gov.uk';      
  static String OPENID_UID_ATTRIBUTE_NAME_VALUE     = 'sub';
  static String OPENID_DOMAIN_ATTRIBUTE_NAME_VALUE  = 'hd';

  static String SSO_CUSTOM_SETTING_OBJECT_NAME      = 'OpenID SSO Settings';  

  @testSetup
  static void createGlobalTestData() {

    Openid_SSO_Settings__c allowedDomainList = new Openid_SSO_Settings__c();

    allowedDomainList.Name     = ALLOWED_DOMAINS;
    allowedDomainList.Value__c = ALLOWED_DOMAINS_VALUE;

    insert allowedDomainList;

    Openid_SSO_Settings__c openIdDomainParameter = new Openid_SSO_Settings__c();

    openIdDomainParameter.Name     = OPENID_DOMAIN_ATTRIBUTE_NAME;
    openIdDomainParameter.Value__c = OPENID_DOMAIN_ATTRIBUTE_NAME_VALUE;

    insert openIdDomainParameter;

    Openid_SSO_Settings__c openIdUIDParameter = new Openid_SSO_Settings__c();

    openIdUIDParameter.Name     = OPENID_UID_ATTRIBUTE_NAME;
    openIdUIDParameter.Value__c = OPENID_UID_ATTRIBUTE_NAME_VALUE;

    insert openIdUIDParameter;        

  }

  /*******************************************************************
  Purpose:  Creates Auth.UserData object for the test - the attributes used here will also be used to seed 
            other parts of the test
  ********************************************************************/ 
  static Auth.UserData createEmployeeData() {

    String firstName = 'First_' + UnitTestDataFactory.getRandomString(8);
    String lastName  = 'Last_'  + UnitTestDataFactory.getRandomString(8);

    Map<String, String> attributeMap = new Map<String, String>();

    attributeMap.put(OPENID_DOMAIN_ATTRIBUTE_NAME_VALUE, ALLOWED_DOMAINS_VALUE); // mapping is correct - we're putting the value from the domain to test against into the 'hd' mapping
    attributeMap.put(OPENID_UID_ATTRIBUTE_NAME_VALUE, UnitTestDataFactory.getRandomString(12));   

    // create the data the provisioner will receive as part of the OpenID 'call'
    Auth.UserData employeeData = new Auth.UserData(
                null,
                firstName,
                lastName,
                firstName + ' ' + lastName,
                UnitTestDataFactory.getRandomEmailAddress(firstName, lastName),
                UnitTestDataFactory.getRandomString(21), 
                null,
                'en', 
                AUTH_PROVIDER,
                null,
                attributeMap
    );

    return employeeData;

  }
  

  /*******************************************************************
  Purpose:  Test the createUser() method
  ********************************************************************/   	
	@isTest 
  static void callCreateUser() {

    // create the Auth Data
    Auth.UserData employeeAuthData    = createEmployeeData();


    // create the user (i.e. the employee) the provisioner will attempt to login as
    User employeeUser                 = UnitTestDataFactory.createUserSystemAdmin(STANDARD_PROFILE);

    employeeUser.email                = employeeAuthData.email;
    employeeUser.firstName            = employeeAuthData.firstName;
    employeeUser.lastName             = employeeAuthData.lastName;
    employeeUser.userName             = employeeAuthData.email;
    employeeUser.federationIdentifier = employeeAuthData.email;

    insert employeeUser;


    // create the user that will actually execute the provisioner (i.e. the 'execute class as: user')
    User provisionerUser              = UnitTestDataFactory.createUserSystemAdmin(PROVISIONER_PROFILE);

    insert provisionerUser;

    Boolean errorOccurred             = false;

		EmployeeGoogleRegistrationHandler googleHandler = new EmployeeGoogleRegistrationHandler();

    test.startTest(); 
    System.runAs(provisionerUser) {

      // test user is found
      User matchTestUser        = googleHandler.createUser(null, employeeAuthData);
      System.assertEquals(employeeUser.Id, matchTestUser.Id);

      // test user not found
      errorOccurred = false;
      try {
        employeeAuthData.email  = 'broken_' + employeeUser.email;
        User mismatchTestUser   = googleHandler.createUser(null, employeeAuthData);
      } catch (Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.Employee_SSO_UserNotFound, new List<String> {String.valueOf(employeeAuthData.email)}), e.getMessage());
      }
      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!'); 

      // test invalid domain
      errorOccurred = false;
      try {
        // change the 'hd' parameter
        employeeAuthData.attributeMap.put(OPENID_DOMAIN_ATTRIBUTE_NAME_VALUE, 'broken_' + ALLOWED_DOMAINS_VALUE);
        User notAllowedUser = googleHandler.createUser(null, employeeAuthData);
      } catch(Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.Employee_SSO_DomainNotAuthorised, new List<String> {String.valueOf(employeeAuthData.email)}), e.getMessage());
      }
      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!');      

    }
    test.stopTest();
	}


  /*******************************************************************
  Purpose:  Test the updateUser() method
  ********************************************************************/     	
	@isTest 
  static void callUpdateUser() {

    Auth.UserData employeeAuthData    = createEmployeeData();

    // create the user (i.e. the employee) the provisioner will attempt to login as
    User employeeUser                 = UnitTestDataFactory.createUserSystemAdmin(STANDARD_PROFILE);

    employeeUser.email                = employeeAuthData.email;
    employeeUser.firstName            = employeeAuthData.firstName;
    employeeUser.lastName             = employeeAuthData.lastName;
    employeeUser.userName             = employeeAuthData.email;
    employeeUser.federationIdentifier = employeeAuthData.email;

    insert employeeUser;

    String updatedUserLastName        = 'NewLast_' + UnitTestDataFactory.getRandomString(8); // the update call should make apply this change

    // create the user that will actually execute the provisioner (i.e. the 'execute class as: user')
    User provisionerUser              = UnitTestDataFactory.createUserSystemAdmin(PROVISIONER_PROFILE);

    insert provisionerUser;    

    EmployeeGoogleRegistrationHandler googleHandler = new EmployeeGoogleRegistrationHandler();

    test.startTest(); 
    System.runAs(provisionerUser) {

      // assert that 'before' state doesn't match the updated name   
      System.assertNotEquals(updatedUserLastName, employeeUser.lastName);

      employeeAuthData.lastName = updatedUserLastName;

      // call the update
      googleHandler.updateUser(employeeUser.Id, null, employeeAuthData);

      user resultTestUser = [SELECT lastName, federationIdentifier FROM User WHERE Id = :employeeUser.Id];
      
      // assert that the 'after' state does match the updated name
      System.assertEquals(updatedUserLastName, resultTestUser.lastName); 

      // test invalid domain
      Boolean errorOccurred = false;
      try {
          // change the 'hd' parameter
        employeeAuthData.attributeMap.put(OPENID_DOMAIN_ATTRIBUTE_NAME_VALUE, 'broken_' + ALLOWED_DOMAINS_VALUE);
        googleHandler.updateUser(employeeUser.Id, null, employeeAuthData);
      } catch(Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.Employee_SSO_DomainNotAuthorised, new List<String> {String.valueOf(employeeAuthData.email)}), e.getMessage());
      }
      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!');
    }
    test.stopTest();
	}

  /*******************************************************************
  Purpose:  Test the error handling
  ********************************************************************/    
  @isTest
  static void testValidation() {

    Auth.UserData employeeAuthData  = createEmployeeData();

    // create the user (i.e. the employee) the provisioner will attempt to login as
    User employeeUser               = UnitTestDataFactory.createUserSystemAdmin(STANDARD_PROFILE);
    insert employeeUser;

    // create the user that will actually execute the provisioner (i.e. the 'execute class as: user')
    User provisionerUser            = UnitTestDataFactory.createUserSystemAdmin(PROVISIONER_PROFILE);
    insert provisionerUser;  

    Boolean errorOccurred           = false;

    EmployeeGoogleRegistrationHandler googleHandler = new EmployeeGoogleRegistrationHandler();   

    test.startTest();
    System.runAs(provisionerUser) {  

      //Test for missing CCS_GOOGLE_ALLOWED_DOMAINS_LIST parameter
      //-------------------------------
      Openid_SSO_Settings__c allowedDomainList = [SELECT Name, Value__c FROM Openid_SSO_Settings__c WHERE NAME = :ALLOWED_DOMAINS];

      // break the allowed domain attribute
      allowedDomainList.Name     = 'x' + ALLOWED_DOMAINS;
      update allowedDomainList;

      // call the handler with the broken attribute
      errorOccurred = false;
      try {
        googleHandler.updateUser(employeeUser.Id, null, employeeAuthData);
      } catch(Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.OpenID_SSO_CustomSettingNotDefined, new List<String> {SSO_CUSTOM_SETTING_OBJECT_NAME + ': ' + ALLOWED_DOMAINS}), e.getMessage());
      }      
      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!');

      // fix the allowed domain attribute
      allowedDomainList.Name     = ALLOWED_DOMAINS;
      update allowedDomainList;      

      //Test for missing CCS_GOOGLE_PARAMETER_HOSTED_DOMAIN parameter
      //-------------------------------
      Openid_SSO_Settings__c openIdDomainParameter = [SELECT Name, Value__c FROM Openid_SSO_Settings__c WHERE NAME = :OPENID_DOMAIN_ATTRIBUTE_NAME];

      // break the hosted domain attribute
      openIdDomainParameter.Name     = 'x' + OPENID_DOMAIN_ATTRIBUTE_NAME;

      update openIdDomainParameter;

      // call the handler to test missing domain attribute
      errorOccurred = false;
      try {
        googleHandler.updateUser(employeeUser.Id, null, employeeAuthData);
      } catch(Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.OpenID_SSO_CustomSettingNotDefined, new List<String> {SSO_CUSTOM_SETTING_OBJECT_NAME + ': ' + OPENID_DOMAIN_ATTRIBUTE_NAME}), e.getMessage());
      } 

      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!');

      // fix the domain attribute for the next test
      openIdDomainParameter.Name     = OPENID_DOMAIN_ATTRIBUTE_NAME;
      update openIdDomainParameter;             

      //Test for missing CCS_GOOGLE_PARAMETER_HOSTED_DOMAIN parameter
      //-------------------------------
      List<Openid_SSO_Settings__c> openIdSSOSettingsToDelete = [SELECT Id FROM Openid_SSO_Settings__c];
      delete openIdSSOSettingsToDelete;
      

      // call the handler to test missing domain attribute
      errorOccurred = false;
      try {
        googleHandler.updateUser(employeeUser.Id, null, employeeAuthData);
      } catch(Exception e) {
        errorOccurred = true;
        System.assertEquals(String.format(Label.OpenID_SSO_CustomSettingNotDefined, new List<String> {SSO_CUSTOM_SETTING_OBJECT_NAME}), e.getMessage());
      } 

      // if error didn't happen, then fail the test
      System.assert(errorOccurred, 'Expected error has not occurred!');      
    }
    test.stopTest();
  }
	
}