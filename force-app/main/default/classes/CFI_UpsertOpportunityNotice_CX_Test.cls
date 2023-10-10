/*****************************************************************************************************************************
Name: CFI_UpsertContractService_Test

Purpose: Unit test for CFI_UpsertOpportunityNotice_CX

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      18/03/2016      INITIAL DEVELOPMENT
1.1 Cezary Zeleznicki       04/11/2016      Procurement RT change
1.2     Cezary Zeleznicki       03/01/2016      Increasing code coverege
*******************************************************************************************************************************/

@isTest (seeAllData=false)
private class CFI_UpsertOpportunityNotice_CX_Test{
    
  

    @isTest
    static void shouldFailOnLogin() {
        // given
        Boolean bUpsertSuccess;
        CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
        mock.typeOfReponce = CFI_MockHttpResponseGenerator.FAIL_LOGIN_RESPONCE;
        Test.setMock(HttpCalloutMock.class, mock);

        UnitTestDataFactory tdf = new UnitTestDataFactory();
        tdf.initTestDataForContracts();
        Case c = fetchCaseById(tdf.liCases[0].Id);

        Integer iNoMsg;

        // when
        Test.startTest();
            CFI_UpsertOpportunityNotice_CX ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController(c));
            iNoMsg = ApexPages.getMessages().size();
            System.assert(ext.disableUpsert,'Button should be disabled');
            ext.disableUpsert = false;
            ext.upsertOpporunityNotice();
        Test.stopTest();

