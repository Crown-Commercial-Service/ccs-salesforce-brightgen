/*********************************************************************
 Name:  AttachmentTriggerHandler
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for attachment trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Piotr Czechumski   2016-04-20     Initial version 
 *********************************************************************/
public with sharing class AttachmentTriggerHandler {

    public static void onBeforeDelete(Map<Id,Attachment> oldMap)
    {
        List<Attachment> liEmailAttachment = new List<Attachment> ();
        String emPrefix = Schema.getGlobalDescribe().get('EmailMessage').getDescribe().getKeyPrefix();
        
        for (Attachment att : oldMap.values()){
        	String partentId = att.ParentId;
        	if (partentId.startsWith(emPrefix)){
        		liEmailAttachment.add(att);
        	}
        }
        if (liEmailAttachment.size() > 0){
        	checkDeletePermissionForEmailAttachments(oldMap.values());
    	}
    }
    

    public static void checkDeletePermissionForEmailAttachments(List<Attachment> attachments)
    {
        if (Access_Permissions__c.getInstance().EmailAttachmentDelete__c == null
            || !Access_Permissions__c.getInstance().EmailAttachmentDelete__c){
            for (Attachment att : attachments){
                att.addError(Label.Only_Admin_Can_Delete);
            }
        }
    }
}