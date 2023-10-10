/*********************************************************************
 Name:  EmailMessageUtilTest
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
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0    --                --               Initial version 
   1.1    Cezary Zeleznicki 2016-10-14       Transfer Emails    US1360
   1.2    Cezary Zeleznicki 2016-11-03       Procurement RT change
 *********************************************************************/
@isTest (seeAllData=false)
private class EmailMessageUtilTest {

    @testSetup
    static void createData() {
        insert UnitTestDataFactory.createOpsWorkflowStages();
        insert UnitTestDataFactory.createOpsWorkflowTemplates();
        Account org = UnitTestDataFactory.createOrganisationAccount('Test org for unit test - EmailMessageUtilTest');
        insert org;
        Contact con = UnitTestDataFactory.createContact(org.Id);
        insert con;
        Case c = UnitTestDataFactory.createProcurementCase(org.id);
        c.ContactId = con.Id;
        Case c2 = c.clone();
        c2.Origin = 'Email';
        insert new List<Case>{c, c2};
        EmailMessage em = UnitTestDataFactory.createEmailMessage(c.Id, true);
        insert em;
        Attachment att = UnitTestDataFactory.createAttachment(em.Id);
        insert att;
    }
    
    static testMethod void shouldCreateEmailMessage()
    {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        EmailMessageUtil.EmailMessageWrapper emw = new EmailMessageUtil.EmailMessageWrapper();
            emw.caseId = c.id;
            // do not set status to get deafult (sent)
            //emw.status = 'Sent'; 
            emw.subject = 'Apex Unit test';
            emw.textBody = 'Just unit test';
            emw.toAddress = 'unittest@salesforce.donotsend.com';
            emw.fromAddress = 'unittest@ccs.donotsend.com';
            emw.fromName = 'Unit test sender';
            EmailMessageUtil.createEmailMessagesWithNoEditRights(new List<EmailMessageUtil.EmailMessageWrapper> {emw});
        Test.stopTest();
        
        System.assertEquals(2, [select id from EmailMessage where parentid = :c.id].size(), 'One email message should be created');
    }

    static testMethod void shouldFailOnCreateEmailMessage()
    {
        Test.startTest();
        EmailMessageUtil.EmailMessageWrapper emw = new EmailMessageUtil.EmailMessageWrapper();
            emw.caseId = null;
            emw.status = 'Sent'; 
            emw.subject = 'Apex Unit test2';
            emw.textBody = 'Just unit test2';
            emw.toAddress = 'unittest@salesforce.donotsend.com';
            emw.fromAddress = 'unittest@ccs.donotsend.com';
            emw.fromName = 'Unit test sender';
            EmailMessageUtil.createEmailMessagesWithNoEditRights(new List<EmailMessageUtil.EmailMessageWrapper> {emw});
        Test.stopTest();
        
        System.assertEquals(1, [select id from EmailMessage].size(), 'One email message should be created');    
    }

    static testMethod void test_transferEmailsToTargetCase() {
        Id originCaseId = [SELECT Id, Origin FROM Case WHERE Origin = 'Phone' LIMIT 1].Id,
        targetCaseId = [SELECT Id, Origin, ownerId, owner.email FROM Case WHERE Origin = 'Email' LIMIT 1].Id;
        Id emailMessageId = [SELECT Id, parentId FROM EmailMessage LIMIT 1].Id;

        Test.startTest();
        String status = EmailMessageUtil.transferEmailsToTargetCase(originCaseId, targetCaseId, new Set<Id>{emailMessageId});
        Test.stopTest();

        Case originCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :originCaseId],
        targetCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :targetCaseId];
        System.assertEquals(Label.Success_msg, status, 'Status returned should be Success');
        System.assertEquals(0, originCase.EmailMessages.size(), 'Source case shouldn\'t contain any emails');
        System.assertEquals(1, targetCase.EmailMessages.size(), 'Target case should contain 1 email');
    }

    static testMethod void test_transferEmailsToTargetCase_Exception() {
        Id originCaseId = [SELECT Id, Origin FROM Case WHERE Origin = 'Phone' LIMIT 1].Id,
        targetCaseId = [SELECT Id, Origin FROM Case WHERE Origin = 'Email' LIMIT 1].Id;
        Id emailMessageId = [SELECT Id FROM EmailMessage LIMIT 1].Id;
        
        Test.startTest();
        String status = EmailMessageUtil.transferEmailsToTargetCase(originCaseId, null, new Set<Id>{emailMessageId});
        Test.stopTest();
        
        Case originCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :originCaseId],
        targetCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :targetCaseId];
        
        System.assertNotEquals(Label.Success_msg, status, 'Status returned should\'t be succes');
        System.assertNotEquals(Label.No_emails_under_source_Case, status, 'Status returned should\'t be no email mgs');
        System.assertEquals(1, originCase.EmailMessages.size(), 'Source case should still contain an email');
        System.assertEquals(0, targetCase.EmailMessages.size(), 'No emails should be moved to target case');
    }

    static testMethod void test_transferEmailsToTargetCase_NoEmails() {
        Id originCaseId = [SELECT Id, Origin FROM Case WHERE Origin = 'Phone' LIMIT 1].Id,
        targetCaseId = [SELECT Id, Origin FROM Case WHERE Origin = 'Email' LIMIT 1].Id;
        Id emailMessageId = [SELECT Id FROM EmailMessage LIMIT 1].Id;

        Test.startTest();
        String status = EmailMessageUtil.transferEmailsToTargetCase(targetCaseId, originCaseId, new Set<Id>{emailMessageId});
        Test.stopTest();

        Case originCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :originCaseId],
        targetCase = [SELECT Id, (SELECT Id FROM EmailMessages) Origin FROM Case WHERE Id = :targetCaseId];
        System.assertEquals(Label.No_emails_under_source_Case, status, 'Status returned should be no emails msg');
        System.assertEquals(1, originCase.EmailMessages.size(), 'Source case should still contain an email');
        System.assertEquals(0, targetCase.EmailMessages.size(), 'No emails should be moved to target case');
    }
    
}