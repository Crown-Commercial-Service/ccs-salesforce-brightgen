/*********************************************************************
 Name:  AttachmentTriggerHandlerTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: unit test for AttachmentTriggerHandlerTest                                                          
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Piotr Czechumski   2016-04-20     Initial version 
   1.1	 Cezry Zeleznicki 	2016-11-03	   Procurement RT change
 *********************************************************************/
@isTest (seeAllData=false)
private class AttachmentTriggerHandlerTest
{
	static final String ORG_NAME = 'Attachment Test Org';
	
	@testSetup
	static void setupTest()
	{
		insert UnitTestDataFactory.createOpsWorkflowStages();
		insert UnitTestDataFactory.createOpsWorkflowTemplates();
		
		Account org = UnitTestDataFactory.createOrganisationAccount(ORG_NAME);
		insert org;
		Contact con = UnitTestDataFactory.createContact(org.Id);
		insert con;
		Case c = UnitTestDataFactory.createProcurementCase(org.id);
		c.ContactId = con.Id;
		insert c;
		EmailMessage em = UnitTestDataFactory.createEmailMessage(c.id, true);
		insert em;
	}

	@isTest
	static void testDelete_ShouldBlockDelete()
	{
		// Given
		EmailMessage em = [select Id, Subject from EmailMessage
			where Parent.Account.Name = :ORG_NAME limit 1];
		Attachment att = UnitTestDataFactory.createAttachment(em.id);
		insert att;

		// When - Then
		Test.startTest();
			try{
				delete att;
				System.assert(false, 'Should throw exception');
			}
			catch (DmlException dmlEx){
				String strExpMsg = dmlEx.getMessage();
				System.assert(strExpMsg.contains(Label.Only_Admin_Can_Delete), 
					'Should fail with label message' );
			}
		Test.stopTest();

	}

	@isTest
	static void testDelete_ShouldAllowDelete()
	{
		// Given
		EmailMessage em = [select Id, Subject from EmailMessage
			where Parent.Account.Name = :ORG_NAME limit 1];
		Attachment att = UnitTestDataFactory.createAttachment(em.id);
		insert att;

		Access_Permissions__c ap = new Access_Permissions__c();
		ap.EmailAttachmentDelete__c = true;
		ap.SetupOwnerId = UserInfo.getProfileId();
		insert ap;

		// When - Then
		Test.startTest();
			delete att;
			System.assertEquals(0, [select id from Attachment where id = :att.id].size(),
				'Should allow deletion of attachment');			
		Test.stopTest();
	}

	@isTest
	static void testDelete_ShouldAllowDeleteForNotEmailAttachments()
	{
		// Given
		Account acct = [select id, name from Account where Name = :ORG_NAME limit 1];
		Attachment att = UnitTestDataFactory.createAttachment(acct.id);
		insert att;


		// When - Then
		Test.startTest();
			delete att;
			System.assertEquals(0, [select id from Attachment where id = :att.id].size(),
				'Should allow deletion of attachment');			
		Test.stopTest();
	}
}