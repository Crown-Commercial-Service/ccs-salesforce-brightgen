/*
Title: bg_CaseEmailsReparent_Controller
Date: 14/09/2020
Author: JAG
Description: Apex controller for bg_CaseEmailReparent LWC.
*/

public without sharing class bg_CaseEmailsReparent_Controller 
{
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getEmails(String caseId)
    {
        List<EmailMessage> emails = new List<EmailMessage>();

        emails = [SELECT Id, toLabel(Status), Subject, FromAddress, MessageDate, Was_Reparented__c, Incoming FROM EmailMessage WHERE ParentId =: caseId];

        return emails;
    }

    @AuraEnabled
    public static string transferEmails(String originCaseId, String targetCaseId, List<Map<String, String>> emailMessages)
    {
        Set<Id> ids = new Set<Id>();
        String result;

        for(Map<String, String> email : emailMessages)
        {
            ids.add((Id)email.get('Id'));
        }

        try 
        {
            result = EmailMessageUtil.transferEmailsToTargetCase((Id)originCaseId, (Id)targetCaseId, ids);
        }
        catch (Exception e) 
        {
            result = e.getMessage();
        }
        
        return result;
    }
}