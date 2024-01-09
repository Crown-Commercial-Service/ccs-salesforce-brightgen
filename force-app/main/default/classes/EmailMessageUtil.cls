/*********************************************************************
 Name:  EmailMessageUtil
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Utils for Email Message
 - method to create email message from process builder skipping check of edit rights on case                                                      
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL              Description
   1.0   Piotr Czechumski   2016-05-19      Initial version 
   1.1   Cezary Zeleznicki  2016-10-14      Transfer Emails      US1360
   1.2   Emeric Gabor       2020-04-27      Email Owner          US0521
   1.3	 Divya Muvvala		2021-09-28		Fixed TransferEmails US1086
 *********************************************************************/
public class EmailMessageUtil {

    // Insert Email Messages without checking if user has access right to case parent record
    @InvocableMethod(label='Insert Email Messages' description='Insert Email Messages without checking if user has access right to edit parent record')
    public static void createEmailMessagesWithNoEditRights (List<EmailMessageWrapper> liEMWrap){
        List <EmailMessage> liEmails = new List <EmailMessage>();

        try{
            // turn off validation of edit rights
            EmailMessageTriggerHelper.CHECK_EDIT_RIGHTS_ON_CASE = false;

            for (EmailMessageWrapper emw : liEMWrap){
                EmailMessage em = new EmailMessage();
                
                // Set status of email
                em.Status = EmailStatus.get(emw.status);
                if (String.isBlank(em.Status)){
                    em.Status = '3'; // default set to Sent
                }
                em.ParentId = emw.caseId;
                em.Subject = emw.subject;
                em.TextBody = emw.textBody;
                em.ToAddress = emw.toAddress;
                em.FromAddress = emw.fromAddress;
                em.FromName = emw.fromName;

                liEmails.add(em);
            }

            insert liEmails;
        }
        catch (Exception ex){
            ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'EmailMessageUtil','createEmailMessagesWithNoEditRights' ,
                'Error on creating EmailMessage = ' + ex, ex,'ERROR',null,null, 
                (Integer)DateTime.now().getTime(), 'COW'
            );  
        }
    }

    @TestVisible
    private static Map <String, String> EmailStatus {
        get{
            if (EmailStatus == null){
                EmailStatus = new Map <String, String>();
                EmailStatus.put('New', '0');
                EmailStatus.put('Read', '1');
                EmailStatus.put('Replied', '2');
                EmailStatus.put('Sent', '3');
                EmailStatus.put('Forwarded', '4');
                EmailStatus.put('Draft', '5');
            }
            return EmailStatus;
        }
        set;
    }

    /*******************************************************************

    Purpose: Deletes email messages attached to source Case and creates
            copy of them under new case

    Parameters: originCaseId    Id of source Case
                targetCaseId    Id of target Case

    ********************************************************************/
    public static String transferEmailsToTargetCase(Id originCaseId, Id targetCaseId, Set<Id> emailIds) {
        Map<Id, EmailMessage> oldEmailId2newEmail = new Map<Id, EmailMessage>();
        Case originCase = [
            SELECT Id, CaseNumber, Subject,
                (SELECT Id, FromAddress, Incoming, ToAddress, Subject, TextBody, ParentId, BccAddress, 
                    CcAddress, FromName, Headers, HtmlBody, MessageDate, ReplyToEmailMessageId, 
                    Source_Case__c, Status
                FROM EmailMessages
                WHERE Id IN :emailIds) 
            FROM Case 
            WHERE Id = :originCaseId
        ];
      
        //US0521
        Case targetCase = new case();
        if(targetCaseId!=null){
            targetCase = [
                SELECT Id, ownerId, owner.email, owner.name, CaseNumber, Subject
                    FROM Case 
                    WHERE Id = :targetCaseId
            ];
        }
        //end US0521

        if(originCase.EmailMessages.isEmpty()) { 
            return Label.No_emails_under_source_Case;
        }   

        for(EmailMessage em : originCase.EmailMessages) {
            EmailMessage emCloned = em.clone(); 
            emCloned.ParentId = targetCaseId;
            if(String.isBlank(em.Source_Case__c)) {
                emCloned.Source_Case__c = originCaseId;
            } 
            oldEmailId2newEmail.put(em.Id, emCloned);
        }

        try {
            EmailMessageTriggerHelper.CHECK_EDIT_RIGHTS_ON_CASE = false;
            insert oldEmailId2newEmail.values();
            copyOverAttachmentsToNewEmail(oldEmailId2newEmail, targetCaseId, originCaseId);
            EmailMessageTriggerHelper.ALLOW_DELETION = true;
           // delete originCase.EmailMessages;
            
            //US0521 - send email to new case owner to confirm emails moved
            if(targetCaseId!=null ){
                //update URL for live
                string cssProdOrgURL = Org_Settings__c.getOrgDefaults().ORG_URL__c+'/';
                system.debug('cssProdOrgURL --'+ cssProdOrgURL);
                //delete the email from originCase
                delete originCase.EmailMessages;
                
                //construct the email message body
                string emailBodyConfirmMove = '<html><head><style> table {font-family: arial, sans-serif;border-collapse: collapse;}td, th {border: 1px solid #dddddd;text-align: left;padding: 8px;}tr:nth-child(even) {background-color: #F1F1F1;}</style></head><body><p>Hi ';
                emailBodyConfirmMove+=targetCase.owner.name+',</p><br/><p>THIS IS A SYSTEM GENERATED EMAIL.</p><p>Please be advised that one or more emails have been moved to the ';
                emailBodyConfirmMove+='<a href="'+cssProdOrgURL+targetCase.id+'">'+targetCase.CaseNumber+'</a> Case, and it requires your review.</p><br/><p>Number of Emails: ';
                emailBodyConfirmMove+=originCase.EmailMessages.size()+'</p><p>Case Subject: ';
                emailBodyConfirmMove+='<a href="'+cssProdOrgURL+targetCase.id+'">'+targetCase.Subject+'</a></p><br/><table ><tr ><th>Subject</th><th>From Name</th><th>From Address</th><th>Message Date</th></tr>';
                
                for(EmailMessage emCloned :oldEmailId2newEmail.values()){
                    emailBodyConfirmMove+='<tr><td><a href="'+cssProdOrgURL+emCloned.id+'">'+emCloned.Subject+'</a></td>';
                    emailBodyConfirmMove+='<td>'+emCloned.FromName+'</td>';
                    emailBodyConfirmMove+='<td>'+emCloned.FromAddress+'</td>';
                    emailBodyConfirmMove+='<td>'+emCloned.MessageDate+'</td></tr>';
                    
                }
                emailBodyConfirmMove+='</table>';
                
                if(string.valueOf(targetCase.OwnerId).startsWith('005')){//owner is user not queue
                    List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    user targetOwner = [SELECT Id, email FROM user WHERE id=:targetCase.OwnerId];
                    msg.setToAddresses(new List<String>{targetOwner.email});
                    msg.setHTMLbody(emailBodyConfirmMove);
                    msg.setSubject('Emails transferred to CASE -'+targetCase.CaseNumber);
                    //US1086 - fixed transferred email func. for Enhanced email feature
                    msg.setTargetObjectId(targetOwner.Id);
                    msg.setSaveAsActivity(false);

                    lstMsgs.add(msg);
                    	Messaging.SendEmailResult[] r = Messaging.sendEmail(lstMsgs);
                }
                return Label.Success_msg;
            }else{
                return null;
            }
            //end US0521
            
        } catch(Exception e) { 
            System.debug(LoggingLevel.ERROR, '*** JB e.getMessage = ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, '*** JB e.getStackTraceString = ' + e.getStackTraceString());
            return e.getMessage();
        }
        
        //return Label.Success_msg;
    }

    private static void copyOverAttachmentsToNewEmail(Map<Id, EmailMessage> oldEmailId2newEmail, Id targetCaseId, Id originCaseId) {
        System.debug(LoggingLevel.ERROR, '*** JB We are in copyOverAttachmentsToNewEmail');
        // Need to initialise any collections we need
        List<ContentVersion> cvToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
        List<ContentDocumentLink> cdlsToDelete = new List<ContentDocumentLink>();
        Set<Id> insertedCvIds = new Set<Id>();
        Set<Id> documentIds = new Set<Id>();
        Map<String, Id> emailIdByDocumentTitle = new Map<String, Id>();

        // Query for possible attachments related to the email
        List<Attachment> attachments = [
            SELECT Id, Name, Body, ParentId, ContentType
            FROM Attachment
            WHERE ParentId IN :oldEmailId2newEmail.keySet()
        ];

        // Query for possible CDLs related to the emails
        List<ContentDocumentLink> cdls = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :oldEmailId2newEmail.keySet() OR LinkedEntityId = :originCaseId];
        System.debug(LoggingLevel.ERROR, '*** JB cdls = ' + cdls);

        // If we have found some cdls then we will need to handle transferring those
        if(cdls.size() > 0)
        {
            System.debug(LoggingLevel.ERROR, '*** JB We are in the first if');
            for(ContentDocumentLink cdl : cdls) 
            {
                ContentDocumentLink newCDLEmail = null;
                ContentDocumentLink newCDLCase = null;
                System.debug(LoggingLevel.ERROR, '*** JB We are in the loop');
                // Checking if we are dealing with an email or not
                // if it is a case we will get a null reference error
                if (oldEmailId2newEmail.get(cdl.LinkedEntityId) != null && null != oldEmailId2newEmail.get(cdl.LinkedEntityId).Id)
                {
                    newCDLEmail = cdl.clone(false, true, false, false);
                    newCDLEmail.LinkedEntityId = oldEmailId2newEmail.get(cdl.LinkedEntityId).Id;

                    newCDLCase = cdl.clone(false, true, false, false);
                    newCDLCase.LinkedEntityId = targetCaseId;
                }
                System.debug(LoggingLevel.ERROR, '*** JB newCDLEmail = ' + newCDLEmail);
                System.debug(LoggingLevel.ERROR, '*** JB newCDLCase = ' + newCDLCase);

                if(newCDLEmail != null)
                {
                    cdlToInsert.add(newCDLEmail);
                }
                if(newCDLCase != null)
                {
                    cdlToInsert.add(newCDLCase);
                }
                
                cdlsToDelete.add(cdl);
            }
            System.debug(LoggingLevel.ERROR, '*** JB cdlToInsert = ' + cdlToInsert);
            System.debug(LoggingLevel.ERROR, '*** JB cdlsToDelete = ' + cdlsToDelete);
        }
        else if(cdls.size() < 1)
        {
            // If we don't have any cdls then we have attachments and will need to handle those

            if(attachments.size() > 0)
            {
                for(Attachment att : attachments) 
                {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = att.Name;
                    cv.VersionData = att.Body;
                    cv.PathOnClient = att.Name + att.ContentType;

                    cvToInsert.add(cv);

                    emailIdByDocumentTitle.put(att.Name, oldEmailId2newEmail.get(att.ParentId).Id);
                }
            }

            // Insert the new content versions
            if(!cvToInsert.isEmpty())
            {
                insert cvToInsert;
            }
            
            // Add the newly inserted content versions IDs to a set
            for(ContentVersion cv : cvToInsert)
            {
                insertedCvIds.add(cv.Id);
            }

            // Query for the inserted content versions so that we can get the contentdocumentid
            List<ContentVersion> insertedContentVersions = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id IN :insertedCvIds];

            if(!insertedContentVersions.isEmpty())
            {
                // Loop through all insert content versions and create a contentdocumentlink so we can share the record
                for(ContentVersion cv : insertedContentVersions)
                {
                    ContentDocumentLink cdlEmail = new ContentDocumentLink();
                    cdlEmail.ContentDocumentId = cv.ContentDocumentId;
                    cdlEmail.LinkedEntityId = emailIdByDocumentTitle.get(cv.Title);
                    cdlEmail.Visibility = 'AllUsers';

                    ContentDocumentLink cdlCase = new ContentDocumentLink();
                    cdlCase.ContentDocumentId = cv.ContentDocumentId;
                    cdlCase.LinkedEntityId = targetCaseId;
                    cdlCase.Visibility = 'AllUsers';

                    cdlToInsert.add(cdlEmail);
                    cdlToInsert.add(cdlCase);
                }
            }
        }

        // Create the links so users are able to find the files
        if(!cdlToInsert.isEmpty())
        {
            insert cdlToInsert;
        }
        // Delete the old links
        if(!cdlsToDelete.isEmpty())
        {
            delete cdlsToDelete;
        }
    }

    public class EmailMessageWrapper{
        @InvocableVariable(required=true) 
        public String status;

        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=true) 
        public String subject;

        @InvocableVariable(required=true) 
        public String textBody;

        @InvocableVariable(required=true) 
        public String toAddress;

        @InvocableVariable(required=true) 
        public String fromAddress;


        @InvocableVariable(required=true) 
        public String fromName;
    }

}