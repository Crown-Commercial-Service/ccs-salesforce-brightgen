/*****************************************************************************************************************************
Name: CFI_UpsertContractService_Test

Purpose: Unit test for CFI_UpsertContract_CX

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      11/03/2016      INITIAL DEVELOPMENT
1.1 - 	Cezary Zeleznicki		04/01/2016	Increasing code coverege
*******************************************************************************************************************************/

@isTest (seeAllData=false)
private class CFI_UpsertContract_CX_Test{
	@isTest
	static void shouldFailOnLogin(){
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_LOGIN_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		Integer iNoMsg;

		// when
		Test.startTest();
			CFI_UpsertContract_CX ext = new CFI_UpsertContract_CX(new ApexPages.StandardController (tdf.liContracts[0]));
			iNoMsg = ApexPages.getMessages().size();
			System.assert(ext.disableUpsert,'Button should be disabled - required fields missing');
			ext.disableUpsert = false;
			ext.upsertContract();
		Test.stopTest();

		// then
		System.assertEquals(iNoMsg+1, ApexPages.getMessages().size(),'New error message had been added');
		ApexPages.message msg = ApexPages.getMessages()[iNoMsg];
		System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity(),'It should be error message on login fail');
		System.assert(!ext.disableUpsert,'Button should not be disabled after failed upsert');
		System.assert(ext.liFields != null && ext.liFields.size() > 0 ,'Query fields list is not empty');
		System.assert(ext.liContractRequiredFields != null && ext.liContractRequiredFields.size() > 0 ,
			'Required fields list is not empty');
		System.assert(ext.liSupplierRequiredFields != null && ext.liSupplierRequiredFields.size() > 0 ,
			'Required fields list is for supplier not empty');
	}

	@isTest
	static void shouldGetMessage(){
		// given
		CCS_Contract__c ccsContract = new CCS_Contract__c();
		CFI_UpsertContract_CX ext;
		ApexPages.message msg;
		Integer iNoMsg;

		// when - then
		// existing notice
		ccsContract.Contract_Finder_Notice_Id__c = 'aaaa-bbb-cccd-dddd';
		ext = new CFI_UpsertContract_CX(new ApexPages.StandardController (ccsContract));
		iNoMsg = ApexPages.getMessages().size();
		msg = ApexPages.getMessages()[iNoMsg-1];
		System.assertEquals(Label.CFI_StartMsgContractCreated,msg.getSummary(),
			'Should get notice already existing message');


		// no access message
		ccsContract.Contract_Finder_Notice_Id__c = null;
		ext = new CFI_UpsertContract_CX(new ApexPages.StandardController (ccsContract));
		ext.liMissedReqFields = new List<String> ();
		ext.displayWelcomeMessage();
		iNoMsg = ApexPages.getMessages().size();
		msg = ApexPages.getMessages()[iNoMsg-1];
		System.assertEquals(Label.CFI_Only_Edit_Access_Can_Send,msg.getSummary(),
			'Should get no edit access message');

		// start message
		ext.hasEditAccess = true;
		ext.displayWelcomeMessage();
		iNoMsg = ApexPages.getMessages().size();
		msg = ApexPages.getMessages()[iNoMsg-1];
		System.assertEquals(Label.CFI_StartMsg,msg.getSummary(),
			'Should get notice already existing message');
	}

	@isTest
	static void shouldUpsertContract(){
		CFI_UpsertContract_CX ext;
		ApexPages.message msg;
		Integer iNoMsg;

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		Category__c cat = UnitTestDataFactory.createCategory();
		insert cat;

		CCS_Contract__c contract = tdf.liContracts[0];
		String strRef = UnitTestDataFactory.getRandomString(8);
		contract.Name = 'Contract-' + strRef;
		contract.Contract_Reference__c = strRef;
		contract.Start_Date__c = Date.today().addDays(24);
		contract.End_Date__c = Date.today().addYears(1);
		contract.Contract_Value__c = Integer.valueOf(Math.random() * 1000000);
		contract.Deadline_Date__c = Date.today().addYears(1);
		contract.Regions__c = 'test';
		contract.Description__c = 'Test';
		contract.Extension_Options__c = false;
		contract.Date_Contract_Awarded__c = Date.today().addDays(24);
		contract.OJEU_Procedure_Type__c = 'Test';
		contract.Contract_Type__c = 'Test contract';
		update contract;

		Level_4_Categorisation_Code_for_Contract__c code4 = UnitTestDataFactory.createCatContract(cat.Id, contract.Id);
		insert code4;

		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_NOTICE;
		Test.setMock(HttpCalloutMock.class, mock);

		Test.startTest();
		ext = new CFI_UpsertContract_CX(new ApexPages.StandardController(contract));
		ext.upsertContract();
		Test.stopTest();

		contract = [SELECT Id, Contract_Finder_Notice_Id__c FROM CCS_Contract__c WHERE Id = :contract.Id];
		iNoMsg = ApexPages.getMessages().size();
		msg = ApexPages.getMessages()[iNoMsg-1];

		System.assertNotEquals(null, contract.Contract_Finder_Notice_Id__c, 'Case should be updated with notice Id');
		System.assertEquals(ApexPages.Severity.INFO, msg.getSeverity(), 
			'Should get success msg');
	}

	@isTest
	static void shouldGenerateException(){
		CFI_UpsertContract_CX ext;
		ApexPages.message msg;
		ApexPages.message msg2;
		Integer iNoMsg;
		Boolean containsNoticeId;

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		Category__c cat = UnitTestDataFactory.createCategory();
		insert cat;

		CCS_Contract__c contract = tdf.liContracts[0];
		String strRef = UnitTestDataFactory.getRandomString(8);
		contract.Name = 'Contract-' + strRef;
		contract.Contract_Reference__c = strRef;
		contract.Start_Date__c = Date.today().addDays(24);
		contract.End_Date__c = Date.today().addYears(1);
		contract.Contract_Value__c = Integer.valueOf(Math.random() * 1000000);
		contract.Deadline_Date__c = Date.today().addYears(1);
		contract.Regions__c = 'test';
		contract.Description__c = 'Test';
		contract.Extension_Options__c = false;
		contract.Date_Contract_Awarded__c = Date.today().addDays(24);
		contract.OJEU_Procedure_Type__c = 'Test';
		contract.Contract_Type__c = 'Test contract';
		update contract;

		Level_4_Categorisation_Code_for_Contract__c code4 = UnitTestDataFactory.createCatContract(cat.Id, contract.Id);
		insert code4;

		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_GET_TOKEN;
		Test.setMock(HttpCalloutMock.class, mock);

		Test.startTest();
		ext = new CFI_UpsertContract_CX(new ApexPages.StandardController(contract));
		ext.upsertContract();
		contract = [SELECT Id, Contract_Finder_Notice_Id__c FROM CCS_Contract__c WHERE Id = :contract.Id];
		containsNoticeId = contract.Contract_Finder_Notice_Id__c != null;
		iNoMsg = ApexPages.getMessages().size();
		msg = ApexPages.getMessages()[iNoMsg-1];

		contract.Contract_Type__c = null;
		update contract;
		ext = new CFI_UpsertContract_CX(new ApexPages.StandardController(contract));
		ext.upsertContract();
		Test.stopTest();

		iNoMsg = ApexPages.getMessages().size();
		msg2 = ApexPages.getMessages()[iNoMsg-1];
		

		System.assert(!containsNoticeId, 'Case should not be updated with notice Id');
		System.assert(msg.getSummary().contains(Label.CFI_UnexpectedError.left(25)), 
			'Should generate Unexpected Error');
		System.assert(msg2.getSummary().contains(Label.CFI_ReqFieldMissing_AN), 
			'Should be missing fields');
	}

}