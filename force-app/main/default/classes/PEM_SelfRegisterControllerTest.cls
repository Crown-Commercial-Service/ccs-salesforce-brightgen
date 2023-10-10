/*********************************************************************
Name:  PEM_SelfRegisterControllerTest
Copyright © 2016  Salesforce
=====================================================================

Purpose: TEST class for PEM_SelfRegisterController
The Form handles three different registration processes.
1) Single recognised Domain (Create user and associate with Org found).
2) Multiple domain found (allow user to select which org they belong).
3) No domain found (Assign them to the default org and create the contact and case)

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
1.0    Simon Coles         2016-11-04       Initial version
1.1	   S O'Halloran		   2016-12-08       Removing (seeAllData)	
1.2    Sebastian Kubalski  2016-12-12       Added tests for PEM_SelfRegisterController.removeWhitespaces
*********************************************************************/

@IsTest 
public class PEM_SelfRegisterControllerTest {
    private static final String TEST_STRING_VALUE = ' asd asda a    asdasd asdsdsd   asdasdad';

    @IsTest
    private static void testRemoveWhitespaces(){
        Test.startTest();
        String result = PEM_SelfRegisterController.removeWhitespaces(TEST_STRING_VALUE);
        Test.stopTest();
        System.assert(result.containsNone(' '), 'Result doesn\'t contain any whitespaces');
    }

    @IsTest
    private static void testNullRemoveWhitespaces(){
        Test.startTest();
        String result = PEM_SelfRegisterController.removeWhitespaces(null);
        Test.stopTest();
        System.assertEquals(null, result, 'Result is null');
    }

    // Test to check if no firstname is entered.
    static testMethod void testBlankFirstname() {
        
        // Setup our Data
        String firstname = null;
        String lastname;
        String email;
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check firstname does not contain invalid characters.
    static testMethod void testFirstNameChars() {
        
        // Setup our Data
        String firstname = 'Simon11';
        String lastname;
        String email;
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check if no lastname is entered.
    static testMethod void testBlankLastname() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname;
        String email;
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check lastname does not contain invalid characters.
    static testMethod void testLastNameChars() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles11';
        String email;
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check email address is not blank
    static testMethod void testBlankEmail() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email;
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check email address is valid
    static testMethod void testValidEmail() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'simoncoles';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check email address is not a user already
    static testMethod void testEmailNotUsed() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'UnitTestUser@unittest.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        // Create a dummy user on object USER
        
        User u = UnitTestDataFactory.createUserMatchingEmailUsername('Standard User');
        insert u;
        List<User> UserNameList = new List<User>([SELECT Id from USER WHERE Username = :email]);
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check email address is blacklisted
    static testMethod void testEmailBlacklisted() {
        
        // Setup our Data
        String firstname = 'UserFirst';
        String lastname = 'UserLast';
        String email = 'user@blacklistme.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        insert new PEM_DomainBlackList__c(Name= 'blacklistme', Domain_Name__c = 'blacklistme.com');
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check phone number is not empty
    static testMethod void testContactNumberNotEmpty() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@hotmail.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = true;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test Phone number contains numbers only
    static testMethod void testContactNumberNotValid() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@hotmail.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber = '1234567689ASD';
        Boolean preValidated = true;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(0, pageResponse.ResponseCode);
    }
    
    // Test to check if Organization is email domain is found & Solid User
    static testMethod void testSingleDomainFound() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@singledomain.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        // Create an Org and Link it to the Email Domain
        Account a = new Account( Name = 'TestOrg' );
        insert a;
        // Create an Email Domain
        PEM_Email_Domain__c emailDomain = new PEM_Email_Domain__c( Email_Domain__c = 'singledomain.com' );
        insert emailDomain;
        // Link Org and Email Domain
        Account_Email_Domain__c emailAccDomain = new Account_Email_Domain__c ( Account__c = a.Id, Email_Domain__c = emailDomain.Id );
        insert emailAccDomain;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(null, pageResponse);  // Null means user was created
    }
    
    // Test to check if Organization is email domain is found multiple times
    static testMethod void testMultipleDomainsFound() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@multidomain.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        // Create an Org and Link it to the Email Domain
        Account acc1 = new Account( Name = 'TestOrg1' );
        insert acc1;
        // Create an Org and Link it to the Email Domain
        Account acc2 = new Account( Name = 'TestOrg2 UnitTest For PEM' );
        insert acc2;
        
        // Create an Email Domain
        PEM_Email_Domain__c emailDomain = new PEM_Email_Domain__c( Email_Domain__c = 'multidomain.com' );
        insert emailDomain;
        
        // Link Org and Email Domain
        Account_Email_Domain__c emailAccDomain1 = new Account_Email_Domain__c ( Account__c = acc1.Id, Email_Domain__c = emailDomain.Id );
        insert emailAccDomain1;
        Account_Email_Domain__c emailAccDomain2 = new Account_Email_Domain__c ( Account__c = acc2.Id, Email_Domain__c = emailDomain.Id );
        insert emailAccDomain2;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(1, pageResponse.ResponseCode);
    }
    
    // Test to check if Organization is email domain is found multiple times
    static testMethod void testMultipleDomainsNotFound() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@multidomain.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber;
        Boolean preValidated = false;
        String companyName;
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(2, pageResponse.ResponseCode);
    }
    
    // Test to check if Organization is email domain is found multiple times
    static testMethod void testCreateWithNoDomainFound() {
        
        // Setup our Data
        String firstname = 'Simon';
        String lastname = 'Coles';
        String email = 'spcoles@multidomain.com';
        String password;
        String confirmPassword;
        String accountId;
        String regConfirmUrl;
        String extraFields;
        String startUrl;
        Boolean includePassword;
        String contactNumber = '123456789';
        Boolean preValidated = true;
        String companyName = 'Salesforce';
        
        PEM_SelfRegisterController.responseWrapper pageResponse = PEM_SelfRegisterController.selfRegister(
            firstname, lastname, email, password, confirmPassword, accountId, regConfirmUrl, extraFields, startUrl, includePassword, contactNumber, preValidated, companyName
        );
        system.assertEquals(null, pageResponse);  // Null means user was created
    }
    
}