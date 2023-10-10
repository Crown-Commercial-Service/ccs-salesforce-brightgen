/*********************************************************************
 Name:  PostRefreshWorker
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Class used to insert test records each time
	Sandbox gets refreshed.
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
	1.0  Cezary Zeleznicki  2016-11-14     Initial version
 *********************************************************************/
global class PostRefreshWorker implements SandboxPostCopy {
	public final static String PROD_ORG_ID = '00Db0000000egy4';
	public final static String CURRENT_ENTITLEMENT_PROCESS = 'sla6';
	public final static String CROWN_COMMERCIAL_NAME = 'Crown Commercial Service Test';
	public final static String HOME_OFFICE_NAME = 'Home Office Test';
	public final static String DEPT_OF_WORK_NAME = 'Dept of Work and Pensions Test';

	private final Id ACCOUNT_ORG_RT_ID = [
		SELECT Id, SobjectType, DeveloperName 
		FROM RecordType 
		WHERE SobjectType = 'Account'
			AND DeveloperName = 'Organisation'
	].Id;
	private final Id ACCOUNT_SUP_RT_ID = [
		SELECT Id, SobjectType, DeveloperName 
		FROM RecordType 
		WHERE SobjectType = 'Account'
			AND DeveloperName = 'Supplier'
	].Id;
	private Map<String, Account> existingAccounts;
	public final static List<String> ORG_ACCUOUNT_NAMES = new List<String>{
		CROWN_COMMERCIAL_NAME, HOME_OFFICE_NAME, DEPT_OF_WORK_NAME
	};
	public final static List<String> SUPPLIER_ACCOUNT_NAMES = new List<String>{
		'Supplier 1 Test', 'Supplier 2 Test', 'Supplier 3 Test', 'Supplier 4 Test', 'Supplier 5 Test', 'Supplier 6 Test'
	};
	//consider putting object - name - type to new Metadata object
	private Org_Settings__c orgSettings;
	@testVisible
	private Trigger_switch__c ts = Trigger_Switch__c.getInstance();
	@testVisible
	private SummaryMessage summaryMessage;
	private Map<String, Category__c> catType2Cat;

	global void runApexClass() {
		Boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
		if(!isSandbox && !Test.isRunningTest()) {
			return;
		}
		run();
	}

	global void runApexClass(SandboxContext context) {
		if(context.sandboxId() == PROD_ORG_ID) {
			return;
		}
		run();
	}

	private void run() {
		summaryMessage = new SummaryMessage();
		try {
			updateTriggerSwitch(true);
			queryAccounts();
			updateOrgSettings('ORG_URL__c', System.URL.getSalesforceBaseUrl().toExternalForm());
			createAccounts();
			Id entitlementId = createEntitlement();
			updateOrgSettings('Entitlement_ID__c', entitlementId);
			List<Contact> contacts = createContacts();
			createCategories(contacts);
			createFrameworks();
			updateTriggerSwitch(false);
		} catch(Exception e) {
			summaryMessage.finish(e.getMessage());
		}
		sendSummaryEmail();
	}

	private void updateTriggerSwitch(Boolean isOff) {
		String onOff = isOff ? 'Off' : 'On';
		summaryMessage.add('Updating Trigger Switch to ' + onOff);

		if(ts == null) {
			ts = new Trigger_Switch__c();
		}

		ts.Case__c = isOff;
		ts.Attachment__c = isOff;
		ts.CaseSupplier__c = isOff;
		ts.EmailMessage__c = isOff;
		ts.MasterFrameworkLot__c = isOff;
		upsert ts;
		summaryMessage.finish();
	}

	private void queryAccounts() {
		summaryMessage.add('Querying Accounts');
		existingAccounts = new Map<String, Account>();
		List<Account> accs = [
			SELECT Id, Name
			FROM Account
			WHERE Name IN :ORG_ACCUOUNT_NAMES 
				OR Name IN :SUPPLIER_ACCOUNT_NAMES
		];

		for(Account acc : accs) {
			existingAccounts.put(acc.Name, acc);
		}
		summaryMessage.finish('No of Accounts: ' + accs.size());
	}

	private void updateOrgSettings(String name, String value) {
		summaryMessage.add('Updating OrgSetting with ' + name + ' ' + value);
		List<Org_Settings__c> orgSettingsList = [
			SELECT Id, SetupOwnerId
			FROM Org_Settings__c
			WHERE SetupOwnerId = :UserInfo.getOrganizationId()
			LIMIT 1
		];

		if(orgSettings == null) {
			orgSettings = new Org_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
		}

		if(!orgSettingsList.isEmpty()) {
			orgSettings.Id = orgSettingsList[0].Id;
		}

		orgSettings.put(name, value);
		upsert orgSettings;
		summaryMessage.finish();
	}

	private void createAccounts() {
		summaryMessage.add('Creating Accounts');
		List<Account> accs = new List<Account>();
		for(String accName : ORG_ACCUOUNT_NAMES) {
			if(existingAccounts.containsKey(accName)) {
				continue;
			}
			accs.add(createOrganisationAccount(accName));
		}

		for(String accName : SUPPLIER_ACCOUNT_NAMES) {
			if(existingAccounts.containsKey(accName)) {
				continue;
			}
			accs.add(createSupplierAccount(accName));
		}

		insert accs;
		summaryMessage.finish();
		for(Account acc : accs) {
			existingAccounts.put(acc.Name, acc);
		}
	}

	private Id createEntitlement() {
		summaryMessage.add('Querying for Entitlements');
		SlaProcess entProcess = [
			SELECT Id, Name 
			FROM SlaProcess 
			WHERE Name LIKE :CURRENT_ENTITLEMENT_PROCESS+'%' 
				AND isActive = true AND isVersionDefault = true 
			LIMIT 1
		];
		List<Entitlement> exEnt = [
			SELECT Id, Name 
			FROM Entitlement 
			WHERE Name = 'Entitlement Test' 
			LIMIT 1
		];
		summaryMessage.finish('No of Entitlements: ' + exEnt.size());
		if(!exEnt.isEmpty()) {
			return exEnt[0].Id;
		}
		summaryMessage.add('Creating Entitlements');
		Entitlement ent = new Entitlement(Name = 'Entitlement Test', 
			AccountId = existingAccounts.get(CROWN_COMMERCIAL_NAME).Id, SlaProcessId = entProcess.Id,
			StartDate = System.today());
		insert ent;
		summaryMessage.finish();
		return ent.Id;
	}

	private List<Contact> createContacts() {
		List<Contact> contacts = new List<Contact>();
		summaryMessage.add('Creating Contacts');
		contacts = [
			SELECT Id
			FROM Contact
			WHERE AccountId =: existingAccounts.get(HOME_OFFICE_NAME).Id 
				OR AccountId =: existingAccounts.get(DEPT_OF_WORK_NAME).Id
				OR AccountId =: existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id
		];

		if(contacts.size() != 3) {
			contacts.add(createContact(existingAccounts.get(HOME_OFFICE_NAME).Id));
			contacts.add(createContact(existingAccounts.get(DEPT_OF_WORK_NAME).Id));
			contacts.add(createContact(existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id));
			insert contacts;
		}
		
		summaryMessage.finish();
		return contacts;
	}

	private void createCategories(List<Contact> contacts) {
		summaryMessage.add('Creating CCS Contract');
		List<CCS_Contract__c> ccsContracts = [
			SELECT Id, Customer__c, Customer_Contact__c, Supplier__c, Supplier_Contact__c 
			FROM CCS_Contract__c 
			WHERE Customer__c =: existingAccounts.get(HOME_OFFICE_NAME).Id
				AND Customer_Contact__c =: contacts[0].Id
				AND Supplier__c =: existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id
				AND Supplier_Contact__c =: contacts[2].Id
		];
		CCS_Contract__c ccsContract;
		if(ccsContracts.isEmpty()) {
			ccsContract = createContract(existingAccounts.get(HOME_OFFICE_NAME).Id, contacts[0].Id, 
				existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id, contacts[2].Id);
			insert ccsContract;
		} else {
			ccsContract = ccsContracts[0];
		}
		
		summaryMessage.finish();

		summaryMessage.add('Creating Categories');
		queryCategories();
		List<Category__c> l1 = createLevel1Categories();
		List<Category__c> l2 = createLevel2Categories(l1);
		List<Category__c> l3 = createLevel3Categories(l2);
		List<Category__c> l4 = createLevel4Categories(l3[0]);
		summaryMessage.finish();

		summaryMessage.add('Creating Level 4 Categorisation Code for Contract');
		List<Level_4_Categorisation_Code_for_Contract__c> l4cats = [
			SELECT Id, Code__c, CCS_Contract__c
			FROM Level_4_Categorisation_Code_for_Contract__c
			WHERE Code__c =: l4[0].Id
				AND CCS_Contract__c =: ccsContract.Id
		];

		if(l4cats.isEmpty()) {
			Level_4_Categorisation_Code_for_Contract__c l4cat = createCatContract(l4[0].Id, ccsContract.Id);
			insert l4cat;
		}
		summaryMessage.finish();
	}

	private void queryCategories() {
		if(catType2Cat == null) {
			catType2Cat = new Map<String, Category__c>();
		}

		List<Category__c> cats = [
			SELECT Id, Name, CategoryType__c, Code_Type__c, Parent__c, Cat_External_ID__c
			FROM Category__c
			LIMIT 500
		];

		for(Category__c c : cats) {
			catType2Cat.put(c.CategoryType__c, c);
		}
	}

	private Category__c fetchCategory(Category__c newCat) {
		Category__c c;
		if(!catType2Cat.containsKey(newCat.CategoryType__c)) {
			return newCat;
		}
		c = catType2Cat.get(newCat.CategoryType__c);
		if(c.Code_Type__c == newCat.Code_Type__c && c.Parent__c == newCat.Parent__c && 
			c.Cat_External_ID__c == newCat.Cat_External_ID__c && c.Name == newCat.Name) {
			return c;
		}
		return newCat;
	}

	private void createFrameworks() {
		summaryMessage.add('Creating Frameworks');
		String mfName = 'Test Framework 1';
		List<Master_Framework__c> mfs = [
			SELECT Id, Name, Status__c
			FROM Master_Framework__c
			WHERE Name =: mfName
				AND Status__c = 'Active'
		];

		Master_Framework__c mf;
		if(mfs.isEmpty()) {
			mf = createMasterFramework(mfName);
			insert mf;
		} else {
			mf = mfs[0];
		}

		List<Master_Framework_Lot__c> masterFrameworkLots = new List<Master_Framework_Lot__c>();
		masterFrameworkLots = [
			SELECT Id, Master_Framework__c, Name
			FROM Master_Framework_Lot__c
			WHERE Name LIKE :mf.Name +'%'
				AND Master_Framework__c =: mf.Id
		];

		if(masterFrameworkLots.size() < 2) {
			Master_Framework_Lot__c mfl = createMasterFrameworkLot(mf.Id, mf.Name + ' Lot 1');
			Master_Framework_Lot__c mfl2 = createMasterFrameworkLot(mf.Id, mf.Name + ' Lot 2');
			masterFrameworkLots.add(mfl);
			masterFrameworkLots.add(mfl2);
			insert masterFrameworkLots;
		}

		List<Supplier_Framework_Lot__c> supplierFrameworkLots = new List<Supplier_Framework_Lot__c> ();
		supplierFrameworkLots = [
			SELECT Id, Master_Framework_Lot__c, Supplier__c
			FROM Supplier_Framework_Lot__c
			WHERE Master_Framework_Lot__c IN :masterFrameworkLots
				AND (Supplier__c =: existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id 
					OR Supplier__c =: existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[1]).Id)
		];

		if(supplierFrameworkLots.size() < 4) {
			for(Master_Framework_Lot__c mfLot : masterFrameworkLots){
				supplierFrameworkLots.add(createSupplierFrameworkLot(mfLot.Id, existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[0]).Id));
				supplierFrameworkLots.add(createSupplierFrameworkLot(mfLot.Id, existingAccounts.get(SUPPLIER_ACCOUNT_NAMES[1]).Id));
			}
			insert supplierFrameworkLots;
		}
		
		summaryMessage.finish();
	}

	private Account createOrganisationAccount(String accountName){
		Account org = new Account(RecordTypeId = ACCOUNT_ORG_RT_ID);
		org.Name = String.isNotBlank(accountName) ? accountName : 'Customer-' + getRandomString(8);
		org.Status__c = 'Active';
		org.Sector__c = 'Health';
		return org;
	}

	private Account createSupplierAccount(String accountName){
		Account org = new Account(RecordTypeId = ACCOUNT_SUP_RT_ID);
		org.Name = String.isNotBlank(accountName) ? accountName : 'Supplier-' + getRandomString(8);
		org.Status__c = 'Active';
		org.Sector__c = 'Health';
		org.DUNS_Number__c = Integer.valueOf(Math.random() * 1000000000);
		org.BillingStreet = 'Kingsway';
		org.BillingPostalCode = 'WC1V 7RN';
		org.BillingCity = 'London';
		org.BillingCountry = 'England';

		return org;
	}

	private Contact createContact(Id accountId) {
		Contact c = new Contact();
		c.AccountId = accountId;
		c.Salutation = 'Mr';
		c.FirstName = 'Splashy ' + getRandomString(1);
		c.LastName = 'Test';
		c.Email = 'mr.splashypants@greenpeace.xyz';
		return c;
	}

	private CCS_Contract__c createContract(Id customerId, Id customerContactId, Id suppliertId, Id supplierContactId){
		CCS_Contract__c retVal = createContract();
		retVal.Customer__c = customerId;
		retVal.Customer_Contact__c = customerContactId;
		retVal.Supplier__c = suppliertId;
		retVal.Supplier_Contact__c = supplierContactId;

		return retVal;
	}

	private CCS_Contract__c createContract(){
		CCS_Contract__c retVal = new CCS_Contract__c();
		String strRef = getRandomString(8);
		retVal.name = 'Contract Test';
		retVal.Contract_Reference__c = strRef;
		retVal.Start_Date__c = Date.today().addDays(24);
		retVal.End_Date__c = Date.today().addYears(1);
		retVal.Contract_Value__c = Integer.valueOf(Math.random() * 1000000);
		retVal.Status__c = 'Pending';
		retVal.Procurement_Reference__c = 'Reference Test';

		return retVal;
	}

	private List<Category__c> createLevel1Categories(){
		List<Category__c> categories = new List<Category__c>();
		Category__c c1 = createCategory('Clinical and Medical', 'CAS Master Category', '', null, '14', '');
		Category__c c2 = createCategory('Buildings', 'Pillar', '', null, '206', '');
		categories.add(fetchCategory(c1));
		categories.add(fetchCategory(c2));
		upsert categories;
		return categories;
	}

	private List<Category__c> createLevel2Categories(List<Category__c> parents){
		List<Category__c> categories = new List<Category__c>();
		Category__c c1 = createCategory('Clinical and Medical', 'CAS Category', '', parents[0].Id, '1410', 'ZC');
		Category__c c2 = createCategory('Property', 'CCS Category', '', parents[1].Id, 'CAT_219', '');
		categories.add(fetchCategory(c1));
		categories.add(fetchCategory(c2));
		upsert categories;
		return categories;
	}

	private List<Category__c> createLevel3Categories(List<Category__c> parents){
		List<Category__c> categories = new List<Category__c>();
		Category__c c1 = createCategory('Clinical and Medical', 'CAS Sub Category', '', parents[0].Id, '1410000', '');
		Category__c c2 = createCategory('Property', 'CCS Sub Category', 'CC', parents[1].Id, 'SUB_219', '');
		categories.add(fetchCategory(c1));
		categories.add(fetchCategory(c2));
		upsert categories;
		return categories;
	}

	private List<Category__c> createLevel4Categories(Category__c parent){
		List<Category__c> categories = new List<Category__c>();
		Category__c c1 = createCategory('33000000', 'Code', 'CPV', parent.Id, '33000000-0', '');
		Category__c c2 = createCategory('U81.14.18.06', 'Code', 'UNSPSC', parent.Id, 'U81.14.18.06', '');
		categories.add(fetchCategory(c1));
		categories.add(fetchCategory(c2));
		upsert categories;
		return categories;
	}

	private Category__c createCategory(String catName, String catType, String codeType, Id parentId, 
		String extId, String catCode){
		Category__c retVal = new Category__c();
		retVal.Name = catName;
		retVal.CategoryType__c = catType;
		retVal.Code_Type__c = codeType;
		retVal.Parent__c = parentId;
		retVal.Cat_External_ID__c = extId;
		retVal.Category_Code__c = catCode;

		return retVal;
	}

	private Level_4_Categorisation_Code_for_Contract__c createCatContract (Id catId,
		Id contractId){
		Level_4_Categorisation_Code_for_Contract__c retVal = 
			new Level_4_Categorisation_Code_for_Contract__c();
		retVal.Code__c = catId;
		retVal.CCS_Contract__c = contractId;

		return retVal;
	}

	private Master_Framework__c createMasterFramework(String name){
		Master_Framework__c retVal = new Master_Framework__c();
		retVal.Name = name;
		retVal.Status__c = 'Live';

		return retVal;
	}

	private Master_Framework_Lot__c createMasterFrameworkLot(Id masterFrameworkId, String name){
		Master_Framework_Lot__c retVal = new Master_Framework_Lot__c();
		retVal.Name = name;
		retVal.Status__c = 'Live';
		retVal.Master_Framework__c = masterFrameworkId;

		return retVal;
	}

	private Supplier_Framework_Lot__c createSupplierFrameworkLot(Id masterFrameworkLotId,
			Id accountId){
		Supplier_Framework_Lot__c retVal = new Supplier_Framework_Lot__c();
		retVal.Master_Framework_Lot__c = masterFrameworkLotId;
		retVal.Supplier__c = accountId;

		return retVal;
	}

	private String getRandomString (Integer maxLength){
		String retVal = '' + Integer.valueOf(Math.random() * Math.pow(10,maxLength));
		return retVal;
	}

	private void sendSummaryEmail() {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSenderDisplayName('PostRefreshWorker');
		mail.setSubject('Process completed');
		mail.setPlainTextBody(summaryMessage.toString());
		mail.setTargetObjectId(UserInfo.getUserId());
		mail.saveAsActivity = false;
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
	}

	public class SummaryMessage {
		private Integer noOfAction;
		private String msg;
		private String done;

		public SummaryMessage() {
			msg = 'Process Started...\n';
			noOfAction = 0;
			done = 'Done.';
		}

		public SummaryMessage add(String msg) {
			++noOfAction;
			this.msg += noOfAction + '. ' + msg + '...\n';
			System.debug('msg ' + msg);
			return this;
		}

		public SummaryMessage finish(String finishMesage) {
			msg += done + ' ' + finishMesage + '\n';
			return this;
		}

		public SummaryMessage finish() {
			msg += done + '\n';
			return this;
		}

		public override String toString() {
			return msg;
		}
	}
}