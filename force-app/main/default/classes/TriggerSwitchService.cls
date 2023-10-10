/*****************************************************************************************************************************
Name: TriggerSwitchService

Purpose: Service class for turn off trigger by custom setting functionality

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      19/04/2016      INITIAL DEVELOPMENT
*******************************************************************************************************************************/
// Service class - without sharing
public without sharing class TriggerSwitchService {	
	public static Boolean isTriggerSwitchOff (String triggerName){
		Boolean retVal = false;
		String strFieldName = triggerName + '__c';
		// check if field for trigger exists
		if (Schema.getGlobalDescribe().get('Trigger_switch__c').getDescribe().fields.getMap().get(strFieldName) != null){
			Boolean bCSValue = (Boolean) Trigger_switch__c.getInstance().get(strFieldName);
			retVal =  bCSValue == null ? false : bCSValue;
		}
        

		return retVal;
	}
}