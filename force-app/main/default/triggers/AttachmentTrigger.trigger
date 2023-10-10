trigger AttachmentTrigger on Attachment (before delete)  {
	
	// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('Attachment')){
		if(trigger.isBefore && trigger.isDelete){
			AttachmentTriggerHandler.onBeforeDelete(trigger.oldMap);
		}
	}
}