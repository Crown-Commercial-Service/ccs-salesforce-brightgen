public with sharing class OpportunityService {
    public static boolean isRunning = false;
    public static boolean isValidForMonthly(Opportunity newOpp, Opportunity oldOpp){
        boolean isAllNotNull = (newOpp.CloseDate != null && newOpp.Contract_Close_Date__c != null && newOpp.Amount != null);
        if(oldOpp != null && !newOpp.Parent_Opportunity__c && newOpp.Parent_Opportunity__c != oldOpp.Parent_Opportunity__c && isAllNotNull){
            return true;
        }
        if(newOpp.CloseDate == null || newOpp.Contract_Close_Date__c == null || newOpp.Amount == null ){
            return false;
        }else if(oldOpp != null && newOpp.CloseDate == oldOpp.CloseDate && newOpp.Contract_Close_Date__c == oldOpp.Contract_Close_Date__c && newOpp.Amount == oldOpp.Amount ){
            return false;
        }
        return true;
    }
    public static void createMonthlyRecords(List<Opportunity> oppList){
        List<Opportunity_Monthly_Value__c> annualValueListToInsert = new List<Opportunity_Monthly_Value__c>();
        for(Opportunity opp: oppList){
            Integer monthDiff = opp.CloseDate.monthsBetween(opp.Contract_Close_Date__c);
            //if (opp.CloseDate.day() >= opp.Contract_Close_Date__c.day()) 
                monthDiff++;
            Decimal AmountToDevide = opp.Amount/monthDiff;
            Opportunity_Monthly_Value__c av = new Opportunity_Monthly_Value__c();
            for( Integer i = 0; i < monthDiff; i++){
                av.Opportunity__c = opp.Id;
                
                av.Monthly_Value__c = AmountToDevide;
                /*if(i == monthDiff && opp.CloseDate.addMonths(i) > opp.Contract_Close_Date__c){
                    av.Date__c = opp.Contract_Close_Date__c;
                }else{
                	av.Date__c = opp.CloseDate.addMonths(i);    
                }*/
                av.Date__c = date.newInstance(opp.CloseDate.addMonths(i).Year(), opp.CloseDate.addMonths(i).Month(), 1);
                annualValueListToInsert.add(av);
                av = new Opportunity_Monthly_Value__c();
                
            }
            System.debug(monthDiff);
        }
        if(annualValueListToInsert.size() > 0){
            try{
            	insert annualValueListToInsert;
        	}catch(exception e){}
        
            
        }
    }
    public static boolean DeleteMonthly(Opportunity newOpp){
        if(newOpp.CloseDate == null || newOpp.Contract_Close_Date__c == null || newOpp.Amount == null ){
        	return true;
        }
        return false;
    }
    public static void CreateMonthlyValues(List<Opportunity> newMapOpps, Map<Id,Opportunity> oldMapOpps){
        List<Opportunity> tempOpps = new List<Opportunity>();
        Boolean isOldMap = (oldMapOpps == null ? false: true);
        Set<Id> oppIDS = new Set<Id>();
        for(Opportunity opp: newMapOpps){
            if(opp.Parent_Opportunity__c){
                oppIDS.add(opp.ID);
            }else{
            	if(isOldMap){
                    if(isValidForMonthly(opp, oldMapOpps.get(opp.Id))){
                        tempOpps.add(opp);
                        oppIDS.add(opp.ID);
                    }
                    if(DeleteMonthly(opp)){
                        oppIDS.add(opp.ID);
                    }
                }else{
                    if(isValidForMonthly(opp, null)){
                        tempOpps.add(opp);
                        
                    }    
                }    
            }
            
            
        }
        
        if(isOldMap && oppIDS.size() > 0){
            deleteMonthlyFromOpp( oppIDS);
        }
        
        if(tempOpps.size() > 0){ 
            createMonthlyRecords(tempOpps); 
        }
    }
    public static void deleteMonthlyFromOpp(set<Id> oppIDS){
        List<Opportunity_Monthly_Value__c> listMonthlyOpp = [Select id from Opportunity_Monthly_Value__c where Opportunity__c In: oppIDS];
        
        try{
            if(listMonthlyOpp.size() > 0){
            	Delete listMonthlyOpp;        
            }
        	
        }catch(exception e){
            system.debug('Error Message On Delete OMV ' + e.getMessage());
        }
        
    }
}