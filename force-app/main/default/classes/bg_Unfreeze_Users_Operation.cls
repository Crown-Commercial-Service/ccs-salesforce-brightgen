/**
 * Author: Simon Kaya
 * Batch class for the unfreezing of users via the Freeze User controller
 * Should only be invoked to unfreeze users where not previously frozen
 * Changes: 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
 */
global class bg_Unfreeze_Users_Operation implements Database.Batchable<sObject>{
    private Boolean isTest = false;
    
    global Iterable<sObject> start(Database.BatchableContext BC)
    {
    		List<User> usersToUnfreeze = [SELECT Id, WasFrozen__c FROM User WHERE WasFrozen__c = false AND Can_Freeze_User__c = true];
    		if(isTest)
    		{
    			 usersToUnfreeze = [SELECT id, LastName, WasFrozen__c FROM User WHERE WasFrozen__c = false AND LastName LIKE 'TestUser%'];
    			 return [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE UserId IN :usersToUnfreeze LIMIT 200];
    		} 
    		return [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE UserId IN : usersToUnfreeze];
    }
    
    /*Unfreezes the accounts*/
    global void execute(Database.BatchableContext BC, List<UserLogin> credentials)
    {
		for(Integer i = 0; i < credentials.size(); i++)
		{
			credentials[i].IsFrozen = false;
		}
		update credentials;
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
    
    public void setIsTest(Boolean isTest)
    {
    		this.isTest = isTest;
    }
}