        // then
        System.assertEquals(iNoMsg+1, ApexPages.getMessages().size(),'New error message had been added');
        ApexPages.message msg = ApexPages.getMessages()[iNoMsg];
        System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity(),'It should be error message on login fail');
        System.assert(!ext.disableUpsert,'Button should not be disabled after failed upsert');
        System.assert(ext.liRequiredFields != null && ext.liRequiredFields.size() > 0 ,'Required fields list is not empty');
    }


    @isTest static void shouldFailOnUpdateOfOppNotice() {
        // given
        Boolean bUpsertSuccess;
        Integer iNoMsg;

        CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
        mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_GET_TOKEN;
        Test.setMock(HttpCalloutMock.class, mock);

        UnitTestDataFactory tdf = new UnitTestDataFactory();
        tdf.initTestDataForContracts();
        Case c = fetchCaseById(tdf.liCases[0].Id);

        // when
        Test.startTest();
            CFI_UpsertOpportunityNotice_CX ext = 
                new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController(c));
            ext.disableUpsert = false;
            iNoMsg = ApexPages.getMessages().size();
            ext.upsertOpporunityNotice();
        Test.stopTest();

        // then
        ApexPages.message msg = ApexPages.getMessages()[iNoMsg];
        System.debug('>>>msg: ' + msg.getSummary());    
        System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity(), 
            'Should get unexpected error, since returned notice id is too long');

    }

    @isTest
    static void shouldGetCorrectMessage(){
        // given
        User user = [Select id from User where isActive = true AND Profile.Name = 'CCS Restricted User' LIMIT 1];
        System.runAs(User)
        {
        
        insert UnitTestDataFactory.createOpsWorkflowStages();
        insert UnitTestDataFactory.createOpsWorkflowTemplates();
        }
       
       
        CFI_UpsertOpportunityNotice_CX ext;
        ApexPages.message msg;
        Integer iNoMsg;
        Case c = new Case();
        insert c;
        c = fetchCaseById(c.Id);


        // when - then
        c.Contract_Finder_Notice_Id__c = 'sdadsa-gregtret-vxcgvx';
        ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController (c));
        iNoMsg = ApexPages.getMessages().size();
        msg = ApexPages.getMessages()[iNoMsg-1];
        System.assertEquals(Label.CFI_On_StartMsgAlreadyCreated,msg.getSummary(),
            'Should get notice aready existing message');

        
       
        User noAccessUser = [Select id from User where isActive = true AND Profile.Name = 'CCS Restricted User' LIMIT 1];
        
        System.runAs(noAccessUser) {
        c.Contract_Finder_Notice_Id__c = null;
        c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Enquiry');
        update c;
           
          
        System.assertEquals(Label.CFI_On_StartMsgAlreadyCreated,msg.getSummary(),
            'Should get notice aready existing message');

            ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController (c));
            ext.liMissedReqFields = new List <String>();
            ext.displayWelcomeMessage();
            iNoMsg = ApexPages.getMessages().size();
            msg = ApexPages.getMessages()[iNoMsg-1];
        }
        
        System.assertEquals(Label.CFI_ON_Only_Edit_Access_Can_Send,msg.getSummary(),
            'Should get no edit access message');

        // call off     
        c.Contract_Finder_Notice_Id__c = null;
        c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Procurement_Call_Off_Competition');
        update c;
        c = fetchCaseById(c.Id);
        ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController (c));
        ext.hasEditAccess = true;
        ext.displayWelcomeMessage();
        iNoMsg = ApexPages.getMessages().size();
        msg = ApexPages.getMessages()[iNoMsg-1];
        System.assertEquals(Label.CFI_StartMsgCallOff,msg.getSummary(),
            'Should get call off message');

        // call off     
        c.Contract_Finder_Notice_Id__c = null;
        c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Procurement_Single_Tender_Action');
        update c;
        c = fetchCaseById(c.Id);
        ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController (c));
        ext.hasEditAccess = true;
        ext.displayWelcomeMessage();
        iNoMsg = ApexPages.getMessages().size();
        msg = ApexPages.getMessages()[iNoMsg-1];
        System.assertEquals(Label.CFI_StartMsgSinTenAction,msg.getSummary(),
            'Should get call off message');

        // ready
        c.Contract_Finder_Notice_Id__c = null;
        c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Enquiry');
        update c;
        c = fetchCaseById(c.Id);
        ext = new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController (c));
        ext.hasEditAccess = true;
        ext.liMissedReqFields = new List <String>();
        ext.displayWelcomeMessage();
        iNoMsg = ApexPages.getMessages().size();
        msg = ApexPages.getMessages()[iNoMsg-1];
        System.assertEquals(Label.CFI_ON_StartMsg,msg.getSummary(),
            'Should get start message');
    }

    @isTest
    static void shouldUpsertOpportunityNotice(){
        Integer iNoMsg;

        CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
        mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_NOTICE;
        Test.setMock(HttpCalloutMock.class, mock);

        UnitTestDataFactory tdf = new UnitTestDataFactory();
        tdf.initTestDataForContracts();
        Case c = fetchCaseById(tdf.liCases[0].Id);
        Category__c cat = UnitTestDataFactory.createCategory();
        insert cat;
        Procurement_Cat_Code__c pcc = UnitTestDataFactory.createProcurementCatCode(c.Id, cat.Id);
        insert pcc;

        Test.startTest();
            CFI_UpsertOpportunityNotice_CX ext = 
                new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController(c));
            ext.disableUpsert = false;
            iNoMsg = ApexPages.getMessages().size();
            ext.upsertOpporunityNotice();
        Test.stopTest();
        
    }

    @isTest
    static void testUpsertDisabled(){
        Boolean isUpsertDisabled;
        Boolean isUpsertDisabled2;

        CFI_MockHttpResponseGenerator mock = new CFI_MockHttpResponseGenerator();
        mock.typeOfReponce = CFI_MockHttpResponseGenerator.SUC_CREATE_NOTICE;
        Test.setMock(HttpCalloutMock.class, mock);

        UnitTestDataFactory tdf = new UnitTestDataFactory();
        tdf.initTestDataForContracts();
        Case c = fetchCaseById(tdf.liCases[0].Id);

        Category__c cat = UnitTestDataFactory.createCategory();
        insert cat;
        Procurement_Cat_Code__c pcc = UnitTestDataFactory.createProcurementCatCode(c.Id, cat.Id);
        insert pcc;

        c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Procurement_Low_Value');
        update c;
        c = fetchCaseById(c.Id);

        Test.startTest();
            CFI_UpsertOpportunityNotice_CX ext = 
                new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController(c));
            ext.hasEditAccess = false;
            isUpsertDisabled = ext.disableUpsert;
            ext.upsertOpporunityNotice();
            c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId('Procurement_Single_Tender_Action');
            update c;
            c = fetchCaseById(c.Id);
            CFI_UpsertOpportunityNotice_CX ext2 = 
                new CFI_UpsertOpportunityNotice_CX(new ApexPages.StandardController(c));
            isUpsertDisabled2 = ext2.disableUpsert;
            ext2.upsertOpporunityNotice();
        Test.stopTest();

        System.assert(isUpsertDisabled);
        System.assert(isUpsertDisabled2);
    }

    private static Case fetchCaseById(Id caseId) {
        return [
            SELECT Id, Contract_Finder_Notice_Id__c, RecordType.DeveloperName, Contract_Finder_Additional_Detail_Id__c, 
                Synchronised_With_Contract_Finder__c, RecordTypeId, Procurement_Reference__c, Regions__c, Contract_Finder_Title__c, 
                Tender_End_Date__c, Contract_Start_Date__c, Contract_End_Date__c, Contract_Low_Value__c,
                Additional_CF_Information__c, Contract_Finder_Desc__c, Contract_Type__c, Contract_High_Value__c, SME_Suitable__c,
                VCSE_Suitable__c
            FROM Case
            WHERE Id = :caseId
        ];
    }
}