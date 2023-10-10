trigger CaseSupplierTrigger on Case_Supplier__c (before insert) {
	
	// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('CaseSupplier')){
		if(trigger.isBefore && trigger.isInsert){
			CaseSupplierTriggerHelper.onBeforeInsert(trigger.new);
		}
	}
    
}