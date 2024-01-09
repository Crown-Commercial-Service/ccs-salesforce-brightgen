/*********************************************************************
 Name:  PostRefreshWorker_Test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Test class for PostRefreshWorker
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
	1.0  Cezary Zeleznicki  2016-11-14     Initial version
 *********************************************************************/
@isTest
private class PostRefreshWorker_Test {
	private final static String MOCK_SANDBOX_ID = '00D4E0000000SGrUAM';

	static void createData() {
		Account accOrg = UnitTestDataFactory.createOrganisationAccount(PostRefreshWorker.CROWN_COMMERCIAL_NAME);
		Account accSupp = UnitTestDataFactory.createSupplierAccount(PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES[0]);
		insert new List<Account>{accOrg, accSupp};

		SlaProcess entProcess = [
			SELECT Id, Name 
			FROM SlaProcess 
			WHERE Name LIKE :PostRefreshWorker.CURRENT_ENTITLEMENT_PROCESS+'%' 
				AND isActive = true AND isVersionDefault = true 
			LIMIT 1
		];

		Entitlement ent = new Entitlement(
			Name = 'Entitlement Test', 
			AccountId = accOrg.Id, 
			SlaProcess = entProcess
		);
		insert ent;
	}

	static testMethod void test_runApexClass() {
		Test.startTest();
		PostRefreshWorker prw = new PostRefreshWorker();
		Test.testSandboxPostCopyScript(prw, MOCK_SANDBOX_ID, 
			MOCK_SANDBOX_ID, 'TestSandbox');
		Test.stopTest();

		Map<Id, Account> id2OrgAccount = new Map<Id, Account>([
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.ORG_ACCUOUNT_NAMES
		]);
		Map<Id, Account> id2SupplierAccount = new Map<Id, Account>([
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES
		]);
		List<Trigger_Switch__c> triggerSwitches = [
			SELECT Id, Case__c, Attachment__c, CaseSupplier__c, EmailMessage__c, MasterFrameworkLot__c
			FROM Trigger_Switch__c
		];

		Org_Settings__c orgSettings = [
			SELECT SetupOwnerId, ORG_URL__c, Entitlement_ID__c
			FROM Org_Settings__c
			WHERE SetupOwnerId = :UserInfo.getOrganizationId()
			LIMIT 1
		];

		Entitlement exEnt = [
			SELECT Id, Name 
			FROM Entitlement 
			WHERE Name = 'Entitlement Test' 
			LIMIT 1
		];

		Boolean contanainsContactForHo = false;
		Boolean containsContactForDeptOfWork = false;
		Boolean containsContactForSupplier = false;
		for(Contact cont : [SELECT Id, Account.Name FROM Contact]) {
			if(cont.Account.Name == PostRefreshWorker.HOME_OFFICE_NAME) {
				contanainsContactForHo = true;
			}
			if(cont.Account.Name == PostRefreshWorker.DEPT_OF_WORK_NAME) {
				containsContactForDeptOfWork = true;
			}
			if(cont.Account.Name == PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES[0]) {
				containsContactForSupplier = true;
			}
		}

		CCS_Contract__c ccsContract = [
			SELECT Id, Customer__r.Name, Customer_Contact__r.Name, Supplier__r.Name, 
				Supplier_Contact__r.Name
			FROM CCS_Contract__c
			LIMIT 1
		];

		List<Category__c> catL1 = [
			SELECT Id, Name, CategoryType__c, Code_Type__c
			FROM Category__c
			WHERE CategoryType__c = 'CAS Master Category' OR
				CategoryType__c = 'Pillar'
		];

		List<Category__c> catL2 = [
			SELECT Id, Name, CategoryType__c, Code_Type__c
			FROM Category__c
			WHERE (CategoryType__c = 'CAS Category' OR
				CategoryType__c = 'CCS Category')
				AND Parent__c IN :catL1
		];

		List<Category__c> catL3 = [
			SELECT Id, Name, CategoryType__c, Code_Type__c
			FROM Category__c
			WHERE (CategoryType__c = 'CAS Sub Category' OR
				CategoryType__c = 'CCS Sub Category')
				AND Parent__c IN :catL2
		];

		List<Category__c> catL4 = [
			SELECT Id, Name, CategoryType__c, Code_Type__c
			FROM Category__c
			WHERE CategoryType__c = 'Code'
				AND (Code_Type__c = 'CPV' OR 
					Code_Type__c = 'UNSPSC')
				AND Parent__c IN :catL3
		];

		Level_4_Categorisation_Code_for_Contract__c l4cat = [
			SELECT Id, Code__c, CCS_Contract__c
			FROM Level_4_Categorisation_Code_for_Contract__c
			WHERE Code__c IN :catL4
				AND CCS_Contract__c = :ccsContract.Id
			LIMIT 1
		];

		Master_Framework__c mf = [
			SELECT Id, Name
			FROM Master_Framework__c
			WHERE Name = 'Test Framework 1'
			LIMIT 1
		];

		List<Master_Framework_Lot__c> masterFrameworkLots = [
			SELECT Id, Name, Master_Framework__c
			FROM Master_Framework_Lot__c
			WHERE Master_Framework__c = :mf.Id
				AND Name LIKE :mf.Name + '%'
		];

		List<Supplier_Framework_Lot__c> supplierFramworkLots = [
			SELECT Id, Name, Master_Framework_Lot__c
			FROM Supplier_Framework_Lot__c
			WHERE Master_Framework_Lot__c IN :masterFrameworkLots
		];

		System.assert(!triggerSwitches.isEmpty(), 'Trigger switch');
		System.assertEquals(System.URL.getOrgDomainUrl().toExternalForm(), orgSettings.ORG_URL__c,
			'Org settings should be updated with base url');
		System.assert(!String.isBlank(orgSettings.Entitlement_ID__c), 
			'Org settings should be udated with entitlement Id');
		System.assertNotEquals(0, id2OrgAccount.size(), 'Org accounts should be created');
		System.assertNotEquals(0, id2SupplierAccount.size(), 'Supplier accounts should be created');
		System.assertNotEquals(null, exEnt, 'Entitlement should be inserted');
		System.assert(contanainsContactForHo, 'Contact for Home Office exists');
		System.assert(containsContactForDeptOfWork, 'Contact for Dep of Work exists');
		System.assert(containsContactForSupplier, 'Contact for ' + PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES[0] + ' exists');
		System.assertNotEquals(null, ccsContract, 'CCS Contract should be created');
		System.assertEquals(2, catL1.size(), 'Two level 1 categories should be created');
		System.assertEquals(2, catL2.size(), 'Two level 2 categories should be created');
		System.assertEquals(2, catL3.size(), 'Two level 3 categories should be created');
		System.assertEquals(2, catL4.size(), 'Two level 4 categories should be created');
		System.assertNotEquals(null, l4cat, 'Level 4 categorisation should be created');
		System.assertNotEquals(null, mf, 'Master Framework should be created');
		//System.assertEquals(null, masterFrameworkLots);
		System.assertEquals(2, masterFrameworkLots.size(), 'Two Master Framwork Lots should be created');
		System.assertEquals(4, supplierFramworkLots.size(), 
			'Four Supplier Framework Lots should be created, 2 for each Master Framwork Lot');
		System.assert(prw.summaryMessage.toString().contains('Querying Accounts'), 'Summary Message contains query for Accounts');
		System.assert(prw.summaryMessage.toString().contains('No of Accounts'), 'Summary Message contains No of Accounts');	
		System.assert(prw.summaryMessage.toString().contains('Updating OrgSetting'), 'Summary Message contains Updating OrgSetting');	
		System.assert(prw.summaryMessage.toString().contains('Creating Accounts'), 'Summary Message contains Creating Accounts');	
		System.assert(prw.summaryMessage.toString().contains('Querying for Entitlements'), 'Summary Message contains Querying for Entitlements');	
		System.assert(prw.summaryMessage.toString().contains('No of Entitlements'), 'Summary Message contains No of Entitlements');	
		System.assert(prw.summaryMessage.toString().contains('Creating Entitlements'), 'Summary Message contains Creating Entitlements');	
		System.assert(prw.summaryMessage.toString().contains('Creating Contacts'), 'Summary Message contains Creating Contacts');	
		System.assert(prw.summaryMessage.toString().contains('Creating CCS Contract'), 'Summary Message contains Creating CCS Contract');	
		System.assert(prw.summaryMessage.toString().contains('Creating Categories'), 'Summary Message contains Creating Category');	
		System.assert(prw.summaryMessage.toString().contains('Creating Level 4 Categorisation Code for Contract'), 
			'Summary Message contains Creating Level 4 Categorisation Code for Contract');	
		System.assert(prw.summaryMessage.toString().contains('Creating Frameworks'), 'Summary Message contains Creating Frameworks');	
		System.assert(prw.summaryMessage.toString().contains('Updating Trigger Switch'), 'Summary Message contains Updating Trigger Switch');
	}
	static testMethod void test_runApexClass_ManualRun() {
		Category__c c = UnitTestDataFactory.createCategory('Test master cat', 'CAS Master Category', '');
		insert c;

		Test.startTest();
		PostRefreshWorker prw = new PostRefreshWorker();
		prw.runApexClass();
		Test.stopTest();

		Map<Id, Account> id2OrgAccount = new Map<Id, Account>([
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.ORG_ACCUOUNT_NAMES
		]);
		Map<Id, Account> id2SupplierAccount = new Map<Id, Account>([
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES
		]);
		List<Trigger_Switch__c> triggerSwitches = [
			SELECT Id, Case__c, Attachment__c, CaseSupplier__c, EmailMessage__c, MasterFrameworkLot__c
			FROM Trigger_Switch__c
		];

		Org_Settings__c orgSettings = [
			SELECT SetupOwnerId, ORG_URL__c, Entitlement_ID__c
			FROM Org_Settings__c
			WHERE SetupOwnerId = :UserInfo.getOrganizationId()
			LIMIT 1
		];

		Entitlement exEnt = [
			SELECT Id, Name 
			FROM Entitlement 
			WHERE Name = 'Entitlement Test' 
			LIMIT 1
		];

		Boolean contanainsContactForHo = false;
		Boolean containsContactForDeptOfWork = false;
		Boolean containsContactForSupplier = false;
		for(Contact cont : [SELECT Id, Account.Name FROM Contact]) {
			if(cont.Account.Name == PostRefreshWorker.HOME_OFFICE_NAME) {
				contanainsContactForHo = true;
			}
			if(cont.Account.Name == PostRefreshWorker.DEPT_OF_WORK_NAME) {
				containsContactForDeptOfWork = true;
			}
			if(cont.Account.Name == PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES[0]) {
				containsContactForSupplier = true;
			}
		}

		CCS_Contract__c ccsContract = [
			SELECT Id, Customer__r.Name, Customer_Contact__r.Name, Supplier__r.Name, 
				Supplier_Contact__r.Name
			FROM CCS_Contract__c
			LIMIT 1
		];

		Category__c category = [
			SELECT Id, Name, CategoryType__c, Code_Type__c
			FROM Category__c
			WHERE CategoryType__c = 'Code'
				AND Code_Type__c = 'CPV'
			LIMIT 1
		];

		Level_4_Categorisation_Code_for_Contract__c l4cat = [
			SELECT Id, Code__c, CCS_Contract__c
			FROM Level_4_Categorisation_Code_for_Contract__c
			WHERE Code__c = :category.Id
				AND CCS_Contract__c = :ccsContract.Id
			LIMIT 1
		];

		Master_Framework__c mf = [
			SELECT Id, Name
			FROM Master_Framework__c
			WHERE Name = 'Test Framework 1'
			LIMIT 1
		];

		List<Master_Framework_Lot__c> masterFrameworkLots = [
			SELECT Id, Name, Master_Framework__c
			FROM Master_Framework_Lot__c
			WHERE Master_Framework__c = :mf.Id
				AND Name LIKE :mf.Name + '%'
		];

		List<Supplier_Framework_Lot__c> supplierFramworkLots = [
			SELECT Id, Name, Master_Framework_Lot__c
			FROM Supplier_Framework_Lot__c
			WHERE Master_Framework_Lot__c IN :masterFrameworkLots
		];

		System.assert(!triggerSwitches.isEmpty(), 'Trigger switch');
		System.assertEquals(System.URL.getOrgDomainUrl().toExternalForm(), orgSettings.ORG_URL__c,
			'Org settings should be updated with base url');
		System.assert(!String.isBlank(orgSettings.Entitlement_ID__c), 
			'Org settings should be udated with entitlement Id');
		System.assertNotEquals(0, id2OrgAccount.size(), 'Org accounts should be created');
		System.assertNotEquals(0, id2SupplierAccount.size(), 'Supplier accounts should be created');
		System.assertNotEquals(null, exEnt, 'Entitlement should be inserted');
		System.assert(contanainsContactForHo, 'Contact for Home Office exists');
		System.assert(containsContactForDeptOfWork, 'Contact for Dep of Work exists');
		System.assert(containsContactForSupplier, 'Contact for ' + PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES[0] + ' exists');
		System.assertNotEquals(null, ccsContract, 'CCS Contract should be created');
		System.assertNotEquals(null, category, 'Category should be created');
		System.assertNotEquals(null, l4cat, 'Level 4 categorisation should be created');
		System.assertNotEquals(null, mf, 'Master Framework should be created');
		//System.assertEquals(null, masterFrameworkLots);
		System.assertEquals(2, masterFrameworkLots.size(), 'Two Master Framwork Lots should be created');
		System.assertEquals(4, supplierFramworkLots.size(), 
			'Four Supplier Framework Lots should be created, 2 for each Master Framwork Lot');
	}

