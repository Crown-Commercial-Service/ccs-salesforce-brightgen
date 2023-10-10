/*********************************************************************
Name:  CCSContractTrigger
Copyright © 2016  Salesforce
=====================================================================

Purpose: This Trigger fires when a Contract is Updated/Inserted.  It is passed to the Class
         CCSContractTriggerHandler

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles        2016-11-03   Initial version
 ********************************************************************/

trigger CCSContractTrigger on CCS_Contract__c (after update, after insert) {

  /************************************************************
        Purpose: This method fires after Inserting a Contract
        Parameters: Trigger.new
        Returns:
        Throws:
    *************************************************************/

    // Disable by a custom setting
    if (!TriggerSwitchService.isTriggerSwitchOff('CCSContract')) {
      if(trigger.isInsert && trigger.isAfter) {
        CCSContractTriggerHandler.onAfterInsert(trigger.new, null);
      }
    }

  /************************************************************
        Purpose: This method fires after Update an existing Contract
        Parameters: Trigger.new
        Returns:
        Throws:
    *************************************************************/

    // Disable by a custom setting
    if (!TriggerSwitchService.isTriggerSwitchOff('CCSContract')) {
      if(trigger.isUpdate && trigger.isAfter) {
        CCSContractTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
      }
    }
}