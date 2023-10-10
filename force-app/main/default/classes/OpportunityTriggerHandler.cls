/*****************************************************************************************************************************
Name: OpportunityTriggerHandler 

Purpose: Opportunity Trigger Handler

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      06/15/2021      
1.1 -   Divya Muvvala	  10/11/2021	  US1076

*******************************************************************************************************************************/
public with sharing class OpportunityTriggerHandler {

    public OpportunityTriggerHandler() {

    }

    // Before insert Context function
    /*public void onbeforeinsert(List<Opportunity> listNewOpportunities){   
    }*/
    // After Insert Context function
    public void OnAfterInsert(List<Opportunity> listNewOpportunities)
    {
        OpportunityService.CreateMonthlyValues(listNewOpportunities, null);
    }
    // Before update Context function
    /*public void onbeforeupdate(List<Opportunity> listNewOpportunities, List<Opportunity> listOldOpportunities){   
    
    }*/
    // After Update Context function
    public void onAfterUpdate(List<Opportunity> listNewOpportunities, Map<Id,Opportunity> mapOldOpportunities){   
        if(!OpportunityService.isRunning){
            OpportunityService.isRunning = true;
            
            //get newOpp value_ownership__c value
            Boolean ownerValue = false;
            
            for(Opportunity newOpp: listNewOpportunities){
                ownerValue = newOpp.Value_Ownership__c;
            }
            
            //check if value_ownership__c is false
            if(!ownerValue){
       			OpportunityService.CreateMonthlyValues(listNewOpportunities, mapOldOpportunities);     
            }
                OpportunityService.isRunning = false;
        }
       
    }
    // Bwfore Delete Context function
    /*public void onBeforeDelete(List<Opportunity> listOldOpportunities){  
        
    }*/
}