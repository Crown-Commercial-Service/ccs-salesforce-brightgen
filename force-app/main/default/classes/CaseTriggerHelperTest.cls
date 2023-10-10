/*********************************************************************
 Name:  CaseTriggerHelperTest
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: tests for CaseTriggerHelper
 -------
 ======================================================
 ======================================================
 History
 -------
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Klea Kolaric       2016-03-07      Initial version
   1.2  Piotr Czechumski 2016-10-14    Add setting time fields for approval US1506
   1.3  Cezary Zeleznicki 2016-10-25        moved flow from PB to Trigger execution.
   1.4  Cezary Zeleznicki 2016-11-03        Procurement RT change
   1.5  Cezary Zeleznicki 2016-11-09        Simplified Stage dates US1645
   1.6  Cazary Zeleznicki 2016-12-06        Enquiry Entitlement Id
   1.7   Cezary Zeleznicki  2016-12-07      Complete Milestones
   1.8  Cezary Zeleznicki   2016-12-14      Sla status change
   1.9  Tristam Hardman     2018-11-12      Duration and 'Plus/Minus' calculations
   2.0  Zahir Basith		2023-09-11		Test coverage for policy recordtype
 *********************************************************************/

@isTest
private class CaseTriggerHelperTest {

    static final String ORG_NAME = 'Test Org';
    static final Id PROC_CALLOFF_RT = UnitTestHelper.mRecordTypes.get('Case').get('Procurement_Call_Off_Competition');
    static final Id POLICY_RT = UnitTestHelper.mRecordTypes.get('Case').get('Policy_Legal_Case');
    static final Id ENQUIRY_RT = UnitTestHelper.mRecordTypes.get('Case').get('Enquiry');
    @testSetup
    static void setupTest()
    {
        // create custom settings
        insert UnitTestHelper.createOpsWorkflowStages();
        insert UnitTestHelper.createOpsWorkflowTemplates();

        Account org = UnitTestHelper.createOrganisationAccount(ORG_NAME);
        insert org;

        SlaProcess sla6 = [SELECT Id, Name FROM SlaProcess WHERE Name LIKE 'sla6%' AND isActive = true LIMIT 1];
        SlaProcess slaEnq = [SELECT Id, Name FROM SlaProcess WHERE Name LIKE 'Enquiry%' AND isActive = true LIMIT 1];
        Entitlement entProc = new Entitlement(Name = 'Test', AccountId = org.Id, SlaProcessId = sla6.Id);
        Entitlement entEnq = new Entitlement(Name = 'Test', AccountId = org.Id, SlaProcessId = slaEnq.Id);

        insert new List<Entitlement>{entProc, entEnq};

        insert new Org_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), 
        Entitlement_ID__c = entProc.Id, Enquiry_Entitlement_ID__c = entEnq.Id);

        Tier_Level__c tl = new Tier_Level__c(Tier_Sla__c = '1.0', Is_Default__c = true);
        Tier_Level__c tl2 = new Tier_Level__c(Tier_Sla__c = '3.0');
        insert new List<Tier_Level__c>{tl, tl2};

        List<Case> cases = new List<Case>();
        for(Integer i=0; i<5; i++)
        {
            Case c = UnitTestHelper.createEnquiryCase(org.Id);
            Case cProc = UnitTestHelper.createProcurementCase(org.Id);
            Case cPolicy = UnitTestHelper.createPolicyCase(org.Id);
            cPolicy.Tier_Level__c = tl.Id;
            cases.add(c);
            cases.add(cProc);
            cases.add(cPolicy);
        }
        insert cases;
    }

    static testMethod void testBulkInsert_100records_pass()
    {
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: PROC_CALLOFF_RT LIMIT 45];
        List<Case> newCases = cases.deepClone(false, false, false);
        newCases.addAll(cases.deepClone(false, false, false));
        Test.startTest();
        insert newCases;
        Test.stoptest();

        system.assertEquals(10,[SELECT count() FROM Case WHERE Id IN :newCases], 'All cases should be created.');
        Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
        system.assertEquals(60,[SELECT count() FROM Procurement_Stage__c WHERE Procurement__c IN :newCases], 'All cases should be have stages.');
    }
 

    static testMethod void testBulkUpdate_100records_pass()
    {
       
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: ENQUIRY_RT LIMIT 10];
        List<Case> newCases = cases.deepClone(false, false, false);
        insert newCases;
        cases.addAll(newCases);
        System.debug('ALL CASES' + cases.size() + ' ' + cases);
        for(Case c : cases) {
           c.RecordTypeId = PROC_CALLOFF_RT;
        }

        Test.startTest();
        update cases;
        Test.stoptest();

        system.assertEquals(10,[SELECT count() FROM Case WHERE RecordTypeId = :PROC_CALLOFF_RT AND Id IN :cases], 'All cases should be updated.');
        Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
        system.assertEquals(15*(numOfStages-2),[SELECT count() FROM Procurement_Stage__c WHERE Procurement__c IN :cases], 'All cases should have stages.');
		
    }

    static testMethod void testInsertTrigger_createStagesFunctionality_stagesCreated()
    {
        Account org = [SELECT Id FROM Account WHERE Name = :ORG_NAME limit 1];
        Case c = UnitTestHelper.createProcurementCase(org.Id);

        Test.startTest();
        insert c;
        Test.stopTest();

        c = [SELECT Id, Stage__c, RecordType.DeveloperName FROM Case WHERE Id = :c.Id];

        Map<String,Ops_Workflow_Stages__c> definedStages = Ops_Workflow_Stages__c.getAll();
        System.debug('Created Stages' + ' ' + definedStages.keySet());
      
        List<Procurement_Stage__c> createdStages = [SELECT Id, Name, Next_Stage__c, Stage_Id__c, Planned_Start_Date__c, Start_SLA1__c, Start_SLA2__c,
                                                    End_SLA1__c, End_SLA2__c, Actual_Start_Date__c
                                                    FROM Procurement_Stage__c WHERE Procurement__c = :c.Id ORDER BY Seq__c ASC];
        System.debug('Created Stages' + ' ' + createdStages);
        //system.assertEquals(definedStages.size()-2,createdStages.size(), 'Created stages count should correspond to the count in custom settings.');
        system.assertEquals(createdStages.get(0).Id,[SELECT Stage__c FROM Case WHERE Id = :c.Id].Stage__c, 'Case should point to first stage.');

        Map<String,Ops_Workflow_Templates__c> wfTemplates = ProcurementStageTriggerHelper.templatesWF.get(c.RecordType.DeveloperName);
        for(Integer i=0; i<createdStages.size(); i++)
        {
            Procurement_Stage__c stage = createdStages.get(i);
            Ops_Workflow_Stages__c wfStage = definedStages.get(stage.Stage_Id__c);
            Ops_Workflow_Templates__c wfTemplate = wfTemplates.get(stage.Stage_Id__c);

            system.assertNotEquals(null,wfStage, 'Stage Id should be set correctly.');
            system.assertEquals(wfStage.Stage_Name__c,stage.Name, 'Stage Name should be set correctly.');
            system.assertEquals(stage.Next_Stage__c, (i == createdStages.size()-1 ? null : createdStages.get(i+1).Id),
                                'Next Stage should be set corectly.');
            // assert SLA flages set correctly
            system.assertEquals(wfTemplate.Start_SLA1__c,stage.Start_SLA1__c,'Start SLA1 should be same as on template.');
            system.assertEquals(wfTemplate.Start_SLA2__c,stage.Start_SLA2__c,'Start SLA2 should be same as on template.');
            system.assertEquals(wfTemplate.End_SLA1__c,stage.End_SLA1__c,'End SLA1 should be same as on template.');
            system.assertEquals(wfTemplate.End_SLA2__c,stage.End_SLA2__c,'End SLA2 should be same as on template.');

            if(stage.Stage_Id__c == 'S01')
            {
                Date cd = [SELECT CreatedDate FROM Case WHERE Id = :c.Id].CreatedDate.date();
                system.assertEquals(cd, stage.Planned_Start_Date__c, 'First stage original start date should be case created date.');
                system.assertEquals(cd, stage.Actual_Start_Date__c, 'First stage actual start date should be case created date.');
            }
            else
            {
                system.assertEquals(null,stage.Planned_Start_Date__c, 'Original start date should be blank.');
                system.assertEquals(null,stage.Actual_Start_Date__c, 'Actual start date should be blank.');
            }
        }

    }

    static testMethod void testUpdateTrigger_createStagesFunctionality_newStagesCreatedOldStagesDeleted()
    {
        System.debug('I am in ');
        Integer numOfStages = Ops_Workflow_Stages__c.getAll().size();
        System.debug('NUMBER OF STAGES' + '' +numOfStages);
        Id procDirectAwardRecTypeId = UnitTestHelper.mRecordTypes.get('Case').get('Procurement_Call_Off_Direct_Award');
        Account org = [SELECT Id FROM Account WHERE Name = :ORG_NAME LIMIT 1];
        Case c = UnitTestHelper.createEnquiryCase(org.id);
        insert c;
        System.assertEquals(0,[SELECT count() FROM Procurement_Stage__c WHERE Procurement__c =: c.Id], 'No stages should exist as procurement route not set.');

        Test.startTest();
        c.RecordTypeId = PROC_CALLOFF_RT;
        update c;

        List<Procurement_Stage__c> oldStages = [SELECT Id FROM Procurement_Stage__c WHERE Procurement__c = :c.Id];
        System.assertEquals(numOfStages-2,oldStages.size() -2, 'Stages should have been created when procurement route set.');

        c.RecordTypeId = procDirectAwardRecTypeId;
        update c;
        List<Procurement_Stage__c> newStages = [SELECT Id FROM Procurement_Stage__c WHERE Procurement__c = :c.Id AND Id IN :oldStages];
        //System.assertEquals(numOfStages-2,newStages.size(), 'Stages should not be modified when route changed.');

        c.RecordTypeId = ENQUIRY_RT;
        update c;
        /*System.assertEquals(0,[SELECT count() FROM Procurement_Stage__c WHERE Procurement__c = :c.Id],
            'Stages should have been deleted when procurement route un-set.');*/

        Test.stopTest();
    }
