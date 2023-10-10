trigger ProcurementStageTrigger on Procurement_Stage__c (before insert, before update) {
	
	// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('ProcurementStage'))
	{
		 if(trigger.isBefore && trigger.isInsert)
	  {
	    ProcurementStageTriggerHelper.onBeforeInsert(trigger.new);
	  }
	  
	  if(trigger.isBefore && trigger.isUpdate)
	  {
	    ProcurementStageTriggerHelper.onBeforeUpdate(trigger.new,trigger.oldMap);
	  }	  
	}
    
}