	static testMethod void test_runApexClass_twoPasses() {
		createData();

		Test.startTest();
		PostRefreshWorker prw = new PostRefreshWorker();
		Test.testSandboxPostCopyScript(prw, MOCK_SANDBOX_ID, 
			MOCK_SANDBOX_ID, 'TestSandbox');
		Test.stopTest();

		List<Entitlement> exEnt = [
			SELECT Id, Name 
			FROM Entitlement 
			WHERE Name = 'Entitlement Test' 
				ORDER BY CreatedDate ASC
		];

		Org_Settings__c orgSettings = [
			SELECT SetupOwnerId, ORG_URL__c, Entitlement_ID__c
			FROM Org_Settings__c
			WHERE SetupOwnerId = :UserInfo.getOrganizationId()
			LIMIT 1
		];

		List<Account> orgAccounts = [
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.ORG_ACCUOUNT_NAMES 
		];

		List<Account> suppAccounts = [
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES
		];

		System.assertEquals(exEnt[0].Id, orgSettings.Entitlement_ID__c, 
			'Org setting should be updated with already existing Entitlement Id');
		System.assertEquals(3, orgAccounts.size(), 'Only three org accounts should exist');
		System.assertEquals(6, suppAccounts.size(), 'Only six org accounts should exist');
	}

