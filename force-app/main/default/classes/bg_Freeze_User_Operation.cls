/**
 * Author: Simon Kaya
 * Batch class for the freezing of users via the Freeze User controller
 * Should only be invoked to freeze users who are not CCS Admins.*/
global class bg_Freeze_User_Operation implements Database.Batchable<sObject>{
    public boolean isTest = false;
    
    global Iterable<sObject> start(Database.BatchableContext BC)
    {
		List<User> admins = [SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'CCS System Administrator'];
		
		if(isTest)
		{
			return [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE UserId NOT IN : admins LIMIT 200];
		}
		
		return [SELECT Id, UserId, IsFrozen FROM UserLogin WHERE UserId NOT IN : admins];
    }
    
    /*Freezes the accounts*/
    global void execute(Database.BatchableContext BC, List<UserLogin> accounts)
    {
    		List<UserLogin> userLoginDetails = new List<UserLogin>();
    		for(UserLogin user : accounts)
    		{
    			user.IsFrozen = true;
    			userLoginDetails.add(user);
    		}
    		update userLoginDetails;
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
}