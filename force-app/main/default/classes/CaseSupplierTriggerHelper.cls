/*********************************************************************
 Name:  CaseSupplierTriggerHelper
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for case supplier trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-06		Initial version 	US601
   1.1 	 Cezary Zeleznicki	2016-11-04		Procurement RT change
 *********************************************************************/
public with sharing class CaseSupplierTriggerHelper {
	
	/* HANDLERS */
	
	public static void onBeforeInsert(List<Case_Supplier__c> triggerNew)
	{
		validationForCallOffDirectAward(triggerNew);
	}
	
	/* CONSTANTS */
	public static final String PL_CALLOFFDIRECTAWARD = 'Procurement_Call_Off_Direct_Award';
	
	/* METHODS */
	
	// if procurement route is Call Off (Direct Award)
	// make sure suppliers are also related to framework lot
	public static void validationForCallOffDirectAward(List<Case_Supplier__c> caseSupps)
	{
		// filter records
		Map<Id,Case> cases;
		Map<Id,Master_Framework_Lot__c> mfws;
		{
			Set<Id> caseIds = new Set<Id>();
			Set<Id> suppIds = new Set<Id>();

			for(Case_Supplier__c cs: caseSupps)
			{
				caseIds.add(cs.Procurement__c);
				suppIds.add(cs.Supplier__c);
			}

			cases = new Map<Id,Case>([select id, Framework_Lot__c from Case where Id in :caseIds and RecordType.DeveloperName = :PL_CALLOFFDIRECTAWARD]);
			if(cases.isEmpty())
			{
				return;
			}
			
			Set<Id> mfwlIds = new Set<Id>();
			for(Case c: cases.values())
			{
				mfwlIds.add(c.Framework_Lot__c);
			}
			
			mfws = new Map<Id,Master_Framework_Lot__c>(
				[select id, (select Supplier__c from Supplier_Framework_Lots__r where Supplier__c in :suppIds) 
					from Master_Framework_Lot__c where id in :mfwlIds]
			);
		}
		
		for(Case_Supplier__c cs: caseSupps)
		{
			if(!cases.containsKey(cs.Procurement__c)) 
			{
				continue;	// skip any non-(Call Off (Direct Award)) procurements
			}
			Case c = cases.get(cs.Procurement__c);

			if(c.Framework_Lot__c == null)
			{
				cs.addError('You cannot add a supplier unless you have already selected a Framework Lot on the Procurement.');
				continue;
			}
			
			Master_Framework_Lot__c mfw = mfws.get(c.Framework_Lot__c);
			Boolean foundFlag = false;
			for(Supplier_Framework_Lot__c sfl : mfw.Supplier_Framework_Lots__r)
			{
				if(cs.Supplier__c == sfl.Supplier__c)
				{
					foundFlag = true;
					break;
				}
			}
			if(!foundFlag) 
			{
				cs.addError('The supplier you are attempting to add is not on the relevant Framework Agreement and Lot. '
					+ 'Please recheck the Framework Lot to identify the valid suppliers.');
			}
		}
	}
    
}