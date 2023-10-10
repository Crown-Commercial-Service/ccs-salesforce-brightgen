/*****************************************************************************************************************************
Name: CFI_UpsertContractService_Test

Purpose: Unit test for CFI_UpsertContractService and CFI_MessageFactory

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      11/03/2016      INITIAL DEVELOPMENT
*******************************************************************************************************************************/

@isTest (seeAllData=false)
private class CFI_UpsertContractService_Test {
	
	@isTest static void shouldFailOnLogin() {
		// given
		Boolean bUpsertSuccess;
		Test.setMock(HttpCalloutMock.class, new CFI_MockHttpResponseGenerator());

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.upsertContract(tdf.liContracts[0], new List <String> {'aaaa', 'bbb'});
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Upsert should fail');

	}

	@isTest static void shouldLogin() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_GET_TOKEN;
		Test.setMock(HttpCalloutMock.class, mock);

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.logIn();
		Test.stopTest();

		// then
		System.assert(bUpsertSuccess, 'Should get access token');
		System.assertEquals(CFI_MockHttpResponseGenerator.TOKEN, ucs.securityToken, 'Should get and save secuity token');

	}

	@isTest static void shouldCreateNotice() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_NOTICE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.insertDraftNotice(tdf.liContracts[0], new List <String> {'72611000', '72611002'});
		Test.stopTest();

		// then
		System.assert(bUpsertSuccess, 'Should create notice');
		System.assertEquals(CFI_MockHttpResponseGenerator.NOTICE_ID, ucs.noticeId, 'Should obtain noticeId');

	}
	@isTest static void shouldCreateNoticeWithCPVCodes() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_GET_TOKEN;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();
		CCS_Contract__c ccsContract = tdf.liContracts[0];
		List<Category__c> liCats = new List<Category__c>();
		liCats.add(UnitTestDataFactory.createCategory());
		liCats.add(UnitTestDataFactory.createCategory());
		insert liCats;

		List<Level_4_Categorisation_Code_for_Contract__c> liContractCodes = new 
		List<Level_4_Categorisation_Code_for_Contract__c>();

		for (Category__c cat : liCats){
			liContractCodes.add (UnitTestDataFactory.createCatContract(cat.Id, ccsContract.id));
		}
		insert liContractCodes;

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.upsertContract(ccsContract, new List <String> {'aaaa', 'bbb'});
		Test.stopTest();

		// then
		System.assert(bUpsertSuccess, 'Should create notice and award');
	}

	@isTest static void shouldFailOnCreateNotice() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.insertDraftNotice(tdf.liContracts[0], new List <String> {'72611000', '72611002'});
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Should fail on create notice');

	}

	@isTest static void shouldCreateAward() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_AWARD;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.insertAward(tdf.liContracts[0]);
		Test.stopTest();

		// then
		System.assert(bUpsertSuccess, 'Should create Award');

	}

	@isTest static void shouldFailOnCreateAward() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.insertAward(tdf.liContracts[0]);
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Should fail on create award');

	}

	@isTest static void shouldPublish() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_AWARD;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.publishNotice(tdf.liContracts[0]);
		Test.stopTest();

		// then
		System.assert(bUpsertSuccess, 'Should create Award');

	}

	@isTest static void shouldFailOnPublish() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.publishNotice(tdf.liContracts[0]);
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Should fail on create award');

	}

	@isTest static void shouldFailOnLoginForOppNotice() {
		// given
		Boolean bUpsertSuccess;
		Test.setMock(HttpCalloutMock.class, new CFI_MockHttpResponseGenerator());

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.upsertOpporunityNotice(tdf.liCases[0], new List <String> {'aaaa', 'bbb'});
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Upsert should fail');
		System.assertEquals(0, CFI_UpsertContractService.getCPVCodes(tdf.liCases[0]).size(), 'Should return empty list of codes');

	}



	@isTest static void shouldCreateOppNotice() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_NOTICE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess = ucs.insertDraftOpportunityNotice(tdf.liCases[0], new List <String> {'aaaa', 'bbb'});
			System.assert(bUpsertSuccess, 'Should create notice');

			// Add additional details
			bUpsertSuccess = ucs.insertAdditionalDetails('Some Text');
			System.assert(bUpsertSuccess, 'Should create additional details');

		Test.stopTest();

		// then
		System.assertEquals(CFI_MockHttpResponseGenerator.NOTICE_ID, ucs.noticeId, 
			'Should obtain noticeId');
		System.assertEquals(CFI_MockHttpResponseGenerator.NOTICE_ID, ucs.additionalDetailId, 
			'Should obtain additional detail id');

	}


	@isTest static void shouldCreateOppNotice2() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_GET_TOKEN;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess = ucs.upsertOpporunityNotice(tdf.liCases[0], new List <String> {'aaaa', 'bbb'});
		Test.stopTest();

		// then		
		System.assert(bUpsertSuccess, 'Should create notice and additional details');

	}

	@isTest static void shouldFailOnCreateOppNotice() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess= ucs.insertDraftOpportunityNotice(tdf.liCases[0], new List <String> {'aaaa', 'bbb'});
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Should fail on create notice');

	}

	@isTest static void shouldFailOnAdditionalDetails() {
		// given
		Boolean bUpsertSuccess;
		CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
		mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_SINGLE_RESPONCE;
		Test.setMock(HttpCalloutMock.class, mock);

		UnitTestDataFactory tdf = new UnitTestDataFactory();
		tdf.initTestDataForContracts();

		// when
		Test.startTest();
			CFI_UpsertContractService ucs = new CFI_UpsertContractService();
			bUpsertSuccess = ucs.insertAdditionalDetails('Some Text');
		Test.stopTest();

		// then
		System.assert(!bUpsertSuccess, 'Should fail on create additional details');

	}
}