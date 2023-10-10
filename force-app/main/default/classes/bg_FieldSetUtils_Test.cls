/******************************************************
 *  bg_FieldSetUtils_Test
 *
 *  Test class bg_FieldSetUtils
 *
 *  Author: James Burgess - BrightGen Ltd
 *  Date:   18/09/2017
 *  Changes:
 *
 ******************************************************/
@isTest
public class bg_FieldSetUtils_Test {

    private static testMethod void TestGetFieldSet()
    {
        List<String> objects = new List<String>{'Framework_Forecast_Year__c'};
        Schema.FieldSet forecastFrameworkYearFieldSet = Schema.describeSObjects(objects).get(0).FieldSets.getMap().values().get(0);
        List<Schema.FieldSetMember> testResults = bg_FieldSetUtils.GetFieldSet(objects.get(0), forecastFrameworkYearFieldSet.getName());
        System.assertEquals(testResults.size(), forecastFrameworkYearFieldSet.getFields().size());
        System.assert(bg_FieldSetUtils.fieldSetMapByObjectName.containsKey('Framework_Forecast_Year__c'));
        System.assert(bg_FieldSetUtils.fieldSetMapByObjectName.values().get(0).containsKey(forecastFrameworkYearFieldSet.getName()));
    }
}