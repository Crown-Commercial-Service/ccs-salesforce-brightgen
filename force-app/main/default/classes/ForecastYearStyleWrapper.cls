/******************************************
 *  ForecastYearStyleWrapper
 *
 *  Wrapper class to hold the Framework_Forecast_Year__c record and a map
 *  holding the style class for each relevant field
 *
 *  Author: James Burgess - BrightGen Ltd
 *  Date:   19/09/2017
 *  Changes:
 *
 ******************************************/
public class ForecastYearStyleWrapper
{
    public Framework_Forecast_Year__c ffy {get; set;}
    public Map<String, String> classByField {get; set;}
    public Boolean showAckButton {get; set;}
    public Decimal prevTotal {get; set;}
    public Decimal currTotal {get; set;}

    public ForecastYearStyleWrapper(Framework_Forecast_Year__c record)
    {
        //Assign the given record to wrapper variable and default Boolean to false
        ffy = record;
        showAckButton = false;
        classByField = new Map<String, String>();
        prevTotal = 0.00;
        prevTotal.setScale(2);
        currTotal = 0.00;
        currTotal.setScale(2);

        //Get the field sets
        List<Schema.FieldSetMember> currentFields = FrameworkForecastUtil.GetCurrentForecastFieldSets();
        List<Schema.FieldSetMember> previousFields = FrameworkForecastUtil.GetAcknowledgedForecastFieldSets();

        //Loop through field sets, checking to see if the values differ and mapping the relevant style class for each scenario
        for(Integer i = 0; i < currentFields.size(); i++)
        {
            //Query out the field sets - assumption that they match in length
            String currField = currentFields.get(i).getFieldPath();
            String prevField = previousFields.get(i).getFieldPath();

            classByField.put(currField, '');
            classByField.put(prevField, '');

            if (ffy.get(currField) != null &&
                ffy.get(prevField) != null)
            {
                prevTotal += (Decimal)ffy.get(prevField);
                currTotal += (Decimal)ffy.get(currField);
                if ((Decimal)ffy.get(prevField) > (Decimal)ffy.get(currField))
                {
                    classByField.put(currField, 'lower');
                    classByField.put(prevField, 'lower');
                }
                else if ((Decimal)ffy.get(prevField) < (Decimal)ffy.get(currField))
                {
                    classByField.put(currField, 'higher');
                    classByField.put(prevField, 'higher');
                }
            }
        }
    }
}