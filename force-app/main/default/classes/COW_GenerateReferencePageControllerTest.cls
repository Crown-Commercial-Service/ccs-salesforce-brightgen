/*********************************************************************
 Name:  COW_GenerateReferencePageControllerTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: test for COW_GenerateReferencePageController                                                         
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-05		 Initial version 	US596
   1.1	 Cezary Zeleznicki 	2016-11-03		 Procurement RT change
 *********************************************************************/
@isTest
private class COW_GenerateReferencePageControllerTest {
    
    static final String ORG_NAME = 'Test Organisation';
	static final String CAT_CODE = 'ZZ';
	static final String CURYY = Date.today().year().format().right(2);
	
	@testSetup
	static void setupTest()
	{
		// create custom setting
		insert new Contract_Reference__c(Name=CAT_CODE+CURYY, Next_Number__c=1);

		insert UnitTestDataFactory.createOpsWorkflowStages();
		insert UnitTestDataFactory.createOpsWorkflowTemplates();
		
		Account org = UnitTestDataFactory.createOrganisationAccount(ORG_NAME);
		insert org;
		
		Case c = UnitTestDataFactory.createProcurementCase(org.id);
		insert c;
	}
	
	static testMethod void testGenerateRefrence_happyPath_caseUpdated()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		
		Pagereference pr = Page.COW_GenerateReferencePage;
		pr.getParameters().put(COW_GenerateReferencePageController.RECORDID_PARAM,c.Id);
		pr.getParameters().put(COW_GenerateReferencePageController.CATCODE_PARAM,CAT_CODE);
		Test.setCurrentPage(pr);
		
		Test.startTest();
		COW_GenerateReferencePageController ctrl = new COW_GenerateReferencePageController();
		system.assert(!ctrl.allowRetry, 'allowRetry sshould be false by default.');
		ctrl.actionGenerateRef();
		ctrl.backAction();
		ctrl.retryAction();
		Test.stopTest();
		
		// confirm that case and custom setting were updated
		c = [select Id, Procurement_Reference__c from Case where id = :c.Id limit 1];
		system.assertNotEquals(null,c.Procurement_Reference__c,'Case procurement reference should be populated.');
		
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE + CURYY) limit 1];
		system.assertEquals(2,cr.Next_Number__c,'Counter should have been increased.');
	}
	
	static testMethod void testGenerateRefrence_undefinedReferenceField_caseNotUpdated()
	{
		Account org = [select id from Account where name = :ORG_NAME];
		
		// create contact - this is an object for which we don't have a defined reference field
		Contact org_con = UnitTestDataFactory.createContact(org.Id);
		insert org_con;
		
		Pagereference pr = Page.COW_GenerateReferencePage;
		pr.getParameters().put(COW_GenerateReferencePageController.RECORDID_PARAM,org_con.Id);
		pr.getParameters().put(COW_GenerateReferencePageController.CATCODE_PARAM,CAT_CODE);
		Test.setCurrentPage(pr);
		
		Test.startTest();
		COW_GenerateReferencePageController ctrl = new COW_GenerateReferencePageController();
		ctrl.actionGenerateRef();
		Test.stopTest();
		
		// nothing happened as code was skipped
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE + CURYY) limit 1];
		system.assertEquals(1,cr.Next_Number__c,'Counter should not have been increased.');
	}
	
	static testMethod void testGenerateRefrence_useDummyField_errorMessageAdded()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		
		Pagereference pr = Page.COW_GenerateReferencePage;
		pr.getParameters().put(COW_GenerateReferencePageController.RECORDID_PARAM,c.Id);
		pr.getParameters().put(COW_GenerateReferencePageController.CATCODE_PARAM,CAT_CODE);
		pr.getParameters().put(COW_GenerateReferencePageController.REFFIELD_PARAM,'dummyfield');
		Test.setCurrentPage(pr);
		
		Test.startTest();
		COW_GenerateReferencePageController ctrl = new COW_GenerateReferencePageController();
		ctrl.actionGenerateRef();
		Test.stopTest();
		
		system.assertEquals(1,ApexPages.getMessages().size(), 'Error message should be added to page.');
	}
}