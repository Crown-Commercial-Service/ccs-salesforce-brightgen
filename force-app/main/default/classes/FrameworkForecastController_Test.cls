@isTest
private class FrameworkForecastController_Test {
    
    /* Test whether a framework manager can create a new set of live and actual forecast year records */ 
    public static testMethod void createNewFrameworkForecastYears_Test()
    {
			User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
         
		        // Create and insert a new Framework
		        Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
				
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
				 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
						
				System.runAs(testFrameworkManagerUser)
	        	{
			
				 	// Create and insert a new Framework Forecast
				 	Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
				 	insert testFrameworkForecast;
			
		         	// Set up a test pageRef
				 	Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
				 	system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
		           
		         	// Get a new instance of the Framework Forecast controller
		         	FrameworkForecastController ctrl = new FrameworkForecastController();
						
					system.assertNotEquals(null, ctrl.ffLive);
					system.assertEquals(10, ctrl.ffLive.size());
					
	         	}
    		}
    }
        
    /* Test whether new framework forecast years can be saved and that actuals records are created */
    public static testMethod void saveNewFrameworkForecastYears_Test()
    {
        	User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
         
		        // Create and insert a new Framework
		        Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
				
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
				 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
						
				System.runAs(testFrameworkManagerUser)
		        {		
						// Create and insert a new Framework Forecast
						Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
						insert testFrameworkForecast;
						
						// Set up a test pageRef
						Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
						system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
						
		                // Get a new instance of the Framework Forecast controller
		                FrameworkForecastController ctrl = new FrameworkForecastController();
						
						ctrl.saveNewForecast();
		        	 
						// Return desired records from the db for asserts
						List<Framework_Forecast_Year__c> fyLiveCgReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.liveRt AND Sector__c = 'CG' AND Forecast__c =: testFrameworkForecast.Id];
						
						List<Framework_Forecast_Year__c> fyLiveWpsReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.liveRt AND Sector__c = 'WPS' AND Forecast__c =: testFrameworkForecast.Id];
						
						List<Framework_Forecast_Year__c> fyLiveActualsReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.actualRt AND Forecast__c =: testFrameworkForecast.Id];
		        	
						// Check that 5 CG records have been created for the framework forecast
						system.assertNotEquals(null, fyLiveCgReturned);
						system.assertEquals(5, fyLiveCgReturned.size());
						
						// Check that 5 WPS records have been created for the framework forecast
						system.assertNotEquals(null, fyLiveWpsReturned);
						system.assertEquals(5, fyLiveWpsReturned.size());
						
						system.assertNotEquals(null, fyLiveActualsReturned);
						system.assertEquals(2, fyLiveActualsReturned.size());	
						
		        	}
    		}
    }
  
    /* Test whether existing framework forecast years can be loaded for editing */
    public static testMethod void loadExistingFrameworkForecastYears_Test()
    {
        	User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
         
        		// Create and insert a new Framework
       		 	Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
		
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
			 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
				insert testFrameworkForecast;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast.Id);
				insert testFrameworkForecastYearsForInsert;
				
				// Set up a test pageRef
				Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
				system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
				
			System.runAs(testFrameworkManagerUser)
        	{
                // Get a new instance of the Framework Forecast controller
                FrameworkForecastController ctrl = new FrameworkForecastController();
				
				// Return desired records from the db for asserts
				List<Framework_Forecast_Year__c> fyLiveCgReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.liveRt AND Sector__c = 'CG' AND Forecast__c =: testFrameworkForecast.Id];
				
				List<Framework_Forecast_Year__c> fyLiveWpsReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.liveRt AND Sector__c = 'WPS' AND Forecast__c =: testFrameworkForecast.Id];
				
				List<Framework_Forecast_Year__c> fyBudgetReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.budgetRt AND Forecast__c =: testFrameworkForecast.Id];
				
				List<Framework_Forecast_Year__c> fyActualsReturned = [SELECT ID FROM Framework_Forecast_Year__c WHERE RecordTypeId =: ctrl.actualRt AND Forecast__c =: testFrameworkForecast.Id];
				
				// Check that forecast years have been found for the framework forecast
				system.assertNotEquals(ctrl.hasForecastYears, false);
				
				// Check that 5 CG records have been created for the framework forecast
				system.assertNotEquals(null, fyLiveCgReturned);
				system.assertEquals(5, fyLiveCgReturned.size());
				
				// Check that 5 CG records have been created for the framework forecast
				system.assertNotEquals(null, fyLiveWpsReturned);
				system.assertEquals(5, fyLiveWpsReturned.size());
				
				// Check that 10 budget records have been returned
				system.assertNotEquals(null, fyBudgetReturned);
				system.assertEquals(10, fyBudgetReturned.size());
				
				// Check that 2 actuals have been returned
				system.assertNotEquals(null, fyActualsReturned);
				system.assertEquals(2, fyActualsReturned.size());
				
            }
    	}
    }  
        
    /* Test whether framework forecast years can be edited and saved by a framework manager */
    public static testMethod void saveFrameworkForecastYears_Test() 
    {	
    		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
         
        		// Create and insert a new Framework
        		Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
		
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
		 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
				insert testFrameworkForecast;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast.Id);
				insert testFrameworkForecastYearsForInsert;
				
				// Set up a test pageRef
				Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
				system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
				
				System.runAs(testFrameworkManagerUser)
        		{
                	// Get a new instance of the Framework Forecast controller
                	FrameworkForecastController ctrl = new FrameworkForecastController();
				
					// Check that forecast years have been found for the framework forecast
					system.assertNotEquals(ctrl.hasForecastYears, false);
				
					ctrl.saveForecast();
            	}
    		}
    }
    
    /* Test to see if an error message is triggered if edit page is accessed without Id */
    public static testMethod void loadEditorWithoutId_Test()
    {
        		User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
				
				// Set up a test pageRef
				Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor'));
    			
    			System.runAs(testFrameworkManagerUser)
        		{
    				// Get a new instance of the Framework Forecast controller
                	FrameworkForecastController ctrl = new FrameworkForecastController();
                	
    				List<Apexpages.Message> msgs = ApexPages.getMessages();
					boolean b = false;
					for(Apexpages.Message msg:msgs)
					{
    					if (msg.getDetail().contains(system.Label.FF_No_Framework_Forecast_Error)) b = true;
				
						system.assert(b);
        			}
   			 	}
    }
    
    /* Test whether an error is triggered when framework forecast years are saved by a non-framework owner */
    public static testMethod void saveFrameworkForecastYearsError_Test() 
    {	
    		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    		
    		User testFrameworkManagerImposter = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerImposter;
    
        	System.runAs(testCcsSysAdmin)
    		{
         
        		// Create and insert a new Framework
        		Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
		
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
		 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
				insert testFrameworkForecast;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast.Id);
				insert testFrameworkForecastYearsForInsert;
				
				// Set up a test pageRef
				Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
				system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
				
				System.runAs(testFrameworkManagerImposter)
        		{
                	// Get a new instance of the Framework Forecast controller
                	FrameworkForecastController ctrl = new FrameworkForecastController();
				
					// Check that forecast years have been found for the framework forecast
					system.assertNotEquals(ctrl.hasForecastYears, false);
				
					ctrl.saveForecast();
					
					// Check for save error page message
					List<Apexpages.Message> msgs = ApexPages.getMessages();
					boolean b = false;
					for(Apexpages.Message msg:msgs)
					{
    					if (msg.getDetail().contains(system.Label.FF_Forecast_Not_Saved_Error)) b = true;
				
						system.assert(b);
        			}
					
            	}
    		}
    }
    
    /* Test whether an error is triggered when a new set of live and actual forecast year records are saved by a non-framework owner  */
    public static testMethod void createNewFrameworkForecastYearsError_Test()
    {
        	User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    		
    		User testFrameworkManagerImposter = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerImposter;
    
        	System.runAs(testCcsSysAdmin)
    		{

		        // Create and insert a new Framework
		        Master_Framework__c testFramework = unitTestDataFactory.createMasterFramework();
				insert testFramework;
				
				Master_Framework__c testFrameworkfu = new Master_Framework__c();
				 	
				testFrameworkfu.id = testFramework.id;
				testFrameworkfu.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu;
				
				String testYear = UnitTestHelper.getSelectedDate();
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast = unitTestDataFactory.createFrameworkForecast(testFramework.Id, testYear);
				insert testFrameworkForecast;
	        	
				// Set up a test pageRef
				Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
				system.currentPageReference().getParameters().put('frameworkForecastId', testFrameworkForecast.Id);
		          
		        System.runAs(testFrameworkManagerImposter)
	        	{ 
		         	// Get a new instance of the Framework Forecast controller
		         	FrameworkForecastController ctrl = new FrameworkForecastController();
						
					ctrl.saveNewForecast();
					
					// Check for save error page message
					List<Apexpages.Message> msgs = ApexPages.getMessages();
					boolean b = false;
					for(Apexpages.Message msg:msgs)
					{
    					if (msg.getDetail().contains(system.Label.FF_Forecast_Not_Saved_Error)) b = true;
				
						system.assert(b);
        			}
					
	         	}
    		}
    }
}