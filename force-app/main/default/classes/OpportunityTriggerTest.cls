@isTest
public with sharing class OpportunityTriggerTest {
    
    @isTest
    public static void monthlyValuesTest(){
        Account acc = new Account();
        acc.Name = 'Org Name';

        insert acc;
        Opportunity tempOpp = new Opportunity();
        tempOpp.Name = 'EG Data Testing';
        tempOpp.AccountId = acc.Id;
        tempOpp.CloseDate = System.Today();
        tempOpp.Contract_Close_Date__c = System.Today().addMonths(3);
        tempOpp.StageName = 'Stage 0 = Need Identified';
        tempOpp.Amount = 10000;
        tempOpp.Value_Ownership__c = false;
        tempOpp.LeadSource = 'Category';

        insert tempOpp;
        System.assert(tempOpp.Id != null, 'Opportunity Not Created');
        
        tempOpp.Contract_Close_Date__c = System.Today().addMonths(4);
        tempOpp.StageName = 'Stage 1 = Solution Available';
        update tempOpp;
        
        OpportunityService.isRunning = false;
        //tempOpp.Parent_Opportunity__c = true;
        update tempOpp;
        
    }
}