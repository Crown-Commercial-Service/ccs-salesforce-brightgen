/*********************************************************************
 Name:  MasterFrameworkLotTriggerHandler
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for Master Framework lots trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Piotr Czechumski   2016-04-20     	Initial version 
 *********************************************************************/
public class MasterFrameworkLotTriggerHandler {
	public static final String MFL_STATUS_EXPIRED = 'Expired';
	public static final String SFL_STATUS_EXPIRED = 'Expired';

	public static void onAfterUpdate(Map<Id,Master_Framework_Lot__c> oldMap, Map<Id,Master_Framework_Lot__c> newMap){
		checkAndUpdateSupplierFrameworkLotWhenExpired(oldMap, newMap);
	}

	/************************************************************
        Purpose: Method  updates child supplier framework lots when status change to Expired
        Parameters: Map of master framework lots to update
        Returns: - 
        Throws: -
    *************************************************************/   
	public static void checkAndUpdateSupplierFrameworkLotWhenExpired (Map<Id, Master_Framework_Lot__c> mapOldMFL, 
			Map<Id, Master_Framework_Lot__c> mapNewMFL){
		
		List<Master_Framework_Lot__c> liMFL = new List<Master_Framework_Lot__c> ();

		for (Master_Framework_Lot__c mflNew : mapNewMFL.values()){
			Master_Framework_Lot__c mflOld = mapOldMFL.get(mflNew.id);
			if (mflOld.Status__c != mflNew.Status__c && mflNew.Status__c == MFL_STATUS_EXPIRED){
				liMFL.add(mflNew);
			}
		}

		if (liMFL.size() > 0){
			updateSupplierFrameworkLotWhenExpired(liMFL);
		}
	}
	
    /************************************************************
        Purpose: Method  updates child supplier framework lots when status change to Expired
        Parameters: List of master framework lots to update
        Returns: - 
        Throws: -
    *************************************************************/   
	public static void updateSupplierFrameworkLotWhenExpired (List<Master_Framework_Lot__c> liMFL){
		List<Supplier_Framework_Lot__c> liSFL = [select id, Status__c from Supplier_Framework_Lot__c
			where Master_Framework_Lot__c in :liMFL and Status__c <> :SFL_STATUS_EXPIRED];

		for (Supplier_Framework_Lot__c sfl : liSFL){
			sfl.Status__c = SFL_STATUS_EXPIRED;
		}

		update liSFL;
	}
}