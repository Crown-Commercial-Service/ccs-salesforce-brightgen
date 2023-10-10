trigger MasterFrameworkLotTrigger on Master_Framework_Lot__c (after insert, after update) {

		// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('MasterFrameworkLot')){
	    if(trigger.isAfter && trigger.isUpdate){
	    	MasterFrameworkLotTriggerHandler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
		}
	}
}