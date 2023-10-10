/*********************************************************************
 Name:  bg_FrameworkForecastViewController
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Jorge Delgado      2017-08-09       Initial version
   1.1   James Burgess      2017-09-12       Case 00030836      Update to model to view years by sector and improved error handling
   1.2   Conor Spark        2017-10-18       Case 00033037      Added totals for years, frameworks, sectors and overall
 *********************************************************************/
public with sharing class bg_FrameworkForecastViewController {

    public String acknowledgedForecastYearId { get; set; }
    public Map<String, List<ForecastYearStyleWrapper>> wpsForecastYearByBY {get; set;} //Wider-public Sector
    public Map<String, List<ForecastYearStyleWrapper>> cgForecastYearByBY {get; set;} //Central Government

    public List<String> businessYears;
    public Map<String, Decimal> yearTotalsDec{get; set;}
    public Map<String, String> yearTotals{get; set;}
    public Map<String, Decimal> cgTotalsDec{get; set;}
    public Map<String, String> cgTotals{get; set;}
    public Map<String, Decimal> wpsTotalsDec{get; set;}
    public Map<String, String> wpsTotals{get; set;}
    public List<Decimal> yearTotalsListDec {get; set;}
    public List<String> yearTotalsList {get; set;}
    public String overallTotal {get; set;}
    public Decimal overallTotalDec {get; set;}
    public String listViewId;
    public ApexPages.StandardSetController frameworkSetController;

    private Map<Id, Framework_Forecast_Year__c> forecastYearMapInMemory;
    private List<Framework_Forecast_Year__c> cachedForecastYears;
    private Set<Id> frameworkIds;

    /*
    *   Constructor, empty for the moment
    */
    public bg_FrameworkForecastViewController(ApexPages.StandardSetController controller) {

    }

    /*
    *   Getter method sets up set controller
    */
    public ApexPages.StandardSetController GetFrameworkSetController()
    {
        if (frameworkSetController == null)
        {
            frameworkSetController = new ApexPages.StandardSetController([SELECT Name FROM Framework_Forecast__c]);
            frameworkSetController.setFilterId(GetListViewId());
        }
        return frameworkSetController;
    }


    /*
    *   Getter and setter methods for listViewId
    */
    public String GetListViewId()
    {
        if (listViewId == null)
        {
            listViewId = frameworkSetController.getListViewOptions().get(0).getValue();
        }
        return listViewId;
    }

    public void SetListViewId(String value)
    {
        listViewId = value;
    }

    public PageReference ClearValues()
    {
        businessYears = null;
        cachedForecastYears = null;
        frameworkIds = null;
        System.debug(LoggingLevel.Error, '***JB*** Changing List View');
        System.debug(LoggingLevel.Error, '***JB*** listViewId: ' + listViewId);
        return null;
    }

    /*
    *   If the businessYears variable is empty, use PopulateRecords to get all of our
    *   variables setup
    */
    public List<String> GetBusinessYears()
    {
        if (businessYears == null)
        {
            businessYears = new List<String>();
            PopulateRecords();
        }
        return businessYears;
    }

    /*
    *   Sets the filter for the set controller (taken from the page) and gets the framework
    *   Ids corresponding to this list view
    */
    public Set<Id> GetFrameworkIds()
    {
        System.debug(LoggingLevel.Error, '***JB*** listViewId: ' + listViewId);
        if (frameworkIds == null)
        {
            GetFrameworkSetController().setFilterId(listViewId);
            frameworkIds = new Map<Id, Framework_Forecast__c>((List<Framework_Forecast__c>)frameworkSetController.getRecords()).keySet();
        }
        System.debug(LoggingLevel.Error, '***JB*** frameworkIds: ' + frameworkIds);
        return frameworkIds;
    }

    /*
    *   Initialises the required variables and queries the database for all records matching the framework
    *   Ids in the list view filter set. Loops through these, splitting by sector and then mapping a list
    *   of wrapped forecast frameworks by the relative business year. You'll end up with a list of wrapped
    *   forecasts for a framework for each business year. The wrapper sets the style class for each set of
    *   current/acknowledged values
    */
    public void PopulateRecords()
    {
        //Initialise framework forecast year maps
        wpsForecastYearByBY = new Map<String, List<ForecastYearStyleWrapper>>();
        cgForecastYearByBY = new Map<String, List<ForecastYearStyleWrapper>>();
        forecastYearMapInMemory = new Map<Id, Framework_Forecast_Year__c>();
        yearTotals = new Map<String,String>();
        yearTotalsDec = new Map<String,Decimal>();
        cgTotals = new Map<String,String>();
        cgTotalsDec = new Map<String,Decimal>();
        wpsTotals = new Map<String,String>();
        wpsTotalsDec = new Map<String,Decimal>();
        businessYears = new List<String>();
        overallTotalDec = 0.00;
        overallTotal = convertDecimalToCurrency(overallTotalDec);


        //Query and loop through framework forecast years, checking for the sector and mapping by business year
        for(Framework_Forecast_Year__c ffy : GetRecords(GetFrameworkIds()))
        {

            Decimal currYearTotal = 0.00;
            Decimal currCgSectorTotal = 0.00;
            Decimal currWpsSectorTotal = 0.00;
            //Save to memory map, for us in update later
            forecastYearMapInMemory.put(ffy.Id, ffy);

            //Initialise list for business year if not already there
            if (!wpsForecastYearByBY.containsKey(ffy.Actual_Forecast_Year__c))
            {
                businessYears.add(ffy.Actual_Forecast_Year__c);
                wpsForecastYearByBY.put(ffy.Actual_Forecast_Year__c, new List<ForecastYearStyleWrapper>());
                cgForecastYearByBY.put(ffy.Actual_Forecast_Year__c, new List<ForecastYearStyleWrapper>());
            }

            //Check the sector and assign to the correct map
            if (ffy.Sector__c == Label.FF_Sector_WPS)
            {
                List<ForecastYearStyleWrapper> listToUpdate = wpsForecastYearByBY.get(ffy.Actual_Forecast_Year__c);
                ForecastYearStyleWrapper fysw =  new ForecastYearStyleWrapper (ffy);
                currYearTotal+=fysw.currTotal;
                currWpsSectorTotal+=fysw.currTotal;
                listToUpdate.add(fysw);
                if (wpsTotalsDec.get(ffy.Actual_Forecast_Year__c) > 0.0) currWpsSectorTotal +=wpsTotalsDec.get(ffy.Actual_Forecast_Year__c);
                wpsTotalsDec.put(ffy.Actual_Forecast_Year__c, currWpsSectorTotal.setScale(2));
                wpsTotals.put(ffy.Actual_Forecast_Year__c, convertDecimalToCurrency(currWpsSectorTotal.setScale(2)));

            }
            else
            {
                List<ForecastYearStyleWrapper> listToUpdate = cgForecastYearByBY.get(ffy.Actual_Forecast_Year__c);
                ForecastYearStyleWrapper fysw =  new ForecastYearStyleWrapper (ffy);
                currCgSectorTotal+=fysw.currTotal;
                currYearTotal+=fysw.currTotal;
                listToUpdate.add(fysw);
                if (cgTotalsDec.get(ffy.Actual_Forecast_Year__c) > 0.0) currCgSectorTotal +=cgTotalsDec.get(ffy.Actual_Forecast_Year__c);
                cgTotalsDec.put(ffy.Actual_Forecast_Year__c, currCgSectorTotal.setScale(2));
                cgTotals.put(ffy.Actual_Forecast_Year__c, convertDecimalToCurrency(currCgSectorTotal.setScale(2)));

            }
            if (yearTotalsDec.get(ffy.Actual_Forecast_Year__c) > 0.0) currYearTotal +=yearTotalsDec.get(ffy.Actual_Forecast_Year__c);
            yearTotalsDec.put(ffy.Actual_Forecast_Year__c, currYearTotal.setScale(2));
            yearTotals.put(ffy.Actual_Forecast_Year__c, convertDecimalToCurrency(currYearTotal.setScale(2)));
            overallTotalDec += currYearTotal.setScale(2);
        }
        overallTotal = convertDecimalToCurrency(overallTotalDec);
    }

    /*
    *   Convert a decimal to a string in currency format (1000.00 becomes 1,000.00)
    */
    public String convertDecimalToCurrency(Decimal dec){
        String amount;
        if (!string.valueof(dec.format()).right(3).contains('.')){
            amount = string.valueof(dec.format()) + '.00';
        }else if (string.valueof(dec.format()).right(2).contains('.')){
            amount = string.valueof(dec.format()) + '0';
        }else {
            amount = string.valueof(dec.format());
        }

        return amount;
    }

    /*
    *   Cache the forecast year records, for re-use later
    */
    public List<Framework_Forecast_Year__c> GetRecords(Set<Id> frameworksToMatch)
    {
        if (cachedForecastYears == null)
        {
            cachedForecastYears = new List<Framework_Forecast_Year__c>(
                                                [SELECT Name, M01__c, M02__c, M03__c, M04__c, M05__c, M06__c, M07__c, M08__c, M09__c, M10__c, 
                                                        M11__c, M12__c, Q1__c, Q2__c, Q3__c, Q4__c, Annual__c, Last_Acknowledged_By__c, Last_Acknowledged_Date__c,
                                                        Forecast__c, Acknowledged_M01__c, Acknowledged_M02__c, Acknowledged_M03__c, Acknowledged_M04__c,
                                                        Acknowledged_M05__c, Acknowledged_M06__c, Acknowledged_M07__c, Acknowledged_M08__c, Acknowledged_M09__c,
                                                        Acknowledged_M10__c, Acknowledged_M11__c, Acknowledged_M12__c, Acknowledged_Q1__c, Acknowledged_Q2__c,
                                                        Acknowledged_Q3__c, Acknowledged_Q4__c, Acknowledged_Annual__c, Actual_Forecast_Year__c, Sector__c, Relative_Forecast_Year__c,
                                                        Forecast__r.Framework__r.Name
                                                FROM    Framework_Forecast_Year__c
                                                WHERE   Forecast__c IN :frameworksToMatch
                                                AND     RecordType.Name = 'Live'
                                                ORDER BY Actual_Forecast_Year__c ASC, Relative_Forecast_Year__c ASC, Forecast__c ASC]);
        }
        return cachedForecastYears;
    }

    /*
    *   Called from a button on the page to set the acknowledged values to the
    *   current values, save the record and reRender the page, printing any
    *   applicable errors
    */
    public PageReference AcknowledgeYear()
    {
        Framework_Forecast_Year__c ffyToUpdate = forecastYearMapInMemory.get(acknowledgedForecastYearId);

        //Acknowledge the record selected
        FrameworkForecastUtil.SetAcknowledgedValues(ffyToUpdate);
        Database.SaveResult sr = Database.update(ffyToUpdate);

        //If the save was unsuccessful, print the error. Otherwise, reset the wrapper for this record
        if (!sr.isSuccess())
        {
            String errorMessage = 'Unable to acknowledge year. Error message: ' + sr.getErrors().get(0).getMessage();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        PopulateRecords();

        return null;
    }
}