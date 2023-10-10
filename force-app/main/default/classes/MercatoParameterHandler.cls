/*****************************************************************************************
Name:  MercatoParameterHandler()
============================================================================================================
Purpose:                                                            
-------    
This class attaches custom attributes to the OAuth Response for Mercato. A custom class was used
because when trying to add the Account.Account_URN__c to the Connected App Custom Attributes
(Setup -> Manage Apps -> Connected Apps -> <<APP>> ->  Custom Attributes), the Salesforce UI crashed. 
Presumably, this is a defect in Salesforce. Anyway, that's why this class exists - because we were unable 
to configure the option in the UI. 
============================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR      DATE    DETAIL                Description
1.0       Garth James   30/11/2016  INITIAL DEVELOPMENT   Created 
********************************************************************************************/
global class MercatoParameterHandler extends Auth.ConnectedAppPlugin{
  class AuthException extends Exception {}

  static String PRM_ORGANIZATION_NAME = 'MERCATO_SP_PARAMETER_ORGANIZATION_NAME';
  static String PRM_ORGANIZATION_URN  = 'MERCATO_SP_PARAMETER_ORGANIZATION_URN';
  static String PRM_FIRST_NAME        = 'MERCATO_SP_PARAMETER_USER_GIVEN_NAME';
  static String PRM_LAST_NAME         = 'MERCATO_SP_PARAMETER_USER_FAMILY_NAME';
  static String PRM_LAST_UPDATED_DATE = 'MERCATO_SP_PARAMETER_LAST_UPDATED_DATE';
  static String PRM_IS_ACTIVE         = 'MERCATO_SP_PARAMETER_ACTIVE_FLAG';
  static String PRM_EMAIL_ADDRESS     = 'MERCATO_SP_PARAMETER_EMAIL_ADDRESS';

  static String SSO_CUSTOM_SETTING_OBJECT_NAME  = 'OpenID SSO Settings';
	static String URN_FIELD = 'Account_URN__c';
    
  /*******************************************************************
  Purpose:  This method returns a map of custom attributes to be added to the OAuth response. This is an OOTB method (signature unchanged) that has been overridden.
                                                     
  Parameters: userId                        Id of the user signing in 
              connectedAppId                Id of the connected app
              formulaDefinedAttributes      Map of attributes
              context                       unknown


  Returns: formulaDefinedAttributes
  Throws [Exceptions]:  
  ********************************************************************/ 
  global override Map<String,String> customAttributes(Id userId, Id connectedAppId, Map<String,String> formulaDefinedAttributes, Auth.InvocationContext context) {

      Map<String, Openid_SSO_Settings__c> oAuthSettingsMap = Openid_SSO_Settings__c.getAll();
      Map<String, String>                 oAuthStringMap   = new Map<String, String>();

      if (oAuthSettingsMap.isEmpty()) {
        throw new AuthException(String.format(Label.OpenID_SSO_CustomSettingNotDefined, new List<String> {SSO_CUSTOM_SETTING_OBJECT_NAME}));
      }

      for (Openid_SSO_Settings__c settingsRow: oAuthSettingsMap.values()) {
        oAuthStringMap.put(settingsRow.Name, settingsRow.Value__c);
      }    

      //List<User> listOfUsers = [SELECT isPortalEnabled, FirstName, LastName, LastModifiedDate, isActive, Email, Contact.Email, Contact.Account.Name, Contact.Account.Account_URN__c FROM User WHERE Id = :userId];
      String userQuery = 'SELECT isPortalEnabled, FirstName, LastName, LastModifiedDate, isActive, Email, Contact.Email, Contact.Account.Name, Contact.Account.' + URN_FIELD + ' FROM User WHERE Id = :userId';
	  List<User> listOfUsers = Database.query(userQuery);

      String companyName;
      String accountURN;
      String emailAddress;

      if(listOfUsers.size()>0 || listOfUsers!=null) {
        // is the user a community user?

        if(listOfUsers.get(0).isPortalEnabled) {
          companyName  = listOfUsers.get(0).Contact.Account.Name; 
          //accountURN   = listOfUsers.get(0).Contact.Account.Account_URN__c;
          accountURN   = (string)listOfUsers.get(0).Contact.Account.get('Account_URN__c');
 		  emailAddress = listOfUsers.get(0).Contact.Email;

        // otherwise, must be an employee
        } else {
          // so...get the internal account
          Org_Settings__c orgSettings  = Org_Settings__c.getOrgDefaults();
          //List<Account> listOfAccounts = [SELECT Id, Account_URN__c, Name FROM Account WHERE Id = :orgSettings.Internal_Account_Id__c];
          	 Id internalAccId = orgSettings.Internal_Account_Id__c;
             String accountQuery = 'SELECT Id, ' + URN_FIELD + ', Name FROM Account WHERE Id = :internalAccId';
             List<Account> listOfAccounts = Database.query(accountQuery);
          if(listOfAccounts.size()>0 || listOfAccounts!=null) {
            companyName = listOfAccounts.get(0).Name;
            //accountURN  = listOfAccounts.get(0).Account_URN__c;
			accountURN   = (string)listOfAccounts.get(0).get('Account_URN__c'); 
          } else {
            companyName = UserInfo.getOrganizationName(); 
            accountURN  = UserInfo.getOrganizationId(); 
          }

          emailAddress  = listOfUsers.get(0).Email;
        }
      
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_ORGANIZATION_NAME)  , companyName);
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_ORGANIZATION_URN)   , accountURN);
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_FIRST_NAME)         , listOfUsers.get(0).FirstName);
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_LAST_NAME)          , listOfUsers.get(0).LastName);
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_LAST_UPDATED_DATE)  , String.valueOf(listOfUsers.get(0).LastModifiedDate));
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_IS_ACTIVE)          , String.valueOf(listOfUsers.get(0).isActive));
        formulaDefinedAttributes.put(oAuthStringMap.get(PRM_EMAIL_ADDRESS)      , emailAddress);

      }

      return formulaDefinedAttributes;
  }  

}