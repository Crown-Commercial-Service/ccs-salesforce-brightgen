/*********************************************************************
 Name:  COW_ContractReferenceUtilTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: test class for COW_ContractReferenceUtil														  
 -------															
 ======================================================
 ======================================================
 History															
 -------															
 VERSION  AUTHOR			DATE			DETAIL				Description
   1.0   Klea Kolaric		2016-04-01		Initial version 	US596
   1.1 	Cezary Zeleznicki	2016-10-13		Procurement reference
   											generation			US1332
   1.2	Cezary Zeleznicki 	2016-11-03		Procurement RT change
 *********************************************************************/
@isTest
private class COW_ContractReferenceUtilTest {
	
	static final String ORG_NAME = 'Test Organisation';
	static final String SUP_NAME = 'Test Supplier';
	static final String CAT_CODE_XX = 'XX';
	static final String CAT_CODE_YY = 'YY';
	static final String CURYY = Date.today().year().format().right(2);
	
	/* WARNING: there is a small chance this test will fail if run on Jan 1st 00:00h, but i hope you have better things to do */
	
	@testSetup
	static void setupTest()
	{
		// create custom setting
		insert new Contract_Reference__c(Name=CAT_CODE_XX+CURYY, Next_Number__c=1);

		insert UnitTestDataFactory.createOpsWorkflowStages();
		insert UnitTestDataFactory.createOpsWorkflowTemplates();
		
		Account org = UnitTestDataFactory.createOrganisationAccount(ORG_NAME);
		Account sup = UnitTestDataFactory.createSupplierAccount(SUP_NAME);
		insert new List<Account>{org,sup};
		
		Contact org_con = UnitTestDataFactory.createContact(org.Id);
		Contact sup_con = UnitTestDataFactory.createContact(sup.Id);
		insert new List<Contact>{org_con,sup_con};
		
		CCS_Contract__c cntr = UnitTestDataFactory.createContract(org.Id, org_con.Id, sup.Id, sup_con.Id);
		cntr.Contract_Reference__c = null;	// make sure this is empty
		insert cntr;
		
		Category__c cat = UnitTestDataFactory.createCategory('XX', 'CAS Category', 'CPV');
		cat.Category_Code__c = CAT_CODE_XX;
		Category__c cat2 = UnitTestDataFactory.createCategory('YY', 'CAS Category', 'CPV');
		cat2.Category_Code__c = CAT_CODE_YY;
		insert new List<Category__c>{cat, cat2};

		Case c = UnitTestDataFactory.createProcurementCase(org.id);
		Case c2 = c.clone();
		Case c3 = c.clone();
		Case c4 = c.clone();
		c4.Origin = 'Email';
		c4.CAS_P_Category__c = cat.Id;
		insert new List<Case>{c, c2, c3, c4};

	}
	
	static testMethod void testPopulateRefrence_generateRef_caseUpdated()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		
		Test.startTest();
		COW_ContractReferenceUtil.populateRefrence(c.Id,CAT_CODE_XX);
		Test.stopTest();
		