	static testMethod void test_runApexClass_Exception() {
		PostRefreshWorker prw = new PostRefreshWorker();

		Test.startTest();
		prw.ts = new Trigger_Switch__c(Id = 'a0p26000000cKyVAAU');
		Test.testSandboxPostCopyScript(prw, MOCK_SANDBOX_ID, 
			MOCK_SANDBOX_ID, 'TestSandbox');
		Test.stopTest();

		List<Entitlement> exEnt = [
			SELECT Id, Name 
			FROM Entitlement 
			WHERE Name = 'Entitlement Test' 
				ORDER BY CreatedDate ASC
		];

		List<Org_Settings__c> orgSettings = [
			SELECT SetupOwnerId, ORG_URL__c, Entitlement_ID__c
			FROM Org_Settings__c
			WHERE SetupOwnerId = :UserInfo.getOrganizationId()
		];

		List<Account> orgAccounts = [
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.ORG_ACCUOUNT_NAMES 
		];

		List<Account> suppAccounts = [
			SELECT Id, Name
			FROM Account
			WHERE Name IN :PostRefreshWorker.SUPPLIER_ACCOUNT_NAMES
		];

		System.assert(orgSettings.isEmpty(), 'No Org settings data should exist');
		System.assertEquals(0, orgAccounts.size(), 'No org accounts should exist');
		System.assertEquals(0, suppAccounts.size(), 'No supplier accounts should exist');
		System.assert(prw.summaryMessage.toString().contains('exception'), 'Summary Message contains exception');
	}
}