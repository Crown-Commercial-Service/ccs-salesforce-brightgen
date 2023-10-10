/*****************************************************************************************
Name:  ContractFinderAppHandler()
============================================================================================================
Purpose:                                                            
-------    
This class attaches custom attributes to the other custom attributes set up 
in (Setup -> Manage Apps -> Connected Apps -> <<APP>> ->  Custom Attributes)

The parameters requested by Contracts Finder are :
user_first_name - set in custom attributes admin screen
user_last_name - set in custom attributes admin screen
user_email - set in custom attributes admin screen
user_login - set in custom attributes admin screen
organisation_duns_number - Taken from the account object 
organisation_name - Taken from account object
location_duns_number - Not sure what this is but we don't store it 
location_name - Not sure what this is but we dont store it
location_address  - Taken from account object (BillingStreet)
location_city  - Taken from account object(BillingCity)
location_county - Taken from account object(BillingState)
location_postcode - Taken from account object(BillingPostalCode)
location_country_iso3 - Don't store this so not implemented

============================================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR      DATE    DETAIL                Description
1.0       Jim MacAulay   12/07/2017  INITIAL DEVELOPMENT   Copied primarily from MercatoParameterHandler 
********************************************************************************************/

global class ContractFinderAppHandler extends Auth.ConnectedAppPlugin{
    class AuthException extends Exception {}
    
    global override Map<String,String> customAttributes(Id userId, Id connectedAppId, Map<String,String> formulaDefinedAttributes, Auth.InvocationContext context) {
        
        String userQuery = 'SELECT isPortalEnabled, FirstName, LastName, LastModifiedDate, isActive, Email, Contact.Email, Contact.Account.Name, Contact.Account.Account_URN__c, Contact.Account.DUNS_Number__c, Contact.Account.BillingStreet, Contact.Account.BillingCity,Contact.Account.BillingState, Contact.Account.BillingCountry, Contact.Account.BillingCountryCode, Contact.Account.BillingPostalCode  FROM User WHERE Id = :userId';
        List<User> listOfUsers = Database.query(userQuery);
        System.debug('CRS Listofusers: ' + listOfUsers);
        String companyName;
        String accountURN;
        String dunsNumber = ''; 
        String emailAddress;
        String billingStreet = '';
        String billingCity = '';
        String billingState = '';
        String billingCountry = '';
        String billingCountryCode = '';
        String billingPostalCode = '';
        
        if(listOfUsers.size()>0 && listOfUsers!=null) {
            // is the user a community user?
            
            if(listOfUsers.get(0).isPortalEnabled) {
                
                // Get details from Account Object
                companyName  = listOfUsers.get(0).Contact.Account.Name; 
                accountURN   = (string)listOfUsers.get(0).Contact.Account.get('Account_URN__c');
                dunsNumber = String.valueOf(listOfUsers.get(0).Contact.Account.get('DUNS_Number__c'));
                emailAddress = listOfUsers.get(0).Contact.Email;
                billingStreet = listOfUsers.get(0).Contact.Account.BillingStreet;
                billingCity = listOfUsers.get(0).Contact.Account.BillingCity;
                billingState = listOfUsers.get(0).Contact.Account.BillingState;
                billingCountry = listOfUsers.get(0).Contact.Account.BillingCountry;
                billingCountryCode = listOfUsers.get(0).Contact.Account.BillingCountryCode; 
                billingPostalCode = listOfUsers.get(0).Contact.Account.BillingPostalCode;
                
                // otherwise, must be an employee
            } else {
                // so...get the internal account (id hard set in Custom Settings)
                Org_Settings__c orgSettings  = Org_Settings__c.getOrgDefaults();                
                Id internalAccId = orgSettings.Internal_Account_Id__c;
                
                String accountQuery = 'SELECT Id, Account_URN__c, DUNS_Number__c, Name,BillingStreet, BillingCity, BillingState, BillingCountry,BillingCountryCode, BillingPostalCode FROM Account WHERE Id = :internalAccId';
                List<Account> listOfAccounts = Database.query(accountQuery);
                
                // This should be the CCS account record so get the details from here
                if( listOfAccounts!=null && listOfAccounts.size()>0) {
                    companyName = listOfAccounts.get(0).Name;
                    accountURN   = (string)listOfAccounts.get(0).get('Account_URN__c'); 
                    billingStreet = listOfAccounts.get(0).BillingStreet;
                    billingCity = listOfAccounts.get(0).BillingCity;
                    billingState = listOfAccounts.get(0).BillingState;
                    billingCountry = listOfAccounts.get(0).BillingCountry;
                    billingCountryCode = listOfAccounts.get(0).BillingCountryCode;
                    billingPostalCode = listOfAccounts.get(0).BillingPostalCode;
                    dunsNumber = '232204180';
                } else {
                    // Should never really get here - it means CCS record was not found !!
                    companyName = UserInfo.getOrganizationName(); 
                    accountURN  = UserInfo.getOrganizationId(); 
                    dunsNumber = '232204180';
                }
            }
            formulaDefinedAttributes.put('organisation_name'  , companyName);
            formulaDefinedAttributes.put('organisation_urn'   , accountURN);
            formulaDefinedAttributes.put('organisation_duns_number'   , dunsNumber);
            formulaDefinedAttributes.put('location_address'   , billingStreet);
            formulaDefinedAttributes.put('location_city'   , billingCity);
            formulaDefinedAttributes.put('location_county'   , billingState);
            formulaDefinedAttributes.put('location_country'   , billingCountry);
            formulaDefinedAttributes.put('location_country_code'   , billingCountryCode);
            formulaDefinedAttributes.put('location_postcode'   , billingPostalCode);
        }   
        return formulaDefinedAttributes;
    }  
}