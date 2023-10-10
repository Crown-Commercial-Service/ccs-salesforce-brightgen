/*****************************************************************************************************************************
Name: TriggerSwitchService

Purpose: Unit test for  TriggerSwitchService

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      19/04/2016      INITIAL DEVELOPMENT
*******************************************************************************************************************************/
@isTest (seeAllData=false)
private  with sharing class TriggerSwitchServiceTest {
	@isTest
	static void shouldReturnFalseForNotExisting(){
		System.assert(!TriggerSwitchService.isTriggerSwitchOff('NoExistingTigger'), 
			'Should return false for not existing trigger');
	}

	@isTest
	static void shouldReturnValueFromCS(){
		Trigger_switch__c ts =  new Trigger_switch__c(EmailMessage__c = false);
		insert ts;
		System.assert(!TriggerSwitchService.isTriggerSwitchOff('EmailMessage'), 
			'Should return false for active trigger');
		ts.EmailMessage__c = true;
		update ts;

		System.assert(TriggerSwitchService.isTriggerSwitchOff('EmailMessage'), 
			'Should return true for swith off trigger ');
	}
}