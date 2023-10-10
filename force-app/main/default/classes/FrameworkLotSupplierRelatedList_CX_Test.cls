/*********************************************************************
 Name:  FrameworkLotSupplierRelatedList_CX_test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller extension for FrameworkLotSupplierRelatedList
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-12-02     Initial version
 *********************************************************************/
@isTest
private class FrameworkLotSupplierRelatedList_CX_Test {
	@testSetup
	static void createData() {
		insert UnitTestDataFactory.createOpsWorkflowStages();
		insert UnitTestDataFactory.createOpsWorkflowTemplates();
		
		List<Account> supplierAccounts = new List<Account>();
		for(Integer i = 0; i <100; i++) {
			supplierAccounts.add(
				UnitTestDataFactory.createSupplierAccount('Test supplier account - FrameworkLotSupplierRelatedList ' + i));
		}
		insert supplierAccounts;

		Master_Framework__c mf = UnitTestDataFactory.createMasterFramework();
		insert mf;
		Master_Framework_Lot__c mfl = UnitTestDataFactory.createMasterFrameworkLot(mf.Id);
		insert mfl;

		List<Supplier_Framework_Lot__c> suppFrameworkLots = new List<Supplier_Framework_Lot__c>();
		for(Integer i = 0; i < 100; i++) {
			Supplier_Framework_Lot__c sfl = UnitTestDataFactory.createSupplierFrameworkLot(mfl.Id, supplierAccounts[i].Id);
			sfl.Status__c = 'Live';
			suppFrameworkLots.add(sfl);
		}
		insert suppFrameworkLots;
	}

	static testMethod void test_getSuppliers() {
		Master_Framework__c mf = [SELECT Id FROM Master_Framework__c LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(mf);
		
		PageReference pageRef = Page.FrameworkLotSupplierRelatedList;
		pageRef.getParameters().put('id', String.valueOf(mf.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FrameworkLotSupplierRelatedList_CX flsrl = new FrameworkLotSupplierRelatedList_CX(sc);
		List<FrameworkLotSupplierRelatedList_CX.SupplierWrapper> suppliers = flsrl.getSuppliers();
		Test.stopTest();

		System.assert(!suppliers.isEmpty(), 'Suppliers shouldn\'t be empty');
	}

	static testMethod void test_goBackToFramework() {
		Master_Framework__c mf = [SELECT Id FROM Master_Framework__c LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(mf);
		
		PageReference pageRef = Page.FrameworkLotSupplierRelatedList;
		pageRef.getParameters().put('id', String.valueOf(mf.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FrameworkLotSupplierRelatedList_CX flsrl = new FrameworkLotSupplierRelatedList_CX(sc);
		PageReference pr = flsrl.goBackToFramework();
		Test.stopTest();

		System.assertEquals(sc.view().getUrl() + '?inline=0', pr.getUrl(),
			'Framework view should be returned');
	}

	static testMethod void test_goToList() {
		Master_Framework__c mf = [SELECT Id FROM Master_Framework__c LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(mf);
		
		PageReference pageRef = Page.FrameworkLotSupplierRelatedList;
		pageRef.getParameters().put('id', String.valueOf(mf.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FrameworkLotSupplierRelatedList_CX flsrl = new FrameworkLotSupplierRelatedList_CX(sc);
		flsrl.getSuppliers();
		flsrl.goToList();
		Test.stopTest();

		System.assertEquals(50, flsrl.pageSize, 'Page size should be equal 50');
		System.assert(flsrl.showFullPage, 'Show full page param should be set');
	}

	static testMethod void test_SetControllerMethods() {
		Master_Framework__c mf = [SELECT Id FROM Master_Framework__c LIMIT 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(mf);
		
		PageReference pageRef = Page.FrameworkLotSupplierRelatedList;
		pageRef.getParameters().put('id', String.valueOf(mf.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FrameworkLotSupplierRelatedList_CX flsrl = new FrameworkLotSupplierRelatedList_CX(sc);
		flsrl.getSuppliers();
		Boolean hasNext = flsrl.getHasNext();
		Boolean hasPrevious = flsrl.getHasPrevious();
		Boolean isFirst = flsrl.getIsFirst();
		Integer recSize = flsrl.getRecordsSize();
		flsrl.first();
		flsrl.last();
		flsrl.previous();
		flsrl.next();
		Test.stopTest();

		System.assert(hasNext, 'Next page should be available');
		System.assert(!hasPrevious, 'Previous page should\'t be available');
		System.assert(isFirst, 'First page should be displayed');
		System.assertEquals(100, recSize, 'Record size in set controller should be 100');
		System.assertEquals(5, flsrl.pageSize, 'Page size should be equal 5');
	}

	static testMethod void test_failPath() {
		ApexPages.StandardController sc = new ApexPages.StandardController(new Master_Framework__c());
		
		PageReference pageRef = Page.FrameworkLotSupplierRelatedList;
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FrameworkLotSupplierRelatedList_CX flsrl = new FrameworkLotSupplierRelatedList_CX(sc);
		List<FrameworkLotSupplierRelatedList_CX.SupplierWrapper> suppliers = flsrl.getSuppliers();
		Test.stopTest();

		System.assertEquals(null, suppliers, 'List of suppliers should be null');
	}
}