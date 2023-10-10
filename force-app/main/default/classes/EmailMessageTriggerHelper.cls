/*********************************************************************
 Name:  EmailMessageTriggerHelper
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for email message trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Klea Kolaric       2016-03-22      Initial version 
   2.0   Piotr Czechumski   2016-04-19      Add before delete handler   
   3.0   Klea Kolaric       2016-05-05      prevent email creation if you can't edit case   
   4.0   Cezary Zeleznicki  2016-10-14      Allow email deletion if flag set
   5.0   Cezary Zeleznicki  2016-11-17      Fill in last received email field
 *********************************************************************/
public class EmailMessageTriggerHelper {
    
    public static final String PLV_EMAIL_RECEIVED = 'Email Received';
    public static final String PLV_EMAIL_SENT = 'Email Sent';

    public static Boolean CHECK_EDIT_RIGHTS_ON_CASE = true;

    public static Boolean ALLOW_DELETION = false;
    
    /* HANDLERS */
    
    public static void onBeforeInsert(List<EmailMessage> triggerNew)
    {
        if (CHECK_EDIT_RIGHTS_ON_CASE){
            preventEmailSendIfNoEditRightsOnCase(triggerNew);
        }
    }
    
    public static void onBeforeDelete(Map<Id,EmailMessage> oldMap)
    {
        checkDeletePermission(oldMap.values());
    }
    
    public static void onAfterInsert(List<EmailMessage> triggerNew)
    {
        updateCaseEmailActivity(triggerNew);
    }
    
    /* METHODS */
    
    // when an email is created, update case object with datetime and type (US497)
    public static void updateCaseEmailActivity(List<EmailMessage> emails)
    {
        Map<Id,Case> updateCases = new Map<Id,Case>();
        for(EmailMessage em : emails)
        {
            if(em.ParentId != null && em.ParentId.getSobjectType() == Schema.Case.SObjectType) // if parent is case
            {
                // create case object for update
                Case c = new Case(Id = em.ParentId);
                c.Last_Email_Activity__c = em.CreatedDate;
                c.Email_Activity_Type__c = em.Incoming ? PLV_EMAIL_RECEIVED : PLV_EMAIL_SENT;
                if(em.Incoming) {
                    c.Last_Received_Email_Address__c = em.FromAddress;
                }
                // in the rare case we get two emails at the same time, update with newer (if that's even possible to ascertain)
                if(!updateCases.containsKey(c.Id) || updateCases.get(c.Id).Last_Email_Activity__c <= c.Last_Email_Activity__c)
                {
                    updateCases.put(c.Id,c);
                }
            }
        }
        update updateCases.values();
    }

    public static void checkDeletePermission(List<EmailMessage> emails)
    {
        if ((Access_Permissions__c.getInstance().EmailMessageDelete__c == null
            || !Access_Permissions__c.getInstance().EmailMessageDelete__c)
            && !ALLOW_DELETION){
            for (EmailMessage em :emails){
                em.addError(Label.Only_Admin_Can_Delete);
            }
        }
    }
    
    // US699 TA945/DE86 prevent user form sending email if they don't have edit access on case
    public static void preventEmailSendIfNoEditRightsOnCase(List<EmailMessage> emailMessages)
    {
        Id userId = UserInfo.getUserId();
        System.debug('**Inside preventEmailSendIfNoEditRightsOnCase**');
        Set<Id> caseIds = new Set<Id>();
        Set<Id> Ids = new Set<Id>();
        
        for(EmailMessage em : emailMessages)
        {    
          if(em.ParentId != null && em.ParentId.getSobjectType() == Schema.Case.SObjectType) // if parent is case
          {
            System.Debug('In case'+em.ParentId);
            caseIds.add(em.ParentId);
          }
          else{
              	//turn off to check edit access if it's not Case object
                CHECK_EDIT_RIGHTS_ON_CASE = false;
          } 
        }
system.debug('CHECK_EDIT_RIGHTS_ON_CASE >> '+CHECK_EDIT_RIGHTS_ON_CASE);
        // find access
        Set<Id> hasEditAccessIds = new Set<Id>();   // contains ids of all records user can edit
        if(CHECK_EDIT_RIGHTS_ON_CASE){
        	for(UserRecordAccess ura : [select HasEditAccess,RecordId from UserRecordAccess where UserId = :userId and  RecordId in :caseIds ])
        	{
                 System.Debug('In URA'+ura);
            	if(ura.HasEditAccess )
            	{
                	hasEditAccessIds.add(ura.RecordId);
            	}
         	}
        
        	for(EmailMessage em : emailMessages)
        	{
            	System.Debug('In hasEditAccessIds*******'+hasEditAccessIds);
            	String pId ;
            
            	if(em.ParentId != null && em.ParentId.getSobjectType() == Schema.Case.SObjectType){
                	pId = em.ParentId;
            	} /*else if((em.RelatedToId != null && em.RelatedToId.getSobjectType() == Schema.Opportunity.SObjectType)){
                	pId = em.RelatedToId;
            	}*/
            
            	System.Debug('In PId********'+pId);

            	if(!hasEditAccessIds.contains(pId))
            	{
                	em.addError(Label.COW_Email_NoEditAccessToCase);
            	}
        	}
        }
    }
    
   
}