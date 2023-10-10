@isTest
private class FrameworkBudgetButtonController_Test {
    
    /* Test to check we are retrieving picklist values for business plan years */
    public static testMethod void getBuinessPlanYearsForPicklist_Test()
    {
        User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
        
        System.runAs(testFrameworkManagerUser)
        {

                // Get a new instance of the Framework budget button controller
                FrameworkBudgetButtonController ctrl = new FrameworkBudgetButtonController();
                
                List<SelectOption> selectOptions = ctrl.getBusinessPlanYears();
                
				system.assertNotEquals(null, selectOptions);
				
          }
    }
    
    /* Test that we can successfully execute the batch class for budget creation */
    public static testMethod void CallBatchMethodFromPopup_Test()
    {
    			
    			UserRole r = new UserRole(name = 'CCS Administrator');
        		insert(r);
    			
    			User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN, r.Id);
    			
    			User testFrameworkManagerUser = UnitTestDataFactory.createUserFrameworkManager('CCS Framework Management User');
        		insert testFrameworkManagerUser;
        
	        	System.runAs(testCcsSysAdmin)
        		{
        			
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
	        		
					//Build string to simulate selecting mutiple frameworks
					String selectedFrameworksIdsTest = testFramework1.Id + ',' + testFramework2.Id;
					
					// Set up a test pageRef
					Test.setCurrentPageReference(new PageReference('Page.FrameworkForecastEditor')); 
					system.currentPageReference().getParameters().put('ids', selectedFrameworksIdsTest);
				
        		}
				
				// Get a new instance of the Framework budget button controller
                FrameworkBudgetButtonController ctrl = new FrameworkBudgetButtonController();
				
				System.runAs(testFrameworkManagerUser)
		        {	
						List<String> paramsRetrieved = ctrl.selectedFrameworkIds;
						// Make sure that we have values passed as parmeters
						system.assertNotEquals(null, ctrl.selectedFrameworkIds);
						system.assertEquals(2, paramsRetrieved.size());
		    	
		    			// Set a selected year value as if we're a picklist
		    			ctrl.selectedYear = UnitTestHelper.getSelectedDate();
		    			
		    			// Call to execute batch
		    			ctrl.createBudgetRecords();
		    			
		    			system.assertNotEquals(ctrl.showBatchExecutedMessage, false);
		    				
		        }
    }
    
}