/**
 * Author: Simon Kaya
 * Controller class for the Freeze users UI, queries the frozen users to 
 * be displayed and executes the batch job to freeze/unfreeze.
 * Changes: 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
 */
public class bg_Freeze_Users_Controller {
	private static final String freezeId = '01p0N000004xist'; 
	private static final String unfreezeId = '01p0N000004xisu';
	private bg_Freeze_Users_Operation freezeOpt;
	private bg_Unfreeze_Users_Operation unfreezeOpt;
	
   	public transient List<User> displayUsers {get; set;}
   	public Integer rowLimit {get; set;}			//Amount of records to display on list
    public Integer currentIndex {get; set;}		//Used for page's user print out   	
   	public Boolean action {get; set;}
   	public Integer unfrozenSize {get; set;}		//VF information
   	public Integer displaySize {get; set;}
   	
   	public bg_Freeze_Users_Controller()
   	{	
   		currentIndex = 0;
   		rowLimit = 100;
   		
   		getUnfrozenUsersSize();
   		getDisplayRecords();
   		
   		freezeOpt = new bg_Freeze_Users_Operation();
   		unfreezeOpt = new bg_Unfreeze_Users_Operation();
   		
   		action = jobsAlreadyRunning()? true : false;
   	}
   	
   	/* Sets the size of the unfrozen users for the visual force page*/
   	public void getUnfrozenUsersSize()
   	{	
   		unfrozenSize = database.countQuery('SELECT COUNT() FROM UserLogin WHERE IsFrozen = false AND UserId IN (SELECT Id FROM User WHERE Can_Freeze_User__c = true)');
   	}
   	
   	/* Returns a list of users not frozen limited to the page size. Then sets the display size of the users
   	 * not not frozen for the visual force page*/
   	private void getDisplayRecords()
   	{	
   		Set<ID> unfrozenUsers = getUsersIdByLogin(false);
   		displayUsers = [SELECT Name, Email, Profile.Name FROM User WHERE Id IN :unfrozenUsers ORDER BY Username LIMIT :rowLimit OFFSET :currentIndex];
   		displaySize = displayUsers.size();
   	}
   	
   	/*Moves the display list onto the next page of records from unfrozen list*/
   	public PageReference next()
   	{   		
   		getUnfrozenUsersSize();
   		if(currentIndex+rowLimit >= unfrozenSize)
   		{
   			currentIndex = unfrozenSize-rowLimit < 0? 0 : unfrozenSize-rowLimit;
   		}
   		else currentIndex += rowLimit;
   		
   		getDisplayRecords();
   		return null;
   	}
   	
   	/* Moves the display list to the previous page of records from unfrozen list*/
   	public PageReference back()
   	{
		currentIndex = currentIndex-rowLimit < 0? 0 : currentIndex-rowLimit; //Don't allow negative index
		getDisplayRecords();
		return null;
   	}
   	
	/*Initialise batch class to freeze users, if a previous batch job is running
	 * retun null to prevent duplicate jobs.*/
	public PageReference freezeUsers(){
		if(jobsAlreadyrunning()) return null;
		
		action = true;
   		ID batchprocessid = Database.executeBatch(freezeOpt);
   		return null;
   	}
   	
   	/*Initialise batch class to unfreeze users, if a previous batch job is running
	 * retun null to prevent duplicate jobs.*/
   	public PageReference unfreezeUsers(){
		if(jobsAlreadyRunning()) return null;
		
		action = true;
		ID batchprocessid = Database.executeBatch(unfreezeOpt);
		return null; 
   	}
   	
   	/*Determines if any previous batch jobs are running for freezing/unfreezing users*/
   	public Boolean jobsAlreadyRunning()
   	{
   		
   		String Query ='SELECT ApexClassID, Status FROM AsyncApexJob WHERE (ApexClassID = \''+
   			 freezeId+'\' OR ApexClassID = \''+unfreezeId+'\')';   			 
   			 AsyncApexJob[] jobs = Database.query(query);

		for(AsyncApexJob job : jobs)
		{
			if(job.Status != 'Completed') return true;
		}		

		return false;
   	}
   	
   	/* Returns a set of user ID's that are frozen or not depending on the argument specified*/
   	public set<ID> getUsersIdByLogin(Boolean frozen)
   	{
   		set<ID> userLoginId = new set<ID>();
   		for(UserLogin login : [SELECT Id, UserId FROM UserLogin WHERE IsFrozen =: frozen AND UserId IN (SELECT Id FROM User WHERE Can_Freeze_User__c = true)])
   		{
   			userLoginId.add(login.UserId);
   		}
   		
   		return userLoginId;
   	}
   	
   	public bg_Unfreeze_Users_Operation getUnfreezeOpt()
   	{
   		return unfreezeOpt;
   	}
   	
    // 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen

    /*
   	public bg_Freeze_Users_Operation getFreezeOpt()
   	{
   		return freezeOpt;
   	}
    */
}