/******************************************************
 *  bg_FrameworkForecastViewController_test
 *
 *  Test class bg_FrameworkForecastViewController
 *
 *  Author: James Burgess - BrightGen Ltd
 *  Date:   18/09/2017
 *  Changes:
 *
 ******************************************************/
@isTest
private class bg_FrameworkForecastViewController_test {

	private static List<Master_Framework__c> testFrameworks;
	private static List<Framework_Forecast__c> testFrameworkForecasts;
	private static List<Framework_Forecast_Year__c> testFrameworkForecastYears;

	/*
	*	Data setup method for the test class, filling data out on the above variables
	*/
	private static void SetupData()
	{
		testFrameworks = new List<Master_Framework__c>();
		testFrameworkForecasts = new List<Framework_Forecast__c>();
		testFrameworkForecastYears = new List<Framework_Forecast_Year__c>();

		for(Integer i = 0; i < 5; i++)
		{
			Master_Framework__c fw = UnitTestDataFactory.createMasterFramework();
			fw.Name += ' ' + i;
			testFrameworks.add(fw);
		}
		
		insert testFrameworks;

		String testYear = UnitTestHelper.getSelectedDate();

		for(Master_Framework__c fw : testFrameworks)
		{
			testFrameworkForecasts.add(UnitTestDataFactory.createFrameworkForecast(fw.Id, testYear));
		}
		
		insert testFrameworkForecasts;

		for(Framework_Forecast__c fwf : testFrameworkForecasts)
		{
			testFrameworkForecastYears.addAll(UnitTestHelper.createAllFrameworkForecastYears(fwf.Id));
		}
		insert testFrameworkForecastYears;
	}

	private static testMethod void TestGetFrameworkSetController()
	{
		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);

