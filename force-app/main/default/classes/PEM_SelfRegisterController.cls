/*********************************************************************
Name:  PEM_SelfRegisterController
Copyright © 2016  Salesforce
=====================================================================

Purpose: This class acts as the controller for the Portal Registration Form.
The Form handles three different registration processes.
1) Single recognised Domain (Create user and associate with Org found).
2) Multiple domain found (allow user to select which org they belong).
3) No domain found (Assign them to the default org and create the contact and case)

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles         2016-11-04       Initial version
 1.1    Sebastian Kubalski  2016-12-12       Added removeWhitespaces    Method is used to remove whitespaces from contact number
 1.2		Simon Coles 				2016-12-13       Add without Sharing        So we don't have to enable lots of objects read access it's safer to do it this here.
*********************************************************************/

global without sharing class PEM_SelfRegisterController {

	// Wrapper Class to pass values back to the Component.
	public class responseWrapper {
	    @AuraEnabled public Integer ResponseCode;
	    @AuraEnabled public String Message;
		  @AuraEnabled public List<Account> AccountList;

	    public responseWrapper() {
	       ResponseCode=null;
	       Message=null;
			   AccountList=null;
	    }
	  }

    @TestVisible
    private static String removeWhitespaces(String value) {
      return value != null ? value.trim().replaceAll('(\\s+)', '') : null;
    }

    // This is the main method used by the Registration form.  It validate the data submitted,
    // checks the domain and decides which type of user is registering.
    @AuraEnabled
    public static responseWrapper selfRegister(String firstname ,String lastname, String email, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword, String contactNumber, Boolean preValidated, String companyName) {

		responseWrapper pageResponse = new responseWrapper();
    String emailDomain;
    Savepoint sp = Database.setSavepoint();
        try {
            contactNumber = removeWhitespaces(contactNumber);

            // If we are submitting the second part of the form then we don't need to revalidate the first form
            if(!preValidated) {
                // Check First Name
                if (firstname == null || String.isEmpty(firstname)) {
          				pageResponse.ResponseCode = 0;
          				pageResponse.Message = System.Label.PEM_FirstNameRequired;
          				return pageResponse;
                } else {
        				  // Check Alpha Numeric Only
          				Pattern isLetters = Pattern.Compile('^([a-zA-Z]|-|\'|é|,|\\s)*$');
          				Matcher alphaMatch = isLetters.matcher(firstname);
          				if(!alphaMatch.Matches()) {
          					pageResponse.ResponseCode = 0;
          					pageResponse.Message = System.Label.PEM_FirstNameInvalidChars;
          					return pageResponse;
          				}
                }

    			      // Check Last Name
                if (lastname == null || String.isEmpty(lastname)) {
          				pageResponse.ResponseCode = 0;
          				pageResponse.Message = Label.Site.lastname_is_required;
          				return pageResponse;
                } else {
          				// Check Alpha Numeric Only
          				Pattern isLetters = Pattern.Compile('^([a-zA-Z]|-|\'|é|,|\\s)*$');
          				Matcher alphaMatch = isLetters.matcher(lastname);
          				if(!alphaMatch.Matches()) {
          					pageResponse.ResponseCode = 0;
          					pageResponse.Message = System.Label.PEM_LastNameInvalidChars;
          					return pageResponse;
          				}
    			      }

    			      // Check Email
                if (email == null || String.isEmpty(email)) {
          				pageResponse.ResponseCode = 0;
          				pageResponse.Message = Label.Site.email_is_required;
          				return pageResponse;
                }

    			      // Check Email Valid & Get Domain
    			      Boolean validEmail = Site.isValidUsername(email);
          			if (!validEmail) {
          				pageResponse.ResponseCode = 0;
          				pageResponse.Message = System.Label.PEM_EmailAddressInvalid;
          				return pageResponse;
                } else {
                  // Check to see if the email Username address has been used already.
                  List<User> UserNameList = new List<User>([SELECT Id from USER WHERE Username = :email]);
                  if(UserNameList.size() != 0) {
                    pageResponse.ResponseCode = 0;
            				pageResponse.Message = System.Label.PEM_EmailAlreadyExist;
            				return pageResponse;
                  }

                  // Grab the domain from the email Address
            			emailDomain = email.split('@').get(1);
                  // Check to see if the domain is blacklisted.
                  List<PEM_DomainBlackList__c> blacklistedDomains = new LIST<PEM_DomainBlackList__c>([SELECT id from PEM_DomainBlackList__c WHERE Domain_Name__c = :emailDomain]);
                  if(blacklistedDomains.size() >= 1) {
                    pageResponse.ResponseCode = 0;
            				pageResponse.Message = System.Label.PEM_DomainBlacklisted;
            				return pageResponse;
                  }
                }
            }

            // Validate second form fields
            if(preValidated) {
              // Check Phone Number
              if (contactNumber == null || String.isEmpty(contactNumber)) {
                pageResponse.ResponseCode = 0;
                pageResponse.Message = System.Label.PEM_ContactNumberRequired;
                return pageResponse;
              } else {
                // Check Numeric Only
                Pattern isLetters = Pattern.Compile('^[0-9]+$');
                Matcher alphaMatch = isLetters.matcher(contactNumber);
                if(!alphaMatch.Matches()) {
                  pageResponse.ResponseCode = 0;
                  pageResponse.Message = System.Label.PEM_ContactNumberInvalid;
                  return pageResponse;
                }
              }
            }

            // First Part of Form is Valid
            // Grab the domain from the email Address
            emailDomain = email.split('@').get(1);
			      // User Information Correct - Check to see if we have a matching Domain.
      			List<id> matchedAccountIds= new List<id>();
      			for(Account_Email_Domain__c a : [SELECT Account__c FROM Account_Email_Domain__c WHERE Email_Domain__r.Email_Domain__c = :emailDomain ORDER BY Account__r.Name ASC]){
      				matchedAccountIds.add(a.Account__c);
      			}

			      // Get Company Information
      			List<Account> CompanyList = new List<Account>([SELECT Id, Name from Account WHERE Id IN:matchedAccountIds ORDER BY Name ASC]);

            // Check Nickname is Unique and provide a random number if not
            List<User> UserList = new List<User>([SELECT Id from USER WHERE CommunityNickname = :firstname+lastname]);
            String communityNickname;
            if(UserList.size() >= 1) {
              communityNickname = firstname+lastname+Math.round(Math.random()*100);
            } else {
              communityNickname = firstname+lastname;
            }

      			// Actions depending on Company Info
      			// Route One (Valid SINGLE Domain - Create Potal User, Create Contact and Link to Account, Send Email and Display Check your email page)
            if(CompanyList.size() == 1 || accountId != null || accountId == 'Other') {
      				// Create User Record
      				User u = new User();
              u.Username = email;
              u.put('Email',email);
              u.FirstName = firstname;
              u.LastName = lastname;
      				u.CommunityNickname = communityNickname;
              u.Phone = contactNumber;
              u.CompanyName = companyName;
      				password = null;
              if(accountId == null) accountId = CompanyList[0].Id;

      				// Insert the Portal User
      				String userId = Site.createPortalUser(u, accountId, password);

       				// Validate User Creation
      				if (userId != null) {
  				      // Redirect to Activate your account Page.
                ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                aura.redirect(confirmRef);
	            } else
      	        return null;
      			}

      			// Route Two (MULTIPLE Domains - Pass CompanyList back to Component)
      			else if(CompanyList.size() > 1) {
      				pageResponse.ResponseCode = 1;
      				pageResponse.AccountList = CompanyList;
      				return pageResponse;
      			}

            // Route Two (MULTIPLE Domains - Pass CompanyList back to Component)
      			else if(CompanyList.size() == 0 && !preValidated) {
      				pageResponse.ResponseCode = 2;
      				return pageResponse;
      			}

      			// Route Three (NO Domain is Found - Gather additional info, Create a case and show redirection page.)
      			else if(CompanyList.size() == 0 && preValidated) {

              // Create User Record
      				User u = new User();
              u.Username = email;
              u.put('Email',email);
              u.FirstName = firstname;
              u.LastName = lastname;
      				u.CommunityNickname = communityNickname;
              u.Phone = contactNumber;
              u.CompanyName = companyName;
      				password = null;

      				// Insert the Portal User
      				String userId = Site.createPortalUser(u, accountId, password);

      				// Validate User Creation
      				if (userId != null) {
  				      // Redirect to Activate your account Page.
                ApexPages.PageReference confirmRef = new PageReference(regConfirmUrl);
                aura.redirect(confirmRef);
	            } else
      	        return null;
      			}
            // Processing Complete.
            return pageResponse;
        }
        catch (Exception ex) {
          Database.rollback(sp);
			    pageResponse.ResponseCode = 0;
			    pageResponse.Message = ex.getMessage();
			    return pageResponse;
        }
    }
}