/*
    static testMethod void testUpdateTrigger_stopSlas_milestonesClosedWhenStopStage()
    {
        Map<Id, Case> id2Case = new Map<Id, Case>([SELECT Id, Stage__c, EntitlementID, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: PROC_CALLOFF_RT LIMIT 100]);
        Integer i = 0;
        for(Case c : id2Case.values()) {
            if(Math.mod(i, 2) == 0) {
                c.SLA_1_Start__c = true;
                c.SLA1__c = '8';
                
            } else {
                c.SLA_2_Start__c = true;
                c.SLA_2_days__c = '10';
            }
            i++;
        }
        update id2Case.values();
        
        Map<Id, Procurement_Stage__c> caseId2Stage = new Map<Id, Procurement_Stage__c>();
        
        for(Procurement_Stage__c ps : [
                SELECT Id, End_SLA1__c, End_SLA2__c, Procurement__c 
                FROM Procurement_Stage__c 
                WHERE (End_SLA1__c = true  OR End_SLA2__c = true) AND Procurement__c IN :id2Case.keySet()
            ]) 
        {
            if((id2Case.get(ps.Procurement__c).SLA_1_Start__c && ps.End_SLA1__c) ||
                (id2Case.get(ps.Procurement__c).SLA_2_Start__c && ps.End_SLA2__c))
            caseId2Stage.put(ps.Procurement__c, ps);
            
        }

        for(Case c : id2Case.values()) {
            if(caseId2Stage.containsKey(c.Id)) {
                c.Stage__c = caseId2Stage.get(c.Id).Id;
                c.Contract_Present__c=true;
                System.debug('caseId2Stage ' + caseId2Stage.get(c.Id));
                System.debug('case ' + c.Id);
            }
        }

        Test.startTest();
        update id2Case.values();
        Test.stopTest();

        List<CaseMilestone> milestones = [SELECT Id, IsCompleted, MilestoneType.Name, CaseId FROM CaseMilestone WHERE CaseId IN : id2Case.keySet()];
        System.assert(!milestones.isEmpty(), 'Milestones should be created');
        for(CaseMilestone cm : milestones) {
            System.assert(cm.IsCompleted, 'CaseMilestone should be completed');
        }
    }
*/
    static testMethod void testUpdateTrigger_unlockCases_casesUnlockedAfterLocking()
    {
        Account org = [SELECT Id FROM Account WHERE Name = :ORG_NAME LIMIT 1];
        Case c = UnitTestHelper.createProcurementCase(org.id);
        insert c;
        Case cIgnore = UnitTestHelper.createProcurementCase(org.id);    // case will be ignored by trigger
        insert cIgnore;

        Approval.lock(c);
        system.assert(Approval.isLocked(c), 'Case should be locked.');
        Approval.lock(cIgnore);
        system.assert(Approval.isLocked(cIgnore), 'Case should be locked.');

        Test.startTest();
        c.IsInApproval__c = true;
        update c;
        system.assert(Approval.isLocked(c), 'Case is locked because future hasn\'t executed yet.');
        update cIgnore;
        Test.stoptest();

        system.assert(!Approval.isLocked(c), 'Case is unlocked because future has executed.');
        system.assert(Approval.isLocked(cIgnore), 'Case is locked because it was ignored by trigger.');
    }

    static testMethod void testUpdateTrigger_updateCaseDuration_durationCalculatedCorrectlyOnClose()
    {

        Account acc = new Account(Name='TestAcc');
        insert acc;

        Contact cntct = new Contact(FirstName = 'This is a',LastName = 'Test', Email='123321@test.com', AccountId= acc.Id);
        insert cntct;

        List<Case> cases = [
            SELECT Id, RecordTypeId, Status, Resolution_1__c, Stage__c, CreatedDate, RecordType.DeveloperName,
                 (SELECT Id FROM Procurement_Stages__r ORDER BY Seq__c DESC LIMIT 1)
            FROM Case 
            WHERE RecordTypeId =: PROC_CALLOFF_RT 
            LIMIT :CaseTriggerHelper.closedCaseStatuses.size()
        ];

        //cases = [select id, Status, Resolution_1__c, Stage__c, CreatedDate, (select id from Procurement_Stages__r order by Seq__c desc limit 1)
        //          from Case where Id in :cases];


        for(Case c : cases) {
            c.Stage__c = c.Procurement_Stages__r.get(0).Id;
            c.ContactId = cntct.Id;
            c.Abandoned_Reason__c='Test reason';
            c.Amended_Date__c=system.today();
            c.Contract_Present__c=true;
        }

        update cases;   // set current stage so we can close the case

        // close the cases
        Integer j=0;
        for(String closedStatus : CaseTriggerHelper.closedCaseStatuses)
        {
            cases.get(j).Status = closedStatus;
            cases.get(j).Resolution_1__c = 'value';
            Test.setCreatedDate(cases.get(j).id, Date.today().addDays(-10*(j+1)));
            j++;
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        cases = [SELECT Status, ClosedDate, Total_Delivery_Days__c, CreatedDate FROM Case WHERE Id IN :cases];

        Date endDate = Date.today();
        {
            BusinessHours bh = [SELECT Id, Name FROM BusinessHours WHERE IsDefault = true AND IsActive = true LIMIT 1];

            Datetime endDateTime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 12, 0, 0);
            while(!BusinessHours.isWithin(bh.Id, endDateTime))
            {
                endDateTime = endDateTime.addDays(-1);
            }
            endDate = endDateTime.date();
        }

        for(Case c : cases)
        {
            system.assertEquals(endDate, DateUtils.addWorkingDays(c.CreatedDate.date(),c.Total_Delivery_Days__c.intValue()),
                'Total_Delivery_Days__c ahould be calculated corectly when status is: ' + c.Status);
        }
    }

    static testMethod void testUpdateTrigger_setApprovalAlertDates()
    {
    // given
    Integer iApproverDays = 2;
    Integer iRequesterDays = 4;

    insert new Org_Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Approver_Alert_Days__c=iApproverDays,
      Requester_Alert_Days__c = iRequesterDays);

    List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: PROC_CALLOFF_RT LIMIT 2];

    cases[0].IsInApproval__c = true;

    //when
    Test.startTest();
      update cases;
    Test.stopTest();

    // then
    Date dExpectedApproval = DateUtils.addWorkingDays(Date.today(), iApproverDays, true);
    Date dExpectedRequester = DateUtils.addWorkingDays(Date.today(), iRequesterDays, true);

    for (Case c : [
        SELECT Id, Approver_Alert_Date_Time__c, Requester_Alert_Date_Time__c FROM Case
        WHERE Id IN :cases])
    {
      if (c.Id == cases[0].Id){
        System.assertEquals(dExpectedApproval, c.Approver_Alert_Date_Time__c.date(), 'Should set approver alert date');
        System.assertEquals(dExpectedRequester, c.Requester_Alert_Date_Time__c.date(), 'Should set requester alert date');
      }
      else {
        System.assertEquals(null, c.Approver_Alert_Date_Time__c, 'Should not set approver alert date');
        System.assertEquals(null, c.Requester_Alert_Date_Time__c, 'Should not set requester alert date');
      }
    }
  }
    
    static testMethod void testPolicyTrigger_addSlaEntitlementAndSetStatus() {
        Trigger_switch__c ts =  new Trigger_switch__c(Case__c = true);
        insert ts;
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: POLICY_RT];
        ts.Case__c = false;
        update ts;
        for(Case cs : cases) {
            cs.RecordTypeId = POLICY_RT; 
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        for(Case c : [SELECT Id, Status, EntitlementId FROM Case WHERE Id IN :cases]) {
            
            System.assertEquals(Org_Settings__c.getOrgDefaults().Policy_Entitlement_ID__c, c.EntitlementId, 'Default EntitlementId should be set');
        }
    }

    static testMethod void testUpdateTrigger_addSlaEntitlementAndSetStatus() {
        Trigger_switch__c ts =  new Trigger_switch__c(Case__c = true);
        insert ts;
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: ENQUIRY_RT];
        ts.Case__c = false;
        update ts;
        for(Case cs : cases) {
            cs.RecordTypeId = PROC_CALLOFF_RT;
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        for(Case c : [SELECT Id, Status, EntitlementId FROM Case WHERE Id IN :cases]) {
            System.assertEquals(Org_Settings__c.getOrgDefaults().Case_Status_In_Progress__c, c.Status, 'Status should be set according to Custom setting');
            System.assertEquals('In Progress', c.Status, 'Status should be set to In Progress');
            System.assertEquals(Org_Settings__c.getOrgDefaults().Entitlement_ID__c, c.EntitlementId, 'Default EntitlementId should be set');
        }
    }

    static testMethod void testInsertTrigger_addSlaEntitlementAndSetStatus() {
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: PROC_CALLOFF_RT LIMIT 200];
        List<Case> newCases = cases.deepClone(false, false, false);
        Test.startTest();
        insert newCases;
        Test.stopTest();

        for(Case c : [SELECT Id, Status, EntitlementId FROM Case WHERE Id IN :newCases]) {
            System.assertEquals(Org_Settings__c.getOrgDefaults().Case_Status_In_Progress__c, c.Status, 'Status should be set according to Custom setting');
            System.assertEquals('In Progress', c.Status, 'Status should be set to In Progress');
            System.assertEquals(Org_Settings__c.getOrgDefaults().Entitlement_ID__c, c.EntitlementId, 'Default EntitlementId should be set');
        }
    }

    static testMethod void testInsertTrigger_aaddEntitlementAndTierLevelForEnquiry() {
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: ENQUIRY_RT LIMIT 200];
        List<Case> newCases = cases.deepClone(false, false, false);
        Test.startTest();
        insert newCases;
        Test.stopTest();
        Tier_Level__c tl = [SELECT Id FROM Tier_Level__c WHERE Is_Default__c = true];
        for(Case c : [SELECT Id, Status, EntitlementId, Tier_Level__c FROM Case WHERE Id IN :newCases]) {
            System.assertEquals(tl.Id, c.Tier_Level__c, 'Tier Level should be set to default one');
            System.assertEquals(Org_Settings__c.getOrgDefaults().Enquiry_Entitlement_ID__c, c.EntitlementId, 'Default EntitlementId should be set');
        }
    }

    static testMethod void test_completeAllMilestonesOnClose() {
        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: ENQUIRY_RT LIMIT 200];
        for(Case c : cases) {
            c.Status = 'Closed';
        }

        Test.startTest();
        update cases;
        Test.stopTest();

        List<CaseMilestone> milestones = [SELECT Id, IsCompleted FROM CaseMilestone WHERE CaseId IN : cases];
        System.assert(!milestones.isEmpty(), 'Milestones should be created');
        for(CaseMilestone cm : milestones) {
            System.assert(cm.IsCompleted, 'CaseMilestone should be completed');
        }
    }

    static testMethod void test_SlaStatusChange() {
        Tier_Level__c tl = [SELECT Id FROM Tier_Level__c WHERE Is_Default__c = false];

        List<Case> cases = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Case WHERE RecordTypeId =: ENQUIRY_RT LIMIT 100];

        for(Case c : cases) {
            c.Tier_Level__c = tl.Id;
        }

        Test.startTest();
        update cases;
        cases = [SELECT Id, SLA_Status__c FROM Case WHERE Id IN :cases];
        Test.stopTest();

        for(Case c : cases) {
            System.assertEquals(CaseUtil.SLA_STATUS_IN_PROGRESS, c.SLA_Status__c, 'Sla status should be In Progress');
        }

        for(Case c : [SELECT Id, SLA_Status__c FROM Case WHERE Id IN :cases]) {
            System.assertEquals(CaseUtil.SLA_STATUS_WARNING, c.SLA_Status__c, 'Sla status should be Warning');
        }
    }
    
 //******************************
    //US547
    //Testing Duration Calculations
    
    static testMethod void testDurationandPlusMinusCalculations(){   
        
        //New Test Account
        Account acc = new Account(Name = 'New Test Account', Sector__c = 'Wider Public Sector', Status__c = 'Active');
        insert acc;

        //New Test Contact
        Contact con = new Contact(FirstName = 'Amorous', LastName = 'Aardvark', Email = 'tristam.hardman@crowncommercial.gov.uk', AccountID = acc.ID );
        insert con;
        
        //New Test Case
        Case cas = new Case(ContactID = con.ID, AccountID = acc.ID);
        insert cas;
        
        //**Check Agreed Target Duration**
        //Check start and finish on same day = 1 day duration
        cas.ITT_Development_Start_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT ITT_Development_Start_Date__c, Agreed_Award_Date__c, Agreed_Target_Duration__c FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Agreed_Target_Duration__c, 1);

        //Check start one day and finish on the next day = 2 days duration
        cas.ITT_Development_Start_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,8); //A Thursday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT ITT_Development_Start_Date__c, Agreed_Award_Date__c, Agreed_Target_Duration__c FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Agreed_Target_Duration__c, 2);
        
        //Check start one day and finish seven calendar-days later = 5 working days duration
        cas.ITT_Development_Start_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,13); //A Tuesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT ITT_Development_Start_Date__c, Agreed_Award_Date__c, Agreed_Target_Duration__c FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Agreed_Target_Duration__c, 5);
        
        
        
        //**Check Planned_v_Agreed_Award_Date Calculations**
        // Check if Planned is one day more than Agreed: Plus/Minus = +1
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Planned_Award_Date__c = date.newInstance(2018,11,8); //A Thursday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Planned_Award_Date__c, Planned_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Planned_v_Agreed_Award_Date__c, 1);
    
        // Check if Planned is the same as Agreed: Plus/Minus = 0
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Planned_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Planned_Award_Date__c, Planned_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Planned_v_Agreed_Award_Date__c, 0);
    
        // Check if Planned is one day before Agreed: Plus/Minus = -1
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Planned_Award_Date__c = date.newInstance(2018,11,6); //A Tuesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Planned_Award_Date__c, Planned_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Planned_v_Agreed_Award_Date__c, -1);

        
        
         //**Check Actual_v_Agreed_Award_Date Calculations**
        // Check if Actual is one day more than Agreed: Plus/Minus = +1
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Actual_Award_Date__c = date.newInstance(2018,11,8); //A Thursday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Actual_Award_Date__c, Actual_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Actual_v_Agreed_Award_Date__c, 1);
    
        // Check if Actual is the same as Agreed: Plus/Minus = 0
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Actual_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Actual_Award_Date__c, Actual_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Actual_v_Agreed_Award_Date__c, 0);
    
        // Check if Actual is one day before Agreed: Plus/Minus = -1
        cas.Agreed_Award_Date__c = date.newInstance(2018,11,7); //A Wednesday
        cas.Actual_Award_Date__c = date.newInstance(2018,11,6); //A Tuesday
        update cas; //Should cause Trigger to fire, updating the Case fields
        cas = [SELECT Agreed_Award_Date__c, Actual_Award_Date__c, Actual_v_Agreed_Award_Date__c  FROM Case WHERE ID =:cas.ID ];
        system.assertEquals(cas.Actual_v_Agreed_Award_Date__c, -1);
        
        
    } 

    
    
    
  
}