/**************************************************
* bg_Freeze_Users_Operation
*
* Batch class for the freezing of users via the Freeze User controller
* Should only be invoked to freeze users who can be frozen i.e. those
* that are not CCS Admins or System Users.
*
* Test Class: bg_Freeze_Users_Controller_Test
* 
* Author : Simon Kaya
* Created: 20/12/2017
* Changes: 18/01/2019 - ADS - Case 40140 - Handle System Users which cannot be frozen
*          14/01/2019 - SSK - Case 45735 - Exclude API only profiles
**************************************************/
global class bg_Freeze_Users_Operation implements Database.Batchable<sObject>
{
    // fields   
    private final String theQuery = 'SELECT Id ' +
        'FROM UserLogin ' +
        'WHERE UserId IN (SELECT Id ' +
        'FROM User ' +
        'WHERE Id != \'' + UserInfo.getUserId() + '\' ' + // explicitly exclude the running User
        'AND Can_Freeze_User__c = TRUE ' +
        'AND Profile.PermissionsApiUserOnly != TRUE '  + //Ensure API users not frozen
        (Test.isRunningTest() ? ' AND LastName LIKE \'TestUser%\') ' : ') ') + // only include the Users created for the test
        'AND IsFrozen = false ' +
        (Test.isRunningTest() ? ' LIMIT 200' : ''); // ensure no more than one executeBatch can be called from within a test method
    
    // methods
    global Iterable<sObject> start(Database.BatchableContext BC)
    {
        return Database.query(theQuery);
    } 
    
    /* Updates the users user login record to indicate that they are frozen out.
	 * WARNING: Prevents these users being able to login until unfrozen */
    global void execute(Database.BatchableContext BC, List<UserLogin> userLogins)
    {
        System.assert(![SELECT Can_Freeze_User__c FROM User WHERE Id = :UserInfo.getUserId()].Can_Freeze_User__c, 'The running User should not be frozen');
        
        final List<UserLogin> userLoginDetails = new List<UserLogin>();
        for (UserLogin userLogin : userLogins)
        {
            userLogin.IsFrozen = true;
            userLoginDetails.add(userLogin);
        }
        
        final List<Database.SaveResult> theSaveResults = Database.update(userLoginDetails, false);
        
        for (Integer i = 0; i < theSaveResults.size(); i++)
        {
            if (!theSaveResults[i].isSuccess())
            {
                for (Database.Error err : theSaveResults[i].getErrors())
                {
                    System.debug(System.LoggingLevel.DEBUG, userLoginDetails[i].Id + ', failed to freeze: ' + err.getStatusCode() + ': ' + err.getMessage());
                }   
            }
        }
        
    } 
    
    global void finish(Database.BatchableContext BC)
    {
    }  
}