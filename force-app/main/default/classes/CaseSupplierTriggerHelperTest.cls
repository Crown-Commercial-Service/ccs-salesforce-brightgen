/*********************************************************************
 Name:  CaseSupplierTriggerHelperTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: test class for CaseSupplierTriggerHelper                                                         
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-07		Initial version 	US601
   1.1 	 Cezary Zeleznicki	2016-11-04		Procurement RT change
 *********************************************************************/
@isTest
private class CaseSupplierTriggerHelperTest {
	
	static final String ORG_NAME = 'Test Organisation';
	static final String SUP_NAME = 'Test Supplier';
	
	@testSetup
	static void setupTest()
	{
		// create custom settings
		insert UnitTestDataFactory.createOpsWorkflowStages();
		List<Ops_Workflow_Templates__c> wftmps = UnitTestDataFactory.createOpsWorkflowTemplates();
		for(Ops_Workflow_Templates__c wftmp : wftmps) {
			wftmp.Record_Type_Name__c = CaseSupplierTriggerHelper.PL_CALLOFFDIRECTAWARD;
		}
		insert wftmps;
		
		Account org = UnitTestDataFactory.createOrganisationAccount(ORG_NAME);
		Account sup = UnitTestDataFactory.createSupplierAccount(SUP_NAME);
		insert new List<Account>{org,sup};
		
		Master_Framework__c mf = new Master_Framework__c(Name='Mater Framework');
		insert mf;
		Master_Framework_Lot__c mfl = new Master_Framework_Lot__c(Name='Lot 1234', Master_Framework_Lot_Number__c='1234', Master_Framework__c=mf.id);
		insert mfl;
		
		Case c = UnitTestDataFactory.createProcurementCase(org.id);
		c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId(CaseSupplierTriggerHelper.PL_CALLOFFDIRECTAWARD);
		c.Framework__c = mf.Id;
		c.Framework_Lot__c = mfl.id;
		insert c;
		
		insert new Supplier_Framework_Lot__c(Master_Framework_Lot__c=mfl.id, Supplier__c=sup.id);
	}
	
	static testMethod void testValidationForCallOffDirectAward_HappyPath_supplierAddedToCase()
	{
		Case c = [select id from Case where Account.Name = :ORG_NAME limit 1];
		Account supp = [select id from Account where Name = :SUP_NAME limit 1];
		
		Test.startTest();
		insert new Case_Supplier__c(Procurement__c=c.Id, Supplier__c=supp.Id);
		Test.stopTest();
		system.assertEquals(1,[select count() from Case_Supplier__c where Procurement__c = :c.Id and Supplier__c = :supp.Id],
			'Case Supplier should be created.');
	}
	
	static testMethod void testValidationForCallOffDirectAward_noFrameworkLot_throwException()
	{
		Case c = [select id, Framework_Lot__c from Case where Account.Name = :ORG_NAME limit 1];
		c.Framework_Lot__c = null;
		update c;
		Account supp = [select id from Account where Name = :SUP_NAME limit 1];
		
		Test.startTest();
		Boolean hadError = false;
		try
		{
			insert new Case_Supplier__c(Procurement__c=c.Id, Supplier__c=supp.Id);
		}
		catch(exception e)
		{
			hadError = true;
		}
		Test.stopTest();
		system.assert(hadError,'Exception should have been thrown.');
	}
	
	static testMethod void testValidationForCallOffDirectAward_supplerNotOnFrameworkLot_throwException()
	{
		Case c = [select id, Framework_Lot__c from Case where Account.Name = :ORG_NAME limit 1];
		Account supp = [select id from Account where Name = :SUP_NAME limit 1];
		delete [select id from Supplier_Framework_Lot__c];	// remove framework lot-supplier association
		
		Test.startTest();
		Boolean hadError = false;
		try
		{
			insert new Case_Supplier__c(Procurement__c=c.Id, Supplier__c=supp.Id);
		}
		catch(exception e)
		{
			hadError = true;
		}
		Test.stopTest();
		system.assert(hadError,'Exception should have been thrown.');
	}
    
}