		System.runAs(testCcsSysAdmin)
		{
			SetupData();
            ApexPages.StandardSetController stdSetCntl = new ApexPages.StandardSetController(testFrameworkForecasts);
			Test.setCurrentPageReference(new PageReference('Page.bg_FrameworkForecastView'));
			bg_FrameworkForecastViewController testCntrl = new bg_FrameworkForecastViewController(stdSetCntl);

		    ApexPages.StandardSetController testResult = testCntrl.GetFrameworkSetController();
			System.assertEquals(testFrameworkForecasts.size(), testResult.getRecords().size());
			Set<Id> testFrameworkForecastIds = new Map<Id, Framework_Forecast__c>(testFrameworkForecasts).keySet();
			for(SObject fwfResult : testResult.getRecords())
			{
				System.assert(testFrameworkForecastIds.contains(fwfResult.Id));
			}
		}
	}

	private static testMethod void TestGetSetListView()
	{
		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);

		System.runAs(testCcsSysAdmin)
		{
			
            SetupData();
            ApexPages.StandardSetController stdSetCntl = new ApexPages.StandardSetController(testFrameworkForecasts);
			Test.setCurrentPageReference(new PageReference('Page.bg_FrameworkForecastView'));
			bg_FrameworkForecastViewController testCntrl = new bg_FrameworkForecastViewController(stdSetCntl);

			testCntrl.GetFrameworkSetController();

			//Confirm the list view is initially empty, before setting the value and confirm the getter returns the expected
			String testResult = testCntrl.GetListViewId();
			System.assertNotEquals(null, testResult);

			testCntrl.SetListViewId('test');
			testResult = testCntrl.GetListViewId();
			System.assertEquals('test', testResult);

			//Try now by setting the list view id before retrieving
			testCntrl = new bg_FrameworkForecastViewController(stdSetCntl);

			testCntrl.GetFrameworkSetController();
			testCntrl.SetListViewId('test');
			testResult = testCntrl.GetListViewId();
			System.assertEquals('test', testResult);
		}
	}

	private static testMethod void TestPopulateRecords()
	{
		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);

		System.runAs(testCcsSysAdmin)
		{
			SetupData();
            ApexPages.StandardSetController stdSetCntl = new ApexPages.StandardSetController(testFrameworkForecasts);
			Test.setCurrentPageReference(new PageReference('Page.bg_FrameworkForecastView'));
			bg_FrameworkForecastViewController testCntrl = new bg_FrameworkForecastViewController(stdSetCntl);

			Set<Id> testFrameForecastIdResults = testCntrl.GetFrameworkIds();
			System.assertEquals(testFrameworkForecasts.size(), testFrameForecastIdResults.size());

			for(Framework_Forecast__c fwf : testFrameworkForecasts)
			{
				System.assert(testFrameForecastIdResults.contains(fwf.Id));
			}

			//Business logic dictates that there should only be 5 years in the forecast
			List<String> testBusinessYearResults = testCntrl.GetBusinessYears();
			System.assertEquals(5, testFrameForecastIdResults.size());

			testCntrl.PopulateRecords();

			//Loop through the business years and confirm that each is in the map
			//And that the list contains a record for each frameworkForecast
			for(String testResultBy : testBusinessYearResults)
			{
				System.assert(testCntrl.wpsForecastYearByBY.containsKey(testResultBy));
				System.assert(testCntrl.cgForecastYearByBY.containsKey(testResultBy));

				for(Id testFrameworkForecastId : testFrameForecastIdResults)
				{
					Boolean wpsContains = false;
					Boolean cgContains = false;
					for(ForecastYearStyleWrapper testWrap : testCntrl.wpsForecastYearByBY.get(testResultBy))
					{
						wpsContains = (testWrap.ffy.Forecast__c == testFrameworkForecastId);

						if(wpsContains)
						{
							break;
						}
					}
					System.assert(wpsContains);

					for(ForecastYearStyleWrapper testWrap : testCntrl.cgForecastYearByBY.get(testResultBy))
					{
						cgContains = (testWrap.ffy.Forecast__c == testFrameworkForecastId);

						if(cgContains)
						{
							break;
						}
					}
					System.assert(cgContains);
				}
			}
		}
	}

	private static testMethod void TestAcknowledgeYear()
	{
		User testCcsSysAdmin = UnitTestDataFactory.createUserSystemAdmin(unitTestDataFactory.PROFILE_CCS_SYSTEM_ADMIN);

		System.runAs(testCcsSysAdmin)
		{
			SetupData();
            	
            
            for(Framework_Forecast_Year__c testFfy : testFrameworkForecastYears)
		{
			testFfy.M01__c = 100;
			testFfy.M02__c = 200;
			testFfy.M05__c = 500;
		}

		update testFrameworkForecastYears;

		Map<Id, Framework_Forecast_Year__c> testFfyById = new Map<Id, Framework_Forecast_Year__c>(testFrameworkForecastYears);
            ApexPages.StandardSetController stdSetCntl = new ApexPages.StandardSetController(testFrameworkForecasts);
			Test.setCurrentPageReference(new PageReference('Page.bg_FrameworkForecastView'));
			bg_FrameworkForecastViewController testCntrl = new bg_FrameworkForecastViewController(stdSetCntl);
			testCntrl.GetBusinessYears();

			//Confirm that the values set above do still differ from the acknowledged
			for(String key : testCntrl.wpsForecastYearByBY.keySet())
			{
				for(ForecastYearStyleWrapper testWrap : testCntrl.wpsForecastYearByBY.get(key))
				{
					System.assertNotEquals(testWrap.ffy.M01__c, testWrap.ffy.Acknowledged_M01__c);
					System.assertNotEquals(testWrap.ffy.M02__c, testWrap.ffy.Acknowledged_M02__c);
					System.assertNotEquals(testWrap.ffy.M05__c, testWrap.ffy.Acknowledged_M05__c);
				}
				for(ForecastYearStyleWrapper testWrap : testCntrl.cgForecastYearByBY.get(key))
				{
					System.assertNotEquals(testWrap.ffy.M01__c, testWrap.ffy.Acknowledged_M01__c);
					System.assertNotEquals(testWrap.ffy.M02__c, testWrap.ffy.Acknowledged_M02__c);
					System.assertNotEquals(testWrap.ffy.M05__c, testWrap.ffy.Acknowledged_M05__c);
				}
			}

			//Acknowledge a year and confirm only that year's acknowledged values are updated
			testCntrl.acknowledgedForecastYearId = testFrameworkForecastYears.get(0).Id;
			testCntrl.AcknowledgeYear();

			for(Framework_Forecast_Year__c testResult : [SELECT Id, M01__c, M02__c, M05__c, Acknowledged_M01__c, 
																Acknowledged_M02__c, Acknowledged_M05__c
													 	 FROM	Framework_Forecast_Year__c
													 	 WHERE	Id IN :testFfyById.keySet()])
			{
				if (testResult.Id == testCntrl.acknowledgedForecastYearId)
				{
					System.assertEquals(testResult.M01__c, testResult.Acknowledged_M01__c);
					System.assertEquals(testResult.M02__c, testResult.Acknowledged_M02__c);
					System.assertEquals(testResult.M05__c, testResult.Acknowledged_M05__c);
				}
				else
				{
					System.assertNotEquals(testResult.M01__c, testResult.Acknowledged_M01__c);
					System.assertNotEquals(testResult.M02__c, testResult.Acknowledged_M02__c);
					System.assertNotEquals(testResult.M05__c, testResult.Acknowledged_M05__c);
				}
			}
		}
	}
}