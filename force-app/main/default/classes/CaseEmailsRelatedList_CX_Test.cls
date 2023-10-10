/*********************************************************************
 Name:  CaseEmailsRelatedList_CX
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller extension for CaseEmailsRelatedList page and
					MoveCaseEMails page
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-19     Initial version
		1.1  Cezary Zeleznicki  2016-11-03		 Procurement RT change
 *********************************************************************/
@isTest
private class CaseEmailsRelatedList_CX_Test {
	
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
		Case c3 = c.clone();
		c3.Origin = 'Web';
		insert new List<Case>{c, c2, c3};
		EmailMessage em = UnitTestDataFactory.createEmailMessage(c.Id, true);
		List<EmailMessage> emails = createEmails(c3.Id, 100);
		emails.add(em);
		insert emails;
		Attachment att = UnitTestDataFactory.createAttachment(em.Id);
		insert att;
	}

	private static List<EmailMessage> createEmails(Id caseId, Integer emailsSize) {
		List<EmailMessage> emails = new List<EmailMessage>();
		for(Integer i = 0; i < emailsSize; i++) {
			emails.add(UnitTestDataFactory.createEmailMessage(caseId, true));
		}
		return emails;
	}

	static testMethod void test_getEmails() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		List<CaseEmailsRelatedList_CX.EmailWrapper> emails = cerl.getEmails();
		Boolean isAbleToSendEmail = cerl.getIsAbleToSendEmail();
		Test.stopTest();

		System.assert(!emails.isEmpty(), 'Emails shouldn\'t be empty');
		System.assert(isAbleToSendEmail, 'User should have edit permissions on Source Case');
	}

	static testMethod void test_getSelectedEmails() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.MoveCaseEmails;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		List<CaseEmailsRelatedList_CX.EmailWrapper> emails = cerl.getEmails();
		emails[0].isSelected = true;
		PageReference pr = cerl.openMoveEmailsPage();
		List<CaseEmailsRelatedList_CX.EmailWrapper> selEmails = cerl.getSelectedEmails();
		Test.stopTest();

		System.assertEquals(Page.MoveCaseEmails.getUrl(), pr.getUrl(), 
			'MoveCaseEmails page should be returned');
		System.assert(!selEmails.isEmpty(), 'List of selected emails shouldn\'t be empty');
	}

	static testMethod void test_openMoveEmailsPage() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		List<CaseEmailsRelatedList_CX.EmailWrapper> emails = cerl.getEmails();
		PageReference pr = cerl.openMoveEmailsPage();
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		Test.stopTest();
		Boolean containsNoEmailMsg = false;
		for(Apexpages.Message msg : msgs) {
			containsNoEmailMsg = msg.getDetail().contains(Label.No_emails_selected);
		}
		System.assert(containsNoEmailMsg, 'No emails msg should be returned');
	}

	static testMethod void test_moveEmails() {
		Case c = [SELECT Id FROM Case WHERE Origin = 'Web' LIMIT 1];
		Case targetCase = [SELECT Id FROM Case WHERE Origin = 'Email' LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		List<CaseEmailsRelatedList_CX.EmailWrapper> emails = cerl.getEmails();
		for(CaseEmailsRelatedList_CX.EmailWrapper ew : emails) {
			ew.isSelected = true;
		}
		cerl.moveEmails();
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		cerl.targetCase.ParentId = targetCase.Id;
		cerl.moveEmails();
		msgs.addAll(ApexPages.getMessages());
		Test.stopTest();

		Boolean containsNoTargetMsg = false;
		for(Apexpages.Message msg : msgs) {
			String msgStr = msg.getDetail();
			if(msgStr.contains(Label.No_target_Case_selected)) {
				containsNoTargetMsg = true;
			}
		}
		System.assert(containsNoTargetMsg, 'No target case msg should be returned');
	}

	static testMethod void test_goBackToCase() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.MoveCaseEmails;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		PageReference pr = cerl.goBackToCase();
		Test.stopTest();

		System.assertEquals(sc.view().getUrl() + '?inline=0', pr.getUrl(),
			'Case view should be returned');
	}

	static testMethod void test_showMore() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		cerl.getEmails();
		cerl.showMore();
		Test.stopTest();

		System.assertEquals(10, cerl.pageSize, 'Page size should be equal 10');
	}

	static testMethod void test_goToList() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		cerl.getEmails();
		cerl.goToList();
		Test.stopTest();

		System.assertEquals(10, cerl.pageSize, 'Page size should be equal 10');
		System.assert(cerl.showFullPage, 'Show full page param should be set');
	}

	static testMethod void test_SetControllerMethods() {
		Case c = [SELECT Id FROM Case LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(c);
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		pageRef.getParameters().put('id', String.valueOf(c.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		cerl.getEmails();
		Boolean hasNext = cerl.getHasNext();
		Boolean hasPrevious = cerl.getHasPrevious();
		Boolean isFirst = cerl.getIsFirst();
		Integer recSize = cerl.getRecordsSize();
		cerl.first();
		cerl.last();
		cerl.previous();
		cerl.next();
		Test.stopTest();

		System.assert(!hasNext, 'Next page shouldn\'t be available');
		System.assert(!hasPrevious, 'Previous page should\'t be available');
		System.assert(isFirst, 'First page should be displayed');
		System.assertEquals(1, recSize, 'Record size in set controller should be 1');
	}

	static testMethod void test_failPath() {
		Case c = [SELECT Id FROM Case WHERE Origin = 'Phone' LIMIT 1];
		Case targetCase = [SELECT Id FROM Case WHERE Origin = 'Email' LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(new Case());
		
		PageReference pageRef = Page.CaseEmailsRelatedList;
		Test.setCurrentPage(pageRef);
		Test.startTest();
		CaseEmailsRelatedList_CX cerl = new CaseEmailsRelatedList_CX(sc);
		List<CaseEmailsRelatedList_CX.EmailWrapper> emails = cerl.getEmails();
		List<CaseEmailsRelatedList_CX.EmailWrapper> selectedEmails = cerl.getSelectedEmails();
		cerl = new CaseEmailsRelatedList_CX(new ApexPages.StandardController(c));
		cerl.getEmails();
		cerl.targetCase.ParentId = targetCase.Id;
		cerl.moveEmails();
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		Test.stopTest();

		Boolean containsNoEmailMsg = false;
		for(Apexpages.Message msg : msgs) {
			if(msg.getDetail().contains(Label.No_emails_under_source_Case)) {
				containsNoEmailMsg = true;
			}
		}

		System.assert(containsNoEmailMsg, 'No email msg should be displayed');
		System.assertEquals(null, emails, 'List of emails should be null');
		System.assert(selectedEmails.isEmpty(), 'List of selected emails should be empty');
	}
}