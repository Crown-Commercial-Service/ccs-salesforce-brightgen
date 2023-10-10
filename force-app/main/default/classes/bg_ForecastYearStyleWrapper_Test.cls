/******************************************************
 *  bg_ForecastYearStyleWrapper_Test
 *
 *  Test class for ForecastYearStyleWrapper class
 *
 *  Author: James Burgess - BrightGen Ltd
 *  Date:   20/09/2017
 *  Changes:
 *
 ******************************************************/
@isTest
private class bg_ForecastYearStyleWrapper_Test {

    private static testMethod void TestConstructor()
    {
        Framework_Forecast_Year__c testFfy = new Framework_Forecast_Year__c();
        testFfy.M01__c = 100;
		testFfy.M02__c = 200;
		testFfy.M03__c = 300;
		testFfy.M04__c = 400;
		testFfy.M05__c = 500;
		testFfy.Q4__c = 600;
		testFfy.Annual__c = 1200;
        testFfy.Acknowledged_M01__c = 200;//Lower
		testFfy.Acknowledged_M02__c = 100;//Higher
		testFfy.Acknowledged_M03__c = 100;//Higher
		testFfy.Acknowledged_M04__c = 600;//Lower
		testFfy.Acknowledged_M05__c = 500;
		testFfy.Acknowledged_Q4__c = 600;
		testFfy.Acknowledged_Annual__c = 2000;//Lower

        ForecastYearStyleWrapper testResult = new ForecastYearStyleWrapper(testFfy);

        System.assertEquals('lower', testResult.classByField.get('M01__c'));
        System.assertEquals('lower', testResult.classByField.get('Acknowledged_M01__c'));
        System.assertEquals('higher', testResult.classByField.get('M02__c'));
        System.assertEquals('higher', testResult.classByField.get('Acknowledged_M02__c'));
        System.assertEquals('higher', testResult.classByField.get('M03__c'));
        System.assertEquals('higher', testResult.classByField.get('Acknowledged_M03__c'));
        System.assertEquals('lower', testResult.classByField.get('M04__c'));
        System.assertEquals('lower', testResult.classByField.get('Acknowledged_M04__c'));
        System.assertEquals('', testResult.classByField.get('M05__c'));
        System.assertEquals('', testResult.classByField.get('Acknowledged_M05__c'));
        System.assertEquals('', testResult.classByField.get('Q4__c'));
        System.assertEquals('', testResult.classByField.get('Acknowledged_Q4__c'));
        System.assertEquals('lower', testResult.classByField.get('Annual__c'));
        System.assertEquals('lower', testResult.classByField.get('Acknowledged_Annual__c'));
    }
}