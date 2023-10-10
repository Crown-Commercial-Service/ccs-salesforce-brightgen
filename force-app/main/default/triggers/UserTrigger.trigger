/*********************************************************************
Name:  UserTrigger
Copyright © 2016  Salesforce
=====================================================================

Purpose: This is the Trigger that fires when a new user is INSERTED.  It is passed to the Class
         UserTriggerHandler
         A secondary purpose is when a Portal User makes changes to their user profile, keep the Contact
         fields Synced.

=====================================================================
History
-------
VERSION  AUTHOR            DATE         DETAIL                      Description
 1.0    Simon Coles        2016-11-03   Initial version
 1.1    Simon Coles        2016-11-10   Adding update to Sync user data with Contact.
 1.2    Simon Coles        2016-11-15   Check Org Sector and assign appropriate Liscence
*********************************************************************/

trigger UserTrigger on USER (after insert, after update, before insert) {

  /************************************************************
        Purpose: This method checks that the custom setting switch in not checked before passing the new User List
             to the handler
        Parameters: Trigger.new
        Returns:
        Throws:
    *************************************************************/

  // Disable by a custom setting
  if(trigger.isInsert && trigger.isAfter) {
    UserTriggerHandler.onAfterInsert(trigger.new);
  }

  /************************************************************
        Purpose: This method checks that the custom setting switch in not checked before passing the new User List
             to the handler
        Parameters: Trigger.new
        Returns:
        Throws:
    *************************************************************/

  if(trigger.isUpdate && trigger.isAfter) {
    UserTriggerHandler.onAfterUpdate(trigger.new);
  }

  /************************************************************
        Purpose: This method checks that the custom setting switch in not checked before passing the new User List
                 to the handler
        Parameters: Trigger.new
        Returns:
        Throws:
    *************************************************************/

  if(trigger.isInsert && trigger.isBefore) {
    UserTriggerHandler.onBeforeInsert(trigger.new);
  }

}