		c = [select Id, Procurement_Reference__c from Case where id = :c.Id limit 1];
		String procRef = COW_ContractReferenceUtil.CC_PREFIX + CAT_CODE_XX + CURYY + 'A02';	// we're starting from number 2
		system.assertEquals(procRef,c.Procurement_Reference__c,'Case procurement reference should calculate correctly.');
		
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE_XX + CURYY) limit 1];
		system.assertEquals(3,cr.Next_Number__c,'Counter should have been increased.');
	}
	
	static testMethod void testPopulateRefrence_generateRef_contractUpdated()
	{
		CCS_Contract__c cntr = [select Id from CCS_Contract__c where Customer__r.Name = :ORG_NAME limit 1];
		
		Test.startTest();
		COW_ContractReferenceUtil.populateRefrence(cntr.Id,CAT_CODE_XX);
		Test.stopTest();
		
		cntr = [select Id, Contract_Reference__c from CCS_Contract__c where id = :cntr.Id limit 1];
		String procRef = COW_ContractReferenceUtil.CC_PREFIX + CAT_CODE_XX + CURYY + 'A02';	// we're starting from number 2
		system.assertEquals(procRef,cntr.Contract_Reference__c,'Contract reference should calculate correctly.');
		
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE_XX + CURYY) limit 1];
		system.assertEquals(3,cr.Next_Number__c,'Counter should have been increased.');
	}
	
	static testMethod void testGenerateReference_severalRequests_counterUpdatedAccordingly()
	{
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE_XX + CURYY) limit 1];
		
		Integer n = 20;	// number of iterations
		Test.startTest();
		for(Integer i = 2; i <= n; i++)
		{
			String ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
			system.assertEquals('A' + (i < 10 ? '0' : '') + i, ref.right(3), 'Letter should be the same, but counter increases.');
			system.assertEquals(i+1, cr.Next_Number__c, 'Next_Number__c needs to increase.');
		}
		Test.stopTest();
	}
	
	static testMethod void testGenerateReference_reach100_changeToNextLetter()
	{
		Contract_Reference__c cr = [select Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE_XX + CURYY) limit 1];
		cr.Next_Number__c = 99;
		update cr;
		
		Test.startTest();
		String ref;
		ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
		system.assertEquals('A99', ref.right(3), '99 should produce A99.');
		ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
		system.assertEquals('A00', ref.right(3), '100 should produce A00.');
		ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
		system.assertEquals('B01', ref.right(3), '101 should produce B01.');
		Test.stopTest();
	}
	
	static testMethod void testGenerateReference_reach2600_throwException()
	{
		Contract_Reference__c cr = [select Id, Next_Number__c from Contract_Reference__c where Name = :(CAT_CODE_XX + CURYY) limit 1];
		cr.Next_Number__c = 2600;
		update cr;
		
		Test.startTest();
		String ref;
		ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
		system.assertEquals('Z00', ref.right(3), '2600 should produce Z00.');
		system.assertEquals(0, cr.Next_Number__c, 'When maximum reached number should revert to 0.');
		
		Boolean hadError = false;
		try
		{
			ref = COW_ContractReferenceUtil.generateReference(CAT_CODE_XX,CURYY,cr);
		}
		catch(COW_ContractReferenceUtil.GenerateReferenceException e)
		{
			hadError = true;
			system.assert(e.getMessage().contains('maximum'),'Correct error should be thrown.');
		}
		system.assert(hadError,'An error should be thrown.');
		Test.stopTest();
	}
	
	static testMethod void testPopulateRefrence_faultyCategoryCode_throwException()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		Test.startTest();
		Boolean hadError = false;
		try
		{
			COW_ContractReferenceUtil.populateRefrence(c.Id,'D2');
		}
		catch(COW_ContractReferenceUtil.GenerateReferenceException e)
		{
			hadError = true;
			system.assert(e.getMessage().contains('2 letters'),'Correct error should be thrown.');
		}
		Test.stopTest();
		system.assert(hadError,'An error should be thrown.');
	}
	
	static testMethod void testPopulateRefrence_caseAlreadyHasRef_throwException()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		COW_ContractReferenceUtil.populateRefrence(c.Id,CAT_CODE_XX);	// populate ref
		
		Test.startTest();
		Boolean hadError = false;
		try
		{
			COW_ContractReferenceUtil.populateRefrence(c.Id,CAT_CODE_XX);
		}
		catch(COW_ContractReferenceUtil.GenerateReferenceException e)
		{
			hadError = true;
			system.assert(e.getMessage().contains('already'),'Correct error should be thrown.');
		}
		Test.stopTest();
		system.assert(hadError,'An error should be thrown.');
	}
	
	static testMethod void testPopulateRefrence_unrecognisedCategoryCode_throwException()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		String newCatCode = 'YY';
		system.assertNotEquals(CAT_CODE_XX,newCatCode,'New category code needs to be different.');
		
		Test.startTest();
		Boolean hadError = false;
		try
		{
			COW_ContractReferenceUtil.populateRefrence(c.Id,newCatCode);
		}
		catch(COW_ContractReferenceUtil.GenerateReferenceException e)
		{
			hadError = true;
			system.assert(e.getMessage().contains('counter'),'Correct error should be thrown.');
		}
		Test.stopTest();
		system.assert(hadError,'An error should be thrown.');
	}
	
	static testMethod void testPopulateRefrence_blankCategoryCode_throwException()
	{
		Case c = [select Id from Case where Account.Name = :ORG_NAME limit 1];
		
		Test.startTest();
		Boolean hadError = false;
		try
		{
			COW_ContractReferenceUtil.populateRefrence(c.Id,null);
		}
		catch(COW_ContractReferenceUtil.GenerateReferenceException e)
		{
			hadError = true;
			system.assert(e.getMessage().contains('populate'),'Correct error should be thrown.');
		}
		Test.stopTest();
		system.assert(hadError,'An error should be thrown.');
	}

	static testMethod void test_populateReference_FromTrigger() {
		List<Case> cases = [
			SELECT Id, Procurement_Reference__c, CAS_Category_Code__c
			FROM Case
			WHERE Origin = 'Phone'
		];
		Category__c cat = [
			SELECT Id, Name, Category_Code__c
			FROM Category__c
			WHERE Name = :CAT_CODE_XX
			LIMIT 1
		];

		for(Case c : cases) {
			c.CAS_P_Category__c = cat.Id;
		}

		Test.startTest();
		update cases;
		Test.stopTest();

		for(Case c : [
			SELECT Id, Procurement_Reference__c, CAS_Category_Code__c
			FROM Case
			WHERE Id IN :cases
		]) {
			System.assertNotEquals(null, c.Procurement_Reference__c);
		}

		Contract_Reference__c contractReference = [
			SELECT Next_Number__c, Name 
			FROM Contract_Reference__c 
			WHERE Name = :CAT_CODE_XX + CURYY
			LIMIT 1
		];
		System.assertEquals(5, (Integer) contractReference.Next_Number__c);
	}

	static testMethod void test_populateReference() {
		List<Case> cases = [
			SELECT Id, Procurement_Reference__c, CAS_Category_Code__c
			FROM Case
			WHERE Origin = 'Email'
		];

		Test.startTest();
		COW_ContractReferenceUtil.populateReference(cases);
		Test.stopTest();

		for(Case c : [
			SELECT Id, Procurement_Reference__c, CAS_Category_Code__c
			FROM Case
			WHERE Id IN :cases
		]) {
			System.assertNotEquals(null, c.Procurement_Reference__c);
		}
		Contract_Reference__c contractReference = [
			SELECT Next_Number__c, Name 
			FROM Contract_Reference__c 
			WHERE Name = :CAT_CODE_XX + CURYY
			LIMIT 1
		];
		System.assertEquals(3, (Integer) contractReference.Next_Number__c);
	}

	static testMethod void test_populateReference_throwException() {
		Boolean hadError = false;
		List<Case> cases = [
			SELECT Id, Procurement_Reference__c, CAS_Category_Code__c
			FROM Case
			WHERE Origin = 'Phone'
		];
		Category__c cat = [
			SELECT Id, Name, Category_Code__c
			FROM Category__c
			WHERE Name = :CAT_CODE_YY
			LIMIT 1
		];

		for(Case c : cases) {
			c.CAS_P_Category__c = cat.Id;
		}

		Test.startTest();
		try {
			COW_ContractReferenceUtil.populateReference(cases);
		} catch(COW_ContractReferenceUtil.GenerateReferenceException e) {
			hadError = true;
			system.assert(e.getMessage().contains('sequence'),'Correct error should be thrown.');
		}
		Test.stopTest();

		Contract_Reference__c contractReference = [
			SELECT Next_Number__c, Name 
			FROM Contract_Reference__c 
			WHERE Name = :CAT_CODE_XX + CURYY
			LIMIT 1
		];
		System.assertEquals(2, (Integer) contractReference.Next_Number__c);
		System.assert(hadError,'An error should be thrown.');
	}
}