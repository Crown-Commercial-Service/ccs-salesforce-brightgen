@isTest
private class FrameworkForecastYearBudget_Batch_Test {
	
    /* Test that we can successfully execute the batch class for budget creation */
    public static testMethod void executeBatchMethod_Test()
    {
            	
        	UserRole r = new UserRole(name = 'CCS Administrator');
    		insert(r);
			
			User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN, r.Id);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
        	
            	// Get useful record type Ids by name
            	Map<String,Id> ffYearRecordTypes = FrameworkForecastUtil.GetRecordTypeIdsByDeveloperName(Framework_Forecast_Year__c.SObjectType);
				String liveRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Live); 
            	String budgetRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Budget);
				String testYear = UnitTestHelper.getSelectedDate();
         
        		// Create and insert a new Framework
                Master_Framework__c testFramework1 = unitTestDataFactory.createMasterFramework();
				insert testFramework1;
				
				//Create a second Framework
				Master_Framework__c testFramework2 = unitTestDataFactory.createMasterFramework();
				insert testFramework2;
				
				// Change user to Framework User for 1
				Master_Framework__c testFrameworkfu1 = new Master_Framework__c();
		 	
				testFrameworkfu1.id = testFramework1.id;
				testFrameworkfu1.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu1;
				
				// Change user to Framework User for 2
				Master_Framework__c testFrameworkfu2 = new Master_Framework__c();
				
				testFrameworkfu2.id = testFramework2.id;
				testFrameworkfu2.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu2;
			
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast1 = unitTestDataFactory.createFrameworkForecast(testFramework1.Id, testYear);
				insert testFrameworkForecast1;
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast2 = unitTestDataFactory.createFrameworkForecast(testFramework2.Id, testYear);
				insert testFrameworkForecast2;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert1 = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast1.Id);
				insert testFrameworkForecastYearsForInsert1;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert2 = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast2.Id);
				insert testFrameworkForecastYearsForInsert2;
				
				//Build string to simulate selecting mutiple frameworks
				String[] selectedFrameworksIdsTest = new String[]{testFramework1.Id,testFramework2.Id};
				
            	String[] frameworkForecastIdsTest = new String[]{testFrameworkForecast1.Id, testFrameworkForecast2.Id};
    		
    		
    		System.runAs(testFrameworkManagerUser)
	        {   
	    			test.startTest();
	    			FrameworkForecastYearBudget_Batch createBudgetBatch = new FrameworkForecastYearBudget_Batch(selectedFrameworksIdsTest, testYear);
					Database.executeBatch(createBudgetBatch);
	    			test.stopTest();
	    			
	    			List<Framework_Forecast_Year__c> ffyBudget = [SELECT ID FROM Framework_Forecast_Year__c WHERE Forecast__c in: frameworkForecastIdsTest AND RecordTypeId =: createBudgetBatch.budgetRt];
	    			system.assertNotEquals(null,ffyBudget);
	    			system.assertNotEquals(null,ffyBudget);
	        }
    		
    		}
        	
    } 
    
    /* Test that we can successfully execute the batch class for budget creation */
    public static testMethod void executeBatchMethodError_Test()
    {
    	  	UserRole r = new UserRole(name = 'CCS Administrator');
    		insert(r);
			
			User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN, r.Id);
			
			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
    		insert testFrameworkManagerUser;
    
        	System.runAs(testCcsSysAdmin)
    		{
    	  		
    	  		// Get useful record type Ids by name
            	Map<String,Id> ffYearRecordTypes = FrameworkForecastUtil.GetRecordTypeIdsByDeveloperName(Framework_Forecast_Year__c.SObjectType);
				String liveRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Live); 
            	String budgetRt = ffYearRecordTypes.get(system.Label.FF_Record_Type_Budget);
				String testYear = UnitTestHelper.getSelectedDate();
				
				
        		// Create and insert a new Framework
                Master_Framework__c testFramework1 = unitTestDataFactory.createMasterFramework();
				insert testFramework1;
				
				//Create a second Framework
				Master_Framework__c testFramework2 = unitTestDataFactory.createMasterFramework();
				insert testFramework2;
				
				// Change user to Framework User for 1
				Master_Framework__c testFrameworkfu1 = new Master_Framework__c();
		 	
				testFrameworkfu1.id = testFramework1.id;
				testFrameworkfu1.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu1;
				
				// Change user to Framework User for 2
				Master_Framework__c testFrameworkfu2 = new Master_Framework__c();
				
				testFrameworkfu2.id = testFramework2.id;
				testFrameworkfu2.ownerId = testFrameworkManagerUser.id;
				update testFrameworkfu2;
			
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast1 = unitTestDataFactory.createFrameworkForecast(testFramework1.Id, testYear);
				insert testFrameworkForecast1;
				
				// Create and insert a new Framework Forecast
				Framework_Forecast__c testFrameworkForecast2 = unitTestDataFactory.createFrameworkForecast(testFramework2.Id, testYear);
				insert testFrameworkForecast2;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert1 = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast1.Id);
				insert testFrameworkForecastYearsForInsert1;
				
				List<Framework_Forecast_Year__c> testFrameworkForecastYearsForInsert2 = UnitTestHelper.createAllFrameworkForecastYears(testFrameworkForecast2.Id);
				insert testFrameworkForecastYearsForInsert2;
				
				//Build string to simulate selecting mutiple frameworks
				String[] selectedFrameworksIdsTest = new String[]{testFramework1.Id,testFramework2.Id};
				
            	String[] frameworkForecastIdsTest = new String[]{testFrameworkForecast1.Id, testFrameworkForecast2.Id};
    		
    		System.runAs(testFrameworkManagerUser)
       		{
    			test.startTest();
    			FrameworkForecastYearBudget_Batch createBudgetBatch = new FrameworkForecastYearBudget_Batch(selectedFrameworksIdsTest, testYear);
				createBudgetBatch.callException('An error has occurred');
    			test.stopTest();
    			
    			List<Exception_Log__c> exceptionLogs = [
					SELECT Id, Class_Name__c, Method_Name__c 
					FROM Exception_Log__c
					WHERE Running_User__c =: UserInfo.getUserId()
				];
				
				for(Exception_Log__c el : exceptionLogs) 
				{
					System.assertEquals(FrameworkForecastYearBudget_Batch.class.toString(), el.Class_Name__c, 'Exception should be generated by Batch Class');
				}
       		}
    		
    		
    	}
    			
    	  	
    } 
    
}