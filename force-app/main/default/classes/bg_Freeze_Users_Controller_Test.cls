/**
 * Author: Simon Kaya
 * Freeze users user interface test, it tests the controllers main functionality.
 * As the controller also invokes batch actions.
 * Changes: 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
 */
@isTest(SeeAllData=False)
public class bg_Freeze_Users_Controller_Test {
    private static bg_Freeze_Users_Controller ctrl;
    
    /*Initilise objects and create some dummy data. Keeps ID set of users for  test 
     * queries sets half the users grabbed as frozen out. Choose to start with users
     * frozen or not*/
    static set<ID> setup(Boolean freeze)
	{	
		Set<ID> dummyData = new Set<ID>();
    		Profile profile = [SELECT id FROM Profile WHERE Name = 'CCS Standard User'];
    		
    		//Build user data
    		List<User>dummyUsers = new List<User>();
    		for(Integer i = 0; i < 70; i++)
    		{
    			dummyUsers.add(UnitTestHelper.createUser(i, profile.id));                
    		}
    		
    		//Test admins not frozen and users already frozen stay frozen
    		dummyUsers[0].WasFrozen__c = true;
        
        	// 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
    		// dummyUsers[1].ProfileId = [SELECT id FROM Profile WHERE Name = 'CCS System Administrator'].id;    		
    		dummyUsers[1].ProfileId = [SELECT Id, ProfileId FROM User WHERE Can_Freeze_User__c = false LIMIT 1].ProfileId;
    		insert dummyUsers;
        	System.assertEquals(1, [SELECT Id FROM User WHERE Id IN :dummyUsers AND Can_Freeze_User__c = false].size(), 'There must one test User that cannot be frozen');        
            		
    		List<UserLogin> credentials = [SELECT Id, UserId FROM UserLogin WHERE UserId IN :dummyUsers LIMIT 70];
            System.debug('SIZE' + ' ' + credentials.size());
    		system.assertEquals(dummyUsers.size(), credentials.size());
    		
    		for(Integer i = 0; i < 50; i++)
    		{
    			dummyData.add(dummyUsers[i].id);	//Add newly inserted users into dummyIds for tests
    			credentials[i].IsFrozen = freeze;
    		}
    		update credentials;
		
		//Initialise last as contrusctor queries users
    		ctrl = new bg_Freeze_Users_Controller();	
    		ctrl.getUnfreezeOpt().setIsTest(true);
    		// 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
            // ctrl.getFreezeOpt().setIsTest(true);
    		
    		return dummyData;
    }
     
    /*Tests the controller turns the pages correctly. Retrieves real user data as controller
     *also uses real data, so no need for setup*/
    public static testMethod void testPageFlick()
    {
    		//Retrieve unfrozen users
    		bg_Freeze_Users_Controller ctrl = new bg_Freeze_Users_Controller();
    		Set<ID> userId = new Set<ID>();
    		for(UserLogin creds: [SELECT UserId FROM UserLogin WHERE IsFrozen = false AND UserId IN (SELECT Id FROM User WHERE Can_Freeze_User__c = true )  ])
    		{
    			userId.add(creds.UserId);
    		}
            Test.startTest();
    		List<User> dummyUsers = [SELECT id, Name, Email FROM User WHERE Id IN :userId AND  Can_Freeze_User__c = true ORDER BY Username ];
    		
    		ctrl.next(); //Flick forward
    		
    		for(Integer i = 0; i < ctrl.rowLimit && i < ctrl.displayUsers.size(); i++)
    		{	
    			system.debug(LoggingLevel.Error, 'Expected: '+dummyUsers[i + ctrl.currentIndex]+ 'Result: '+ctrl.displayUsers.get(i));
    			system.assertEquals(dummyUsers[i + ctrl.currentIndex].Name, ctrl.displayUsers.get(i).Name);
    		}
    		Test.stopTest();
    	//	ctrl.back(); //Flick back
    	
    	//	for(Integer i = 0; i < ctrl.rowLimit && i < ctrl.unfrozenSize; i++)
    	//	{
    	//		system.assertEquals(dummyUsers.get(i + ctrl.currentIndex).Name, ctrl.displayUsers.get(i).Name);
    	//	}
    }
     public static testMethod void testPageFlickBack()
    {
    		//Retrieve unfrozen users
    		bg_Freeze_Users_Controller ctrl = new bg_Freeze_Users_Controller();
    		Set<ID> userId = new Set<ID>();
    		for(UserLogin creds: [SELECT UserId FROM UserLogin WHERE IsFrozen = false AND UserId IN (SELECT Id FROM User WHERE Can_Freeze_User__c = true )  ])
    		{
    			userId.add(creds.UserId);
    		}
            Test.startTest();
    		List<User> dummyUsers = [SELECT id, Name, Email FROM User WHERE Id IN :userId AND  Can_Freeze_User__c = true ORDER BY Username ];
    		
    		
    		
    		ctrl.back(); //Flick back
    	
    		for(Integer i = 0; i < ctrl.rowLimit && i < ctrl.unfrozenSize; i++)
    		{
    			system.assertEquals(dummyUsers.get(i + ctrl.currentIndex).Name, ctrl.displayUsers.get(i).Name);
    		}
        Test.stopTest();
    }
    
    /*Test that the batch function unfreezes users, Any user who was already frozen
     * should not be unfrozen*/
    public static testMethod void testUnfreeze()
    {
    		Set<ID> dummyData = setup(true);
    		
    		Test.startTest();
    		ctrl.unfreezeUsers();
		    Test.stopTest();
		
		UserLogin[] credentials = [SELECT UserId, IsFrozen FROM UserLogin WHERE UserId IN :dummyData ORDER BY UserId];
		User[] dummyUsers = [SELECT Id, WasFrozen__c FROM User WHERE Id IN :dummyData ORDER By Id];
			
    		for(Integer i = 0; i < credentials.size(); i++)
    		{
    			system.debug(LoggingLevel.ERROR, 'Unfreeze Users =>'+dummyUsers[i] +' : '+credentials[i]);
    			system.assertEquals(dummyUsers[i].WasFrozen__c, credentials[i].IsFrozen);
    		}
    		
    }
    
    /*Test that users are frozen but system administrators are not*/
    public static testMethod void testFreeze()
    {
    		Set<ID> dummyData = setup(false);
    		
    		Test.startTest();
    		ctrl.freezeUsers();
    		Test.stopTest();
    		
    		UserLogin[] credentials = [SELECT UserId, IsFrozen FROM UserLogin WHERE UserId IN :dummyData ORDER BY UserId];
    		User[] dummyUsers = [SELECT Id, Can_Freeze_User__c, Profile.Name FROM User WHERE Id IN :dummyData ORDER By Id];
    		
    		for(Integer i = 0; i < credentials.size(); i++)
    		{
                // 18/01/2019 - ADS - Case 40140 - Handle System Accounts which cannot be frozen
    			// if(dummyUsers[i].Profile.Name == 'CCS System Administrator') system.assertEquals(false, credentials[i].IsFrozen);
    			// else system.assertEquals(true, credentials[i].IsFrozen);
                System.assertEquals(dummyUsers[i].Can_Freeze_User__c, credentials[i].IsFrozen);
    		}
    }
    
}