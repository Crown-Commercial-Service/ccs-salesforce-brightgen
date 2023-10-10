trigger EmailMessageTrigger on EmailMessage (before insert, after insert, before delete) {
	
	// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('EmailMessage')){
		if(trigger.isAfter && trigger.isInsert)
		{
			EmailMessageTriggerHelper.onAfterInsert(trigger.new);
		}
	    if(trigger.isBefore && trigger.isDelete)
		{
			EmailMessageTriggerHelper.onBeforeDelete(trigger.oldMap);
		}
	    if(trigger.isBefore && trigger.isInsert)
		{
			EmailMessageTriggerHelper.onBeforeInsert(trigger.new);
		}
	}
}