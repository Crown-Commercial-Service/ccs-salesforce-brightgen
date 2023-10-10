/*****************************************************************************************
Name:  SupplierJITProvisioner()
============================================================================================================
Purpose:                                                            
-------    
This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.

Handler has been customised from the default provisioner class created. I had initially planned to map the SAML attributes against 
the 'default' Salesforce expected SAML names, leaving the 'handle' methods largely untouched, but given the level of customisation and mapping, I didn't think the class would be 
re-usable for any other provisioning purpose, and ultimately decided against it. 
Therefore, the SAML assertion fields are mapped directly in the 'handle' methods.                                                         
============================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR      DATE    DETAIL                Description
1.0       Garth James   24/10/2016  INITIAL DEVELOPMENT   Created 
********************************************************************************************/


global class SupplierJITProvisioner implements Auth.SamlJitHandler {
  private class JitException extends Exception{}

  //static SSO_JIT_Provisioning_Settings__c supplierSettings = SSO_JIT_Provisioning_Settings__c.getValues('Supplier User Settings'); 

  static SAML_SSO_Settings__c accountOwnerUserName    = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_ACCOUNT_OWNER_USERNAME'); 
  static SAML_SSO_Settings__c domainSuffux            = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_USER_LOGIN_DOMAIN_SUFFIX'); 
  static SAML_SSO_Settings__c profileForCreatedUsers  = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_USER_PROFILE_NAME'); 
  static SAML_SSO_Settings__c accountRecordType       = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_ACCOUNT_RECORD_TYPE'); 
  static SAML_SSO_Settings__c contactOrigin           = SAML_SSO_Settings__c.getValues('SID4GOV_NEW_CONTACT_ORIGIN');



  /*******************************************************************
  Purpose:  This method gets the Supplier Profile Id using the Supplier_JIT_Provisioning_Setting__mdt metadata object. This will be the 
            profile used when this class creates a new community user.                                                        
  Parameters: None
  Returns: Profile Id
  Throws [Exceptions]: Label.SSO_SupplierProfileNotDefined_ui   
                       Label.SSO_NoSupplierProfile_ui                               
  ********************************************************************/  
  private Id getSupplierProfileId() {
      
    System.debug('Entry: getSupplierProfileId()');
          
    if(String.isEmpty(profileForCreatedUsers.Value__c)) {  
      throw new JitException(Label.SSO_SupplierProfileNotDefined_ui);    
    }
                  
    List<Profile> supplierProfiles = [SELECT Id FROM Profile WHERE Name = :profileForCreatedUsers.Value__c LIMIT 1];
    if(supplierProfiles.size() == 0) {
      throw new JitException(String.format(Label.SSO_NoSupplierProfile_ui, new List<String>{String.valueOf(profileForCreatedUsers.Value__c)}));    
    }
        
    Id supplierProfileId = supplierProfiles.get(0).Id;
        
    System.debug('Exit: getSupplierProfileId(). Returned supplierProfileId: ' + supplierProfileId);
    return supplierProfileId;
  } 



  /*******************************************************************
  Purpose:  This method gets the Contact Owner Id using the Supplier_JIT_Provisioning_Setting__mdt metadata object. This Id will be used
            as the owner of the contact this class creates. 

            Separate method (from getSupplierAccountOwnerId) for flexibility, although currently this is
            assumed to be the same, hence the call to getSupplierAccountOwnerId below.                                                        
  Parameters: None
  Returns: Contact Id
  Throws [Exceptions]: None                                                     
  ********************************************************************/     
  private static Id getSupplierContactOwnerId() {

    System.debug('Entry: getSupplierContactOwnerId()');
    
    Id supplierContactOwnerId = getSupplierAccountOwnerId(); 
    
    System.debug('Exit: getSupplierContactOwnerId(). Returned supplierContactOwnerId: ' + supplierContactOwnerId);
    return supplierContactOwnerId;
  }
    

  /*******************************************************************
  Purpose:  This method gets the Account Owner Id using the Supplier_JIT_Provisioning_Setting__mdt metadata object. This Id will be used
            as the owner of the account this class creates. 
                                                     
  Parameters: None
  Returns: User Id
  Throws [Exceptions]: Label.SSO_NoAccountOwner                                                     
  ********************************************************************/     
  private static Id getSupplierAccountOwnerId() {
  
    System.debug('Entry: getSupplierAccountOwnerId()');
    
    if(String.isEmpty(accountOwnerUserName.Value__c)) {
      throw new JitException(Label.SSO_SupplierAccountOwnerNotDefined_ui);
    }
              
    List<User> supplierAccountOwners = [SELECT Id FROM User WHERE Username = :accountOwnerUserName.Value__c];
    
    if(supplierAccountOwners.size() == 0) {
      throw new JitException(String.format(Label.SSO_NoAccountOwner_ui, new List<String>{String.valueOf(accountOwnerUserName.Value__c)}));    
    }
    
    Id supplierAccountOwnerId = supplierAccountOwners.get(0).Id; 
    
    System.debug('Exit: getSupplierAccountOwnerId(). Returned supplierAccountOwnerId: ' + supplierAccountOwnerId);       
    return supplierAccountOwnerId;
  } 


  /*******************************************************************
  Purpose:  This method will create a username using values from a supplied email adress and a suffix from the 
            Supplier_JIT_Provisioning_Setting__mdt metadata object. Using the metedata object provides a 
            basic level of control to change the users login names without changing code. 
                                                     
  Parameters: Email
  Returns: userName - i.e. something fit for entry into the User.userName field
  Throws [Exceptions]: Label.SSO_NoDomainSuffix                                                   
  ********************************************************************/   

  private String generateUsername(String email) {

    System.debug('Entry: generateUsername(String email)');

    if(String.isEmpty(domainSuffux.Value__c)) {
      throw new JitException(Label.SSO_NoDomainSuffix_ui);
    }
    
    String userName = email.substringBefore('@') + '@' + domainSuffux.Value__c;
    
    System.debug('Exit: generateUsername(). Returned userName: ' + userName);
    return userName;
  }

  /*******************************************************************
  Purpose:  This method is intended to be a validation method to do some early checks on the assertion message
            for compulsory fields or any other arbitrary validation that might be required. Some of these errors\
            are handled in the methods, but this will serve as an easy place to add logical rejections or extra errors
                                                     
  Parameters: samlAttributes (System generated Map of the SAML AttributeStatement)
  Returns: nothing (void)
  Throws [Exceptions]:  Label.SSO_UserEmailNull
                        Label.SSO_UserEmailNotSupplied
                        Label.SSO_DUNSNumberNull
                        Label.SSO_DUNSNumberNotSupplied
  ********************************************************************/ 

  private void checkCompulsoryFieldsInAssertion(Map<String, String> samlAttributes, Boolean originatesFromCommunity, String federationIdentifier) {

    System.debug('Entry: checkCompulsoryFieldsInAssertion(Map<String, String> samlAttributes, Boolean originatesFromCommunity)');


    // compulsory email address
    if(String.isEmpty(federationIdentifier)) {
      throw new JitException(Label.SSO_FederationIdentifierNull_ui);
    }   

    // compulsory email address
    if(samlAttributes.containsKey('user_email')) {
      String emailAddress = samlAttributes.get('user_email');
      if (String.isEmpty(emailAddress)) {
        throw new JitException(Label.SSO_UserEmailNull_ui);
      }   
    } else {
      throw new JitException(Label.SSO_UserEmailNotSupplied_ui);
    }
    
    if(originatesFromCommunity) {
      // compulsory DUNS number
      if(samlAttributes.containsKey('organisation_duns_number')) {
        String dunsNumber = samlAttributes.get('organisation_duns_number');
        if (String.isEmpty(dunsNumber) || Decimal.valueOf(dunsNumber) <= 0) {
          throw new JitException(Label.SSO_DUNSNumberNull_ui);          
        }   
      } else {
        throw new JitException(Label.SSO_DUNSNumberNotSupplied_ui);       
      }
    }
    
    System.debug('Exit: checkCompulsoryFieldsInAssertion(). Method is void and returns nothing.');
  }


  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged) that has been modified to suit the provisioning
            logic required for CCS. Dependig on the 'create' parameter, this will create a new user or update an existing one.

            Note that this method doesn't actually issue any DML to _create_ a user - it simply prepares a User object which is 'magically' 
            collected by the system and created as part of the JIT provisioning system behaviour. It appears that this is intentional Salesforce behaviour.
                                                     
  Parameters: isCreateAssertion       Boolean indicating if this is a new assertion (true)(i.e a new login session) or an existing session being reauthenticated (false)
              u                       A user object. For new users this will have been just initialised.
              samlAttributes          System generated Map of the SAML AttributeStatement
              federationIdentifier    System generated field which has extraced the SAML identifier from the SAML Assertion 
              isStandard              System generated boolean. Doesn't appear to be used (I've not used it) in the class, but has been left as 
                                      part of the system generated class.
  Returns: nothing (void)
  Throws [Exceptions]:  none
  ********************************************************************/   

  private void handleUser(boolean isCreateAssertion, User u, Map<String, String> samlAttributes, String federationIdentifier, boolean isStandard) {

    System.debug('Entry: handleUser(boolean isCreateAssertion, User u, Map<String, String> samlAttributes, String federationIdentifier, boolean isStandard)');
      
    if(isCreateAssertion) {
      if(samlAttributes.containsKey('user_email')) {
        u.FederationIdentifier = federationIdentifier;
        u.Email = samlAttributes.get('user_email');
        u.Username = generateUsername(samlAttributes.get('user_email'));
      } else {
        u.FederationIdentifier = federationIdentifier;
      }
    }
    if(samlAttributes.containsKey('user_unique_id')) {
      u.User_External_Id__c = samlAttributes.get('user_unique_id');
    }
    if(samlAttributes.containsKey('user_telephone')) {
      u.Phone = samlAttributes.get('user_telephone');
    }
    if(samlAttributes.containsKey('user_first_name')) {
      u.FirstName = samlAttributes.get('user_first_name');
    }
    if(samlAttributes.containsKey('user_last_name')) {
      u.LastName = samlAttributes.get('user_last_name');
    }
    if(samlAttributes.containsKey('user_position')) {
      u.Title = samlAttributes.get('user_position');
    }
    if(samlAttributes.containsKey('organisation_name')) {
      u.CompanyName = samlAttributes.get('organisation_name');
    }
    if(samlAttributes.containsKey('user_mobile')) {
      u.MobilePhone = samlAttributes.get('user_mobile');
    }
    if(samlAttributes.containsKey('user_extension')) {
      u.Extension = samlAttributes.get('user_extension');
    }
             
    if(isCreateAssertion) {
    
    String uid = UserInfo.getUserId();
    User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:uid];     

      u.LocaleSidKey = currentUser.LocaleSidKey;
      u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
      
      String alias = '';
      if(u.FirstName == null) {
        alias = u.LastName;
      } else {
        alias = u.FirstName.left(0) + u.LastName;
      }
      if(alias.length() > 5) {
        alias = alias.substring(0, 5);
      }
      
      u.Alias = alias;
      u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
      u.EmailEncodingKey = currentUser.EmailEncodingKey;
      

      /*
       * If you are updating Contact or Account object fields, you cannot update the following User fields at the same time.
       * If your identity provider sends thehese User fields as attributes along with Contact 
       * or Account fields, you must modify the logic in this class to update either these 
       * User fields or the Contact and Account fields.
       */

      u.IsActive = true;
      u.ForecastEnabled = false;
      u.ProfileId = getSupplierProfileId();
    }

    //Handle custom fields here

    if(!isCreateAssertion) {
        update(u);
    }
      
    System.debug('Exit: handleUser(). Method is void and returns nothing.');
  }


  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged) that has been modified to suit the provisioning
            logic required for CCS. Depending on the 'create' parameter, this will create a new Contact or update an existing one.
                                                     
  Parameters: isCreateAssertion       Boolean indicating if this is a new assertion (true)(i.e a new login session) or an existing session being reauthenticated (false)
              accountId               ID of the account to be associated with this contact. Has been auto-generated as a String (although I presume it would be fine as an Id)
              u                       A user object. For new users this will have been just initialised. For existing users this will have been matched by the updateUser method.
              samlAttributes          System generated Map of the SAML AttributeStatement

  Returns: nothing (void)
  Throws [Exceptions]:  Label.SSO_ExistingContactNotMatchedByEmail
                        Label.SSO_TooManyContactsMatchedByEmail
                        Label.SSO_UserEmailNotSupplied
                        Label.SSO_UnableToCreateContact
                        Label.SSO_ExistingAccountNotMatchedByDUNSNumber
                        Label.SSO_DUNSNumberNotSupplied
                        Label.SSO_UnableToCreateAccount
  ********************************************************************/  

  private void handleContact(boolean isCreateAssertion, String accountId, User u, Map<String, String> samlAttributes) { 
      
    System.debug('Entry: handleContact(boolean create, String accountId, User u, Map<String, String> attributes)');
    
    Contact c;
    boolean newContact = false;
      
    if(samlAttributes.containsKey('user_email')) {
      String emailAddress = samlAttributes.get('user_email');
      List<Contact> contactResultList = [SELECT Id, AccountId FROM Contact WHERE Email=:emailAddress AND AccountId =: AccountId];
      if(contactResultList.size() == 0) {
        if(isCreateAssertion) {
          // insert SAML assertion
          c = new Contact();
          c.Email = samlAttributes.get('user_email');
          newContact = true;
        } else {      
          // update SAML assertion - can't match email address.
          throw new JitException(String.format(Label.SSO_ExistingContactNotMatchedByEmail_ui, new List<String> {String.valueOf(emailAddress)}));
        }           
      } else if (contactResultList.size() == 1) {
        // match found
        // Cannot update the User.ContactId once set (seems to be a Salesforce limitation for Community/Portal users)
        // So, have to query to see if a user exists for this contact - if not, then we need to set the u.ContactId
        // otherwise, we don't (well, can't)
        Integer numberOfRelatedUsers = [SELECT count() FROM User WHERE ContactId = :contactResultList.get(0).Id];
        if(numberOfRelatedUsers == 0) {
          u.ContactId = contactResultList.get(0).Id;
        } else {
          if(isCreateAssertion) { // create assertions shouldn't have a numberOfRelatedUsers > 0, so this is a problem, indicating the Federation Identifier has probably been messed with on an existing user
            throw new JitException(String.format(Label.SSO_ContactAssociatedWithUserButUserNotFound_ui, new List<String> {String.valueOf(contactResultList.get(0).Id)}));
          }
        }
        c = contactResultList.get(0);
      } else if (contactResultList.size() >= 2) {
        throw new JitException(String.format(Label.SSO_TooManyContactsMatchedByEmail_ui, new List<String> {String.valueOf(emailAddress)}));
      }
    } else {
      // No email address - Throw a JIT error
      throw new JitException(Label.SSO_UserEmailNotSupplied_ui);
    }

    if(!newContact && c.AccountId != accountId) {
      throw new JitException(String.format(Label.SSO_AccountMismatch_ui, new List<String> {String.valueOf(samlAttributes.get('user_email')), String.valueOf(c.AccountId), String.valueOf(accountId)}));
    }

    if(samlAttributes.containsKey('user_unique_id')) {
      c.Contact_External_Id__c = samlAttributes.get('user_unique_id');
    }
    if(samlAttributes.containsKey('user_first_name')) {
      c.FirstName = samlAttributes.get('user_first_name');
    }
    if(samlAttributes.containsKey('user_last_name')) {
      c.LastName = samlAttributes.get('user_last_name');
    }
    if(samlAttributes.containsKey('user_telephone')) {
      c.Phone = samlAttributes.get('user_telephone');
    }
    if(samlAttributes.containsKey('user_extension')) {
      c.extension__c = samlAttributes.get('user_extension');
    }        
    if(samlAttributes.containsKey('user_mobile')) {
      c.MobilePhone = samlAttributes.get('user_mobile');
    }
    if(samlAttributes.containsKey('user_position')) {
      c.Title = samlAttributes.get('user_position');
    }
    if(samlAttributes.containsKey('user_title')) {
      c.Salutation = samlAttributes.get('user_title');
    }
    if(isCreateAssertion) {
      c.OwnerId = getSupplierContactOwnerId();
    }

    if(contactOrigin != null) {
      if(contactOrigin.Value__c != null) {
        c.Origin__c = contactOrigin.Value__c;

      }
    }

    try {
      if(newContact) {
        c.AccountId = accountId;
        insert(c);
        u.ContactId = c.Id;
      } else {
        update(c);
      }
    } catch(Exception e) {
      // handle exception
     throw new JitException(String.format(Label.SSO_UnableToCreateContact_ui, new List<String> {String.valueOf(e.getMessage())}));
    }
    
    System.debug('Exit: handleContact(). Method is void and returns nothing.');
  }

  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged) that has been modified to suit the provisioning
            logic required for CCS. Depending on the 'create' parameter, this will create a new Account or update an existing one.
                                                     
  Parameters: isCreateAssertion       Boolean indicating if this is a new assertion (true)(i.e a new login session) or an existing session being reauthenticated (false)
              u                       A user object. For new users this will have been just initialised. For existing users this will have been matched by the updateUser method.
              samlAttributes          System generated Map of the SAML AttributeStatement

  Returns: Account Id
  Throws [Exceptions]:  Label.SSO_ExistingAccountNotMatchedByDUNSNumber
                        Label.SSO_DUNSNumberNotSupplied
                        Label.SSO_UnableToCreateAccount
  ********************************************************************/  
  private String handleAccount(boolean isCreateAssertion, User u, Map<String, String> samlAttributes) {
  
    System.debug('Entry: handleAccount(boolean isCreateAssertion, User u, Map<String, String> samlAttributes)');
    
    Account a;
    boolean newAccount = false;
        
    if(samlAttributes.containsKey('organisation_duns_number')) {
    // DUNS numbers should probably be a String in Salesforce because of visual formatting...but is an Integer for now. 
      Decimal dunsNumber = Decimal.valueOf(samlAttributes.get('organisation_duns_number'));
      
      // DUNS_Number__c is Unique in Salesforce anyway, but limited to one to avoid errors.
      List<Account> accountResultList = [SELECT Id FROM Account WHERE DUNS_Number__c =:dunsNumber ORDER BY LastModifiedDate DESC LIMIT 1];
      if(accountResultList.size() == 0) {
        // create new account if SAML assertion is a 'create' assertion
        if(isCreateAssertion) {
          a = new Account();
          a.DUNS_Number__c = dunsNumber;
          newAccount = true; 
          // if SAML assertion is an 'update', then throw an error - we didn't find a matching account
        } else {
          throw new JitException(String.format(Label.SSO_ExistingAccountNotMatchedByDUNSNumber_ui, new List<String> {String.valueOf(dunsNumber)}));
        }                 
      } else {
        a = accountResultList.get(0);
      }
    } else {
      throw new JitException(Label.SSO_DUNSNumberNotSupplied_ui);                
    }

    if(newAccount) {
      a.OwnerId = getSupplierAccountOwnerId();
      List<RecordType> recordTypeResultList = [SELECT Id FROM RecordType WHERE Name =:accountRecordType.Value__c];
      if(recordTypeResultList.size() > 0) {
        a.RecordTypeId = recordTypeResultList.get(0).Id;
      }
    }
                
    if(samlAttributes.containsKey('organisation_name') && newAccount) {
        a.Name = samlAttributes.get('organisation_name');
    }
    if(samlAttributes.containsKey('organisation_unique_id')) {
      a.Account_External_Id__c = samlAttributes.get('organisation_unique_id');
    }
    
    try {
      if(newAccount) {
          insert(a);
      } else {
          update(a);
      }
    } catch(Exception e) {
      // handle error
      throw new JitException(String.format(Label.SSO_UnableToCreateAccount_ui, new List<String> {String.valueOf(e.getMessage())}));
    }
      
    System.debug('Exit: handleAccount(). Returned a.Id: ' + a.Id);
    
    return a.Id;
  }


  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged). 
                                                     
  Parameters: create                  Boolean indicating if this is a new assertion (true)(i.e a new login session) or an existing session being reauthenticated (false)
              u                       A user object. For new users this will have been just initialised. For existing users this will have been matched by the updateUser method.
              SamlSsoProviderId       System supplied Id of the SSO configuration (Setup -> Security Controls -> Single Sign-on Settings -> <<<record in question>>>)
              communityId             System supplied Id for the Community from which the SSO request originates. This must contain a value for this class to provision an Account and a Contact
              portalId                System supplied Id for a Portal (not available to CCS as deprecated functionality). Expecting this to always be null.
              federationIdentifier    System generated field which has extraced the SAML identifier from the SAML Assertion 
              attributes              System generated Map of the SAML AttributeStatement
              assertion               System supplied Base64 encoded version of what I assume is the raw SAML assertion. Not used in this class.

  Returns: nothing (void)
  Throws [Exceptions]:  None
  ********************************************************************/  

  private void handleJit(boolean isCreateAssertion, User u, Id samlSsoProviderId, Id communityId, Id portalId,
    String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion) {
    System.debug('Entry: handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion)'); 
    
    // Disable duplicate management (for this class)
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;

    Savepoint sp = Database.setSavepoint();

    try {
      checkCompulsoryFieldsInAssertion(samlAttributes, true, federationIdentifier);
      String account = handleAccount(isCreateAssertion, u, samlAttributes);
      handleContact(isCreateAssertion, account, u, samlAttributes);                     
      handleUser(isCreateAssertion, u, samlAttributes, federationIdentifier, false);
    } catch (Exception e) {
      Database.rollback(sp);
      throw new JitException(e.getMessage());
    }    
    System.debug('Exit: handleJit(). Method is void and returns nothing.');
  }

  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged). Apart from this comment, the method is UNCHANGED

            As I understand it, this method is called when the first SSO request for a user's session occurs (i.e. the first time the log on for the day
            or session - not just the first time they log in ever)
            Thereafter, all subsequent SSO calls for that user (provided he is still logged in) will call the updateUser method.
                                                     
  Parameters: SamlSsoProviderId       System supplied Id of the SSO configuration (Setup -> Security Controls -> Single Sign-on Settings -> <<<record in question>>>)
              communityId             System supplied Id for the Community from which the SSO request originates. This must contain a value for this class to provision an Account and a Contact
              portalId                System supplied Id for a Portal (not available to CCS as deprecated functionality). Expecting this to always be null.
              federationIdentifier    System generated field which has extraced the SAML identifier from the SAML Assertion 
              attributes              System generated Map of the SAML AttributeStatement
              assertion               System supplied Base64 encoded version of what I assume is the raw SAML assertion. Not used in this class.

  Returns: User object
  Throws [Exceptions]:  None
  ********************************************************************/ 

  global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,
    String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion) {   
    System.debug('Entry: createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion)');  
      
      
    User u = new User();
    handleJit(true, u, samlSsoProviderId, communityId, portalId, federationIdentifier, samlAttributes, rawAssertion);
        
    System.debug('Exit: createUser(). Returned u: ' + u);    
    return u;
  }

  /*******************************************************************
  Purpose:  This is a system generated method (method signature & parameters unchanged). Apart from this comment, the method is UNCHANGED

            As I understand it, this method is called for all subsequent SSO calls after the initial login request.
                                                     
  Parameters: userId                  System supplied Id that presumably comes from the existing signon session
              SamlSsoProviderId       System supplied Id of the SSO configuration (Setup -> Security Controls -> Single Sign-on Settings -> <<<record in question>>>)
              communityId             System supplied Id for the Community from which the SSO request originates. This must contain a value for this class to provision an Account and a Contact
              portalId                System supplied Id for a Portal (not available to CCS as deprecated functionality). Expecting this to always be null.
              federationIdentifier    System generated field which has extraced the SAML identifier from the SAML Assertion 
              attributes              System generated Map of the SAML AttributeStatement
              assertion               System supplied Base64 encoded version of what I assume is the raw SAML assertion. Not used in this class.

  Returns: User object
  Throws [Exceptions]:  None
  ********************************************************************/ 

  global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
    String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion) {
    System.debug('Entry: updateUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> samlAttributes, String rawAssertion)');  
      
    User u = [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId];
    handleJit(false, u, samlSsoProviderId, communityId, portalId, federationIdentifier, samlAttributes, rawAssertion);
          
    System.debug('Exit: updateUser(). Method is void and returns nothing.');            
  }
}