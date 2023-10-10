/*********************************************************************
 Name:  EmailMessageTriggerHelperTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: tests for email message trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Klea Kolaric       2016-03-22      Initial version
   2.0   Piotr Czechumski   2016-04-19      Add before delete handler tests
   2.1   Cezary Zeleznicki  2016-11-03      Procurement RT change
   2.2   Cezary Zeleznicki  2016-11-17      Fill in last received email field
 *********************************************************************/
@isTest
private class EmailMessageTriggerHelperTest {
    
    static final String ORG_NAME = 'Test Org';
    
    @testSetup
    static void setupTest()
    {
        insert UnitTestDataFactory.createOpsWorkflowStages();
        insert UnitTestDataFactory.createOpsWorkflowTemplates();
        Account org = UnitTestHelper.createOrganisationAccount(ORG_NAME);
        insert org;
        Contact con = UnitTestHelper.createContact(org.Id);
        insert con;
        Case c = UnitTestHelper.createProcurementCase(org.id);
        c.ContactId = con.Id;
        insert c;
    }
    
    static testMethod void testInsertTrigger_testBulkInsert_success()
    {
        Case c = [select id, Last_Email_Activity__c, Email_Activity_Type__c from Case where Account.Name = :ORG_NAME limit 1];
        List<EmailMessage> emails = new List<EmailMessage>();
        Integer recordCount = 200;
        
        for(Integer i=0; i<recordCount; i++)
        {
            emails.add(new EmailMessage(
                            FromAddress = 'test@abc.org',
                            Incoming = Math.mod(i,2) == 0,
                            ToAddress = 'test@def.test',
                            Subject = 'Email',
                            TextBody = 'Hello!.',
                            ParentId = c.id));
        }
        
        Test.startTest();
        insert emails;
        Test.stopTest();
        
        system.assertEquals(recordCount,[select count() from EmailMessage where ParentId = :c.Id], 'All emails inserted.');
    }
    
    static testMethod void testInsertTrigger_sendReceiveEmails_setActivityDetailsOnCase()
    {
        Case c = [
            SELECT id, Last_Email_Activity__c, Email_Activity_Type__c, Last_Received_Email_Address__c 
            FROM Case 
            WHERE Account.Name = :ORG_NAME LIMIT 1
        ];
        System.assertEquals(null,c.Last_Email_Activity__c, 'Last_Email_Activity__c should not be set.');
        System.assertEquals(null,c.Email_Activity_Type__c, 'Email_Activity_Type__c should not be set.');
        System.assertEquals(null, c.Last_Received_Email_Address__c, 'Last_Received_Email_Address__c should not be set');
        String testAbcEmail = 'test@abc.org';
        
        EmailMessage receivedEmail = new EmailMessage(
                                            FromAddress = testAbcEmail,
                                            Incoming = true,
                                            ToAddress = 'support@css.test',
                                            Subject = 'Received Email',
                                            TextBody = 'I sent you an email.',
                                            ParentId = c.id);
                                            
        EmailMessage sentEmail = new EmailMessage(
                                        FromAddress = 'support@css.test',
                                        Incoming = false,
                                        ToAddress = 'test@abc.org',
                                        Subject = 'Sent Email',
                                        TextBody = 'I got your an email.',
                                        ParentId = c.id);
        
        Test.startTest();
        
        insert receivedEmail;
        System.assertEquals(EmailMessageTriggerHelper.PLV_EMAIL_RECEIVED,
            [SELECT Email_Activity_Type__c FROM Case WHERE Last_Email_Activity__c != null].Email_Activity_Type__c,
            'Last_Email_Activity__c should be set and email should be of type received.');
        System.assertEquals(testAbcEmail, 
            [SELECT Last_Received_Email_Address__c FROM Case WHERE Id =: c.Id].Last_Received_Email_Address__c,
            'Last_Received_Email_Address__c should be equal to ' + testAbcEmail);
        insert sentEmail;
        
        System.assertEquals(EmailMessageTriggerHelper.PLV_EMAIL_SENT,
            [SELECT Email_Activity_Type__c FROM Case WHERE Last_Email_Activity__c != null].Email_Activity_Type__c,
            'Last_Email_Activity__c should be set and email should be of type sent.');
        System.assertEquals(testAbcEmail, 
            [SELECT Last_Received_Email_Address__c FROM Case WHERE Id =: c.Id].Last_Received_Email_Address__c,
            'Last_Received_Email_Address__c should be still equal to ' + testAbcEmail);
            
        Test.stopTest();
    }
    
    static testMethod void testDeleteTrigger_StopDelete()
    {
        // given
        Case c = [select id, Last_Email_Activity__c, Email_Activity_Type__c from Case where Account.Name = :ORG_NAME limit 1];
        List<EmailMessage> emails = new List<EmailMessage>();
        Integer recordCount = 10;
        
        for(Integer i=0; i<recordCount; i++)
        {
            emails.add(new EmailMessage(
                            FromAddress = 'test@abc.org',
                            Incoming = Math.mod(i,2) == 0,
                            ToAddress = 'test@def.test',
                            Subject = 'Email',
                            TextBody = 'Hello!.',
                            ParentId = c.id));
        }
        insert emails;

        // when - then
        Test.startTest();
            try{
                delete emails;
                System.assert(false, 'Should throw exception');
            }
            catch (DmlException dmlEx){
                String strExpMsg = dmlEx.getMessage();
                System.assert(strExpMsg.contains(Label.Only_Admin_Can_Delete), 
                    'Should fail with label message' );
            }
        Test.stopTest();
        
    }
    
    static testMethod void testDeleteTrigger_ShouldDelete()
    {
        // given
        Case c = [select id, Last_Email_Activity__c, Email_Activity_Type__c from Case where Account.Name = :ORG_NAME limit 1];
        List<EmailMessage> emails = new List<EmailMessage>();
        Integer recordCount = 10;
        Access_Permissions__c ap = new Access_Permissions__c();
        ap.EmailMessageDelete__c = true;
        ap.SetupOwnerId = UserInfo.getProfileId();
        insert ap;
        
        for(Integer i=0; i<recordCount; i++)
        {
            emails.add(new EmailMessage(
                            FromAddress = 'test@abc.org',
                            Incoming = Math.mod(i,2) == 0,
                            ToAddress = 'test@def.test',
                            Subject = 'Email',
                            TextBody = 'Hello!.',
                            ParentId = c.id));
        }
        insert emails;

        // when - then
        Test.startTest();
            delete emails;
            System.assertEquals(0, [select id from EmailMessage where id in :emails].size(),
                'All email messages should be deleted');
        Test.stopTest();
        
    }
    
   
    
}