trigger CaseTrigger on Case (before update, before insert, after insert, after update) {

	// turn off by custom setting
	if (!TriggerSwitchService.isTriggerSwitchOff('Case'))
	{
		
		if(trigger.isBefore && trigger.isUpdate)
		{
			CaseTriggerHelper.onBeforeUpdate(trigger.new,trigger.oldMap);
		}

		if(trigger.isBefore && trigger.isInsert)
		{
			CaseTriggerHelper.onBeforeInsert(trigger.new);
		}
		
		if(trigger.isAfter && trigger.isInsert)
		{
			CaseTriggerHelper.onAfterInsert(trigger.new);
		}
		
		if(trigger.isAfter && trigger.isUpdate)
		{
			CaseTriggerHelper.onAfterUpdate(trigger.new,trigger.oldMap);
		}
    }
}