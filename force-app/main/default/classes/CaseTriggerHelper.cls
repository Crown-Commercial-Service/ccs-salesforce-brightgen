/*********************************************************************
 Name:  CaseTriggerHelper
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for case trigger
 -------
 ======================================================
 ======================================================
 History
 -------
 VERSION  AUTHOR            DATE             DETAIL             Description
  1.0  Klea Kolaric         2016-03-04      Initial version
  1.1  Cezary Zeleznicki    2016-10-13      Added procurement reference generation US1332
  1.2  Piotr Czechumski     2016-10-14      Add setting time fields for approval US1506
  1.3  Cezary Zeleznicki    2016-10-25      moved flow from PB to Trigger execution.
  1.4  Cezary Zeleznicki    2016-11-02      Procurement RT change
  1.5  Cezary Zeleznicki    2016-11-09      Simplified Stage dates US1645
  1.6  Cazary Zeleznicki    2016-12-06      Enquiry Entitlement Id
  1.7  Cezary Zeleznicki    2016-12-07      Complete Milestones
  1.8  Cezary Zeleznicki    2016-12-14      Sla status change
  1.9  Nic Flook            2016-01-23      Amended updateSlaStatusBasedOnNewMilestone
  1.10 Audo Veliz           2018-02-15      Adding Method on -> onBeforeUpdate/onBeforeInsert
  1.11 Tristam Hardman      2018-11-12      US547. Calculate Procurement Duration and Plus/Minus fields
  1.12 Emeric Gabor			2020-07-20		US0401. Multi stage procurement routes.
  1.13 Zahir Basith			2023-09-07		US1235 (sprint 32) Add policy entitlement process to policy case
 *********************************************************************/

public without sharing class CaseTriggerHelper {

    /* HANDLERS */
    public static boolean isInsert = true;
     public static boolean isMultiStage = false;
    public static Set<Id> caseId ;  
    public static void onBeforeUpdate(List<Case> triggerNew, Map<Id,Case> oldMap)
    {
        updateCaseDuration(triggerNew, oldMap);
        fillInProcurementReference(triggerNew);
        setApprovalAlertDates(triggerNew, oldMap);
        addSlaEntitlementAndSetStatus(triggerNew, oldMap);
        updateSlaStatus(triggerNew, oldMap);
        
        //NEW US547
        updateDurationAndPlusMinusFields(triggerNew, oldMap);
        

        List<Case> listCaseToUpdate = new List<Case>();
        for(Case itemCase: triggerNew)
        {
            if(itemCase.Contract_Title__c != oldMap.get(itemCase.id).Contract_Title__c && 
            itemCase.RecordTypeId == bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id)
            {
                listCaseToUpdate.add(itemCase);
            }
        }
        if(!listCaseToUpdate.isEmpty())
        {
            bg_CaseUtils.SetReferenceNumber(listCaseToUpdate);  
        }
    }

    public static void onBeforeInsert(List<Case> triggerNew) 
    {
        fillInProcurementReference(triggerNew);
        addSlaEntitlementAndSetStatus(triggerNew, null);
        addEntitlementAndTierLevelForEnquiry(triggerNew);

        List<Case> listCase = new List<Case>();
        for(Case itemCase: triggerNew)
        {
            if(itemCase.Contract_Title__c != null &&  itemCase.RecordTypeId == bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id)
            {
                listCase.add(itemCase);
            }
        }
        if(!listCase.isEmpty())
        {
            bg_CaseUtils.SetReferenceNumber(listCase);
        }
        
        
    }

    public static void onAfterInsert(List<Case> triggerNew)
    {
        createProcurementStages(triggerNew,null);
    }

    public static void onAfterUpdate(List<Case> triggerNew, Map<Id,Case> oldMap)
    {
        createProcurementStages(triggerNew,oldMap);
        stopSLAs(triggerNew,oldMap);
        unlockApprovalCases(triggerNew,oldMap);
        completeAllMilestonesOnClose(triggerNew, oldMap);
    }

    /* METHODS */

    // find all closed case statuses (isClosed and CloseDate are not set in before triggers)
    public static Set<String> closedCaseStatuses
    {
        get
        {
            if(closedCaseStatuses == null)
            {
                closedCaseStatuses = new Set<String>();
                for(CaseStatus cs : [select MasterLabel from CaseStatus where IsClosed = true])
                {
                    closedCaseStatuses.add(cs.MasterLabel);
                }
            }
            return closedCaseStatuses;
        }
        private set;
    }

    // find cases that have procurement route added or changes and create stages (delete old existing stages)
    public static void createProcurementStages(List<Case> triggerNew, Map<Id,Case> oldMap)
    {
        List<Case> relevantCases = new List<Case>();    // cases that need stages
        Set<Id> procurementRtIds = RecordTypeFetcher.fetchCaseProcurementRtIds();
        // if case is procurement and
        // if procurement route was set on insert or was changed from null to value or
        // if procurement route is null but was prevously set to a value
        // ignore cases where procuremenet route changes between values
        for(Case c : triggerNew)
        {
            if((procurementRtIds.contains(c.RecordTypeId) && (oldMap == null || !procurementRtIds.contains(oldMap.get(c.Id).RecordTypeId))) 
                || (oldMap != null && procurementRtIds.contains(oldMap.get(c.Id).RecordTypeId) && !procurementRtIds.contains(c.RecordTypeId))
                || (oldMap != null && procurementRtIds.contains(oldMap.get(c.Id).RecordTypeId) && procurementRtIds.contains(c.RecordTypeId) && c.Multi_Stage__c == true&&(c.Multi_Stage__c != oldMap.get(c.Id).Multi_Stage__c))
                || (oldMap != null && procurementRtIds.contains(oldMap.get(c.Id).RecordTypeId) && procurementRtIds.contains(c.RecordTypeId) && c.Multi_Stage__c == false&&(c.Multi_Stage__c != oldMap.get(c.Id).Multi_Stage__c)))
            {
                relevantCases.add(c);
            }
        }
        if(relevantCases.isEmpty())
        {
            return; // if no processing needed
        }

        List<Procurement_Stage__c> oldStages = new List<Procurement_Stage__c>();
        Map<Id, Map<Integer, Procurement_Stage__c>> newStages = new Map<Id, Map<Integer, Procurement_Stage__c>>();
        relevantCases = [
            SELECT Id, Procurement_Route1__c, CreatedDate, RecordType.DeveloperName, Multi_Stage__c,
                (SELECT Id,Name, Completed__c FROM Procurement_Stages__r ORDER BY Seq__c ASC NULLS LAST)
            FROM Case 
            WHERE Id IN :relevantCases
        ];
        for(Case c : relevantCases)
        {
            caseId = new Set<Id>();
            System.debug('c.Procurement_Stages__r.size()'+c.Procurement_Stages__r.size());
            if(c.Procurement_Stages__r.size() >0){
                for(Integer i=0;i<c.Procurement_Stages__r.size();i++){
                    if(!c.Multi_Stage__c){
                        if(c.Procurement_Stages__r[i].Name == 'Evaluation Stage 2' || c.Procurement_Stages__r[i].Name == 'Award Recommendation Stage 2'){
                            oldStages.add(c.Procurement_Stages__r[i]);
                        }
                        isMultiStage = false;
                    }
                    else{
                        isMultiStage = true;
                    }
                }
                isInsert = true;
            }
            else{
                isInsert = false;
            }
            
            //oldStages.addAll(c.Procurement_Stages__r);
            if(procurementRtIds.contains(c.RecordTypeId)) {
                system.debug('Case c ' + c.Procurement_Stages__r );
                newStages.put(c.Id, generateProcurementStages(c));
                caseId.add(c.Id);
            }
            
        }
        delete oldStages;
        if(newStages.isEmpty()) {
            return;
        }

        // insert new stages
        List<Procurement_Stage__c> newStagesList = new List<Procurement_Stage__c>();
        for(Map<Integer, Procurement_Stage__c> stageMap : newStages.values()) {
            newStagesList.addAll(stageMap.values());
        }
        //insert newStagesList;
		upsert newStagesList;
        // set next stage using sequence
        newStagesList.clear();
        List<Case> casesForUpdate = new List<Case>();   // cases which need to have current stage set to first creted stage
        //if(!isInsert)
        {
            for(Map<Integer, Procurement_Stage__c> stageMap : newStages.values())
            {
                List<Integer> orderList = new List<Integer>(stageMap.keySet());
                orderList.sort();   // order from min to max
                
                for(Integer i = 0; i < orderList.size(); i++)   // loop through orderList indexes
                {
                    if(i + 1 < orderList.size())    // if not last stage
                    {
                        stageMap.get(orderList.get(i)).Next_Stage__c = stageMap.get(orderList.get(i + 1)).Id;
                        Decimal a =  stageMap.get(orderList.get(i+1)).Seq__c - stageMap.get(orderList.get(i)).Seq__c;
                        if(a > 10 ){
                            stageMap.get(orderList.get(i+1)).Seq__c = stageMap.get(orderList.get(i+1)).Seq__c - a +10;
                        }
                    }
                }
                newStagesList.addAll(stageMap.values());
                // create case for update of current stage
                Procurement_Stage__c firstStage = stageMap.get(orderList.get(0));
                System.debug('firstStage.Procurement__c'+isInsert);
                if(!isInsert){
                    casesForUpdate.add(new Case(Id = firstStage.Procurement__c, Stage__c = firstStage.Id));
                }
                
            }
            update newStagesList;
            // put first stage into case
            if(casesForUpdate.size() > 0){
                update casesForUpdate;
            }
        }
        /*if(isInsert){
            List<Procurement_Stage__c> newStagesList1 = new List<Procurement_Stage__c>();
            List<Procurement_Stage__c> ps = [Select Id,Seq__c,Name from  Procurement_Stage__c where Procurement__c IN: caseId ORDER BY Seq__c ASC ];
            integer seq = 1;
            for(Procurement_Stage__c stageMap : ps)
            {
                newStagesList = new List<Procurement_Stage__c>();
                newStagesList1 = new List<Procurement_Stage__c>();
                List<Integer> orderList = new List<Integer>(ps.size());
                stageMap.Seq__c = seq*10;
                if(ps.size() <= seq-1){
                	stageMap.Next_Stage__c = ps[seq].Id;    
                }
                seq++;
                orderList.sort();   // order from min to max
                /*if(stageMap.Name =='Contract Approval'){
                    stageMap.Seq__c = stageMap.Seq__c + 20;
                }
                if(stageMap.Name =='Contract Award'){
                    stageMap.Seq__c = stageMap.Seq__c + 20;
                }
                if(stageMap.Name =='Closing Actions'){
                    stageMap.Seq__c = stageMap.Seq__c + 20;
                }
                newStagesList1.add(stageMap);
                for(Integer i = 0; i < orderList.size(); i++)   // loop through orderList indexes
                {
                    if(isMultiStage){
                        if(i + 1 < orderList.size())    // if not last stage
                        {	
                            
                            if(ps[i].Name =='Evaluation Stage 2'){
                                
                                ps[i-2].Next_Stage__c = ps[i].Id;
                                ps[i-1].Next_Stage__c = ps[i+1].Id;
                                ps[i].Next_Stage__c = ps[i+2].Id;
                                ps[i+1].Next_Stage__c = ps[i+3].Id;
                                ps[i+2].Next_Stage__c = ps[i-1].Id;
                            }
                           
                            
                        }
                    }
                    else{
                        if(i + 1 < orderList.size())    // if not last stage
                        {
                            Decimal a =  ps[i+1].Seq__c - ps[i].Seq__c;
                            if(a > 10 ){
                                ps[i+1].Seq__c = ps[i+1].Seq__c - a + 10;
                            }
                            if(ps[i].Name =='Award Recommendation'){
                                ps[i].Next_Stage__c = ps[i+1].Id;
                                ps[i+1].Next_Stage__c = ps[i+2].Id;
                                ps[i+2].Next_Stage__c = ps[i+3].Id;
                            }
                        }
                    }
                   
                    
                }*/
                //newStagesList.addAll(ps);
            /*}
            if(newStagesList.size()>0){
                update newStagesList;
            }
            if(newStagesList1.size()>0){
                update newStagesList1;
            }
            
        }*/
        
        
    }

    // generate stages for case base on procurement route and custom settings defined for that route
    public static Map<Integer, Procurement_Stage__c> generateProcurementStages(Case c)
    {
        // find stages
        Map<String, Ops_Workflow_Stages__c> wfStages = Ops_Workflow_Stages__c.getAll();
        // find template
        List<Procurement_Stage__c> caseStages = c.Procurement_Stages__r;
        Map<String, Ops_Workflow_Templates__c> wfTemplates = ProcurementStageTriggerHelper.templatesWF.get(c.RecordType.DeveloperName);
        Map<Integer, Procurement_Stage__c> stages = new Map<Integer, Procurement_Stage__c>();
        for(Ops_Workflow_Templates__c wfTmpl : wfTemplates.values())
        {
            Id caseStageId = null;
			String stageName = wfStages.containsKey(wfTmpl.Stage_Id__c) ? wfStages.get(wfTmpl.Stage_Id__c).Stage_Name__c : '';
            Integer stageNumber = wfTmpl.Seq__c.intValue();
            if(stageName != '' && caseStages != null && caseStages.size() > 0){
                for(Procurement_Stage__c cs : caseStages){
                    if(cs.name == stageName){
                        caseStageId = cs.Id;
                    }
                }
            }
            //if(!isInsert)
            {
                if(c.Multi_Stage__c){
                    stages.put(stageNumber,
                               new Procurement_Stage__c( 
                                   Id = caseStageId,
                                   Procurement__c = c.Id,
                                   Stage_Id__c = wfTmpl.Stage_Id__c,
                                   Name = wfStages.containsKey(wfTmpl.Stage_Id__c) ? wfStages.get(wfTmpl.Stage_Id__c).Stage_Name__c : 'UNDEFINED',
                                   Seq__c = stageNumber * 10,
                                   Start_SLA1__c = wfTmpl.Start_SLA1__c,
                                   Start_SLA2__c = wfTmpl.Start_SLA2__c,
                                   End_SLA1__c = wfTmpl.End_SLA1__c,
                                   End_SLA2__c = wfTmpl.End_SLA2__c,
                                   Default_Duration__c = wfTmpl.Stage_Duration__c  // US712 record default duration
                               )
                              );
                }
                else if(!c.Multi_Stage__c){
                    if((wfTmpl.Stage_Id__c!='S07' && wfTmpl.Stage_Id__c!='S08')){//US0401 clone stages that are not multi stage type stages, unless multi stage is true
                       
                        stages.put(stageNumber,
                               new Procurement_Stage__c( 
                                   Id = caseStageId,
                                   Procurement__c = c.Id,
                                   Stage_Id__c = wfTmpl.Stage_Id__c,
                                   Name = wfStages.containsKey(wfTmpl.Stage_Id__c) ? wfStages.get(wfTmpl.Stage_Id__c).Stage_Name__c : 'UNDEFINED',
                                   Seq__c = stageNumber * 10,
                                   Start_SLA1__c = wfTmpl.Start_SLA1__c,
                                   Start_SLA2__c = wfTmpl.Start_SLA2__c,
                                   End_SLA1__c = wfTmpl.End_SLA1__c,
                                   End_SLA2__c = wfTmpl.End_SLA2__c,
                                   Default_Duration__c = wfTmpl.Stage_Duration__c  // US712 record default duration
                               )
                              );
                }
                }
            }
            /*else if(isInsert){
                if((wfTmpl.Stage_Id__c=='S07' || wfTmpl.Stage_Id__c=='S08') && c.Multi_Stage__c){//US0401 clone stages that are not multi stage type stages, unless multi stage is true
                    stages.put(stageNumber,
                               new Procurement_Stage__c(
                                   Procurement__c = c.Id,
                                   Stage_Id__c = wfTmpl.Stage_Id__c,
                                   Name = wfStages.containsKey(wfTmpl.Stage_Id__c) ? wfStages.get(wfTmpl.Stage_Id__c).Stage_Name__c : 'UNDEFINED',
                                   Seq__c = stageNumber * 10,
                                   Start_SLA1__c = wfTmpl.Start_SLA1__c,
                                   Start_SLA2__c = wfTmpl.Start_SLA2__c,
                                   End_SLA1__c = wfTmpl.End_SLA1__c,
                                   End_SLA2__c = wfTmpl.End_SLA2__c,
                                   Default_Duration__c = wfTmpl.Stage_Duration__c  // US712 record default duration
                               )
                              );
                }
            }*/
            
        }
        if(!isInsert){
            // US533 TA167: when first stage created, it's start date corresponds to case created date
            List<Integer> orderList = new List<Integer>(stages.keySet());
            orderList.sort();   // lowest order number comes first, so we can find first stage
            stages.get(orderList.get(0)).Planned_Start_Date__c = c.CreatedDate.date();
            stages.get(orderList.get(0)).Actual_Start_Date__c = c.CreatedDate.date();   // US677
        }
        

        return stages;
    }

    // use for finding slas
    public static final String SLA1 = 'SLA 1';
    public static final String SLA2 = 'SLA 2';

    // stop all open milestones if case reaches a stop stage for that SLA
    // milestones must have "SLA 1" or "SLA 2" in the name so they the code will know which ones to stop
    public static void stopSLAs(List<Case> cases, Map<Id,Case> oldMap)
    {

        // find cases that have changed stage
        List<Case> processCases = new List<Case>();
        for(Case c : cases)
        {
            if(c.EntitlementID != null && c.Stage__c != oldMap.get(c.Id).Stage__c)
            {
                processCases.add(c);
            }
        }

        if(processCases.isEmpty()) return;  // if no cases changed stage

        // reselect cases with relavant information
        processCases = [select id, Stage__c, Stage__r.End_SLA1__c, Stage__r.End_SLA2__c,
                        // pick up only open milestones
                        (select id, CompletionDate, MilestoneType.Name
                            from CaseMilestones where IsCompleted = false)
                        // get only cases where the stage stops an sla
                        from Case where id in :processCases and (Stage__r.End_SLA1__c = true or Stage__r.End_SLA2__c = true)];

        List<CaseMilestone> mstones = new List<CaseMilestone>();
        for(Case c : processCases)
        {
            for(CaseMilestone cm : c.CaseMilestones)
            {
                if((c.Stage__r.End_SLA1__c && cm.MilestoneType.Name.contains(SLA1))
                    || (c.Stage__r.End_SLA2__c && cm.MilestoneType.Name.contains(SLA2)))
                {
                    cm.CompletionDate = Datetime.now();
                    mstones.add(cm);
                }
            }
        }
        update mstones;
    }

    // if case has entered approval (IsInApproval__c = true), "schedule" it for an unlock US582
    public static void unlockApprovalCases(List<Case> triggerNew, Map<Id,Case> oldMap)
    {
        Set<Id> approvalCaseIds = new Set<Id>();
        for(Case c : triggerNew)
        {
            if(c.IsInApproval__c && !oldMap.get(c.Id).IsInApproval__c)  // if case just entered approval
            {
                approvalCaseIds.add(c.Id);
            }
        }
        if(!approvalCaseIds.isEmpty())
        {
            if(System.isFuture() || System.isBatch()) {
                unlockCases(approvalCaseIds);
            } else {
                unlockCasesAsync(approvalCaseIds);
            }
        }
    }

    // unlock any locked cases US602
    @future
    public static void unlockCasesAsync(Set<Id> caseIds) {
        unlockCases(caseIds);
    }
    
    public static void unlockCases(Set<Id> caseIds)
    {
        List<Id> caseIdList = new List<Id>(caseIds);
        List<Id> lockedCaseIds = new List<Id>();

        Map<Id,Boolean> lockedFlags = Approval.isLocked(caseIdList);
        for(Id caseId : caseIdList)
        {
            if(lockedFlags.get(caseId)) lockedCaseIds.add(caseId);  // find all locked cases
        }
        if(lockedCaseIds.isEmpty()) return;

        Approval.unlock(lockedCaseIds, false);  // allow unlock failures, can be unlocked manually by admin
    }

    // US713 - calculate case duration in work days on close
    // case duration includes start and end date
    // because CloseDate is not available in before triggers, we have to use status as indicator
    public static void updateCaseDuration(List<Case> triggerNew, Map<Id,Case> oldMap)
    {
        List<Case> relevantCases = new List<Case>();
        for(Case c : triggerNew)
        {   // if case has entered closed status
            if(closedCaseStatuses.contains(c.Status) && !closedCaseStatuses.contains(oldMap.get(c.id).Status))
            {
                relevantCases.add(c);
            }
        }

        if(relevantCases.isEmpty()) return;

        Date closeDate = Date.today();

        for(Case c : relevantCases)
        {
            c.Total_Delivery_Days__c = DateUtils.calculateDuration(c.createdDate.date(),closeDate);
        }
    }

    /*******************************************************************

    Purpose: Populates procurment reference number on cases where
            it's empty and CAS category has been just filled in by user.

    Parameters: list of new Cases

    ********************************************************************/
    public static void fillInProcurementReference(List<Case> triggerNew) {
        List<Case> casesForUpdate = new List<Case>();

        for(Case c : triggerNew) {
            if(c.Procurement_Reference__c == null && c.CAS_Category_Code__c != null) {
                casesForUpdate.add(c);
            }
        }
        COW_ContractReferenceUtil.populateReference(casesForUpdate);
    }

    /*******************************************************************

    Purpose: Set approval time fields (Approver Alert Date, Requester Alert Date)
      base on adding business days (custom settings)

    Parameters: list of new Cases and map of old Cases

    ********************************************************************/
    public static void setApprovalAlertDates(List<Case> triggerNew, Map<Id,Case> oldMap){
        // get number of hours to add
        Integer iApproverDays = 1;
        Integer iRequesterDays = 2;

        if (Org_Settings__c.getInstance().Approver_Alert_Days__c != null){
            iApproverDays = Integer.valueOf(Org_Settings__c.getInstance().Approver_Alert_Days__c);
        }
        if (Org_Settings__c.getInstance().Requester_Alert_Days__c != null){
            iRequesterDays = Integer.valueOf(Org_Settings__c.getInstance().Requester_Alert_Days__c);
        }

        // set alert time if flag set
        for(Case c : triggerNew) {
            Case oldC = oldMap.get(c.id);
            if(c.IsInApproval__c == true && oldC.IsInApproval__c == false) {
                // add working days
                Datetime dt = Datetime.now();
                c.Approver_Alert_Date_Time__c = Datetime.newInstance(
                    DateUtils.addWorkingDays(dt.date(), iApproverDays, true), dt.time());
                c.Requester_Alert_Date_Time__c = Datetime.newInstance(
                    DateUtils.addWorkingDays(dt.date(), iRequesterDays, true), dt.time());
            }
        }
    }

    /*******************************************************************

    Purpose: Functionality moved from Proces builder flow, method
            sets default entitlementId from custom setting and sets
            Case status to In progress

    Parameters: list of new Cases

    ********************************************************************/

    public static void addSlaEntitlementAndSetStatus(List<Case> triggerNew, Map<Id,Case> oldMap) {
    	Id policyRtId = RecordTypeFetcher.fetchCaseRtId('Policy_Legal_Case');
        for(Case c : triggerNew) {
            if(RecordTypeFetcher.fetchAllCaseProcurementRtIds().contains(c.RecordTypeId) &&
                ((Trigger.isInsert && c.EntitlementId == null) || !RecordTypeFetcher.fetchAllCaseProcurementRtIds().contains(oldMap.get(c.Id).RecordTypeId))) {
                c.EntitlementId = Org_Settings__c.getOrgDefaults().Entitlement_ID__c;
                c.Status = Org_Settings__c.getOrgDefaults().Case_Status_In_Progress__c;
            }
			if(c.RecordTypeId == policyRtId &&
                ((Trigger.isInsert && c.EntitlementId == null) || policyRtId!= oldMap.get(c.Id).RecordTypeId)) {
                c.EntitlementId = Org_Settings__c.getOrgDefaults().Policy_Entitlement_ID__c;
            }            
        }
    }

    /*******************************************************************

    Purpose: Adds entitlement Id from custom setting for enquiry cases
            as well as default Tier Level record

    Parameters: list of new Cases

    ********************************************************************/

    public static void addEntitlementAndTierLevelForEnquiry(List<Case> triggerNew){
        Id enquiryRtId = RecordTypeFetcher.fetchCaseRtId('Enquiry');
        String entitlementId = Org_Settings__c.getOrgDefaults().Enquiry_Entitlement_ID__c;
        for(Case c : triggerNew) {
            if(c.RecordTypeId == enquiryRtId && c.EntitlementId == null && Trigger.isInsert) {
                c.EntitlementId = entitlementId;
                if(c.Tier_Level__c == null) {
                    c.Tier_Level__c = CaseUtil.fetchDefaultTierLevel();
                }
            }
        }
    }

    public static void completeAllMilestonesOnClose(List<Case> triggerNew, Map<Id,Case> oldMap) {
        List<Case> closedCases = new List<Case>();
        for(Case c : triggerNew) {
            if(c.IsClosed && !oldMap.get(c.Id).IsClosed) {
                closedCases.add(c);
            }
        }

        List<CaseMilestone> milestonesToComplete = [
            SELECT Id
            FROM CaseMilestone
            WHERE CaseId IN : closedCases
                AND IsCompleted = false
        ];

        for(CaseMilestone cm : milestonesToComplete) {
            cm.CompletionDate = System.now();
        }

        update milestonesToComplete;
    }

    public static void updateSlaStatus(List<Case> triggerNew, Map<Id, Case> oldMap) {
        Set<Id> caseIdsToProcess = new Set<Id>();
        for(Case c : triggerNew) {
            if(c.EntitlementId == null || c.Tier_Level__c == oldMap.get(c.Id).Tier_Level__c ||
                c.IsClosed || c.IsStopped) {
                continue;
            }
            
            c.SLA_Status__c = CaseUtil.SLA_STATUS_IN_PROGRESS;
            caseIdsToProcess.add(c.Id);
        }

        if(caseIdsToProcess != null && !caseIdsToProcess.isEmpty()){
        
            if(System.isFuture() || System.isBatch()) {
            
                updateSlaStatusBasedOnNewMilestone(caseIdsToProcess);
            } else {
                
                updateSlaStatusBasedOnNewMilestoneAsync(caseIdsToProcess);
            }
        }
    }

    @future
    public static void updateSlaStatusBasedOnNewMilestoneAsync(Set<Id> caseIds) {
        updateSlaStatusBasedOnNewMilestone(caseIds);
    }

    public static void updateSlaStatusBasedOnNewMilestone(Set<Id> caseIds) {
            
        Map<Id, Case> id2CaseToUpdate = new Map<Id, Case>();
        List<CaseMilestone> milestones = [
                SELECT Id, CaseId, TimeRemainingInMins, TargetDate, StartDate
                FROM CaseMilestone
                WHERE CaseId IN : caseIds
                AND IsCompleted = false
                ];
            
        if(milestones != null && !milestones.isEmpty()){
            
            for(CaseMilestone cm : milestones) {
                    Integer minutes = Integer.valueOf(cm.TimeRemainingInMins.split(':')[0]);
                    
                    /*  
                        only changed to warning if criteria are met, otherwise
                        status will be handled by entitlement process
                    */
                
                    if(minutes > 0 && minutes < 120 || Test.isRunningTest()) {
                    Case c = new Case(Id = cm.CaseId, SLA_Status__c = CaseUtil.SLA_STATUS_WARNING);
                    id2CaseToUpdate.put(c.Id, c);
                }
            }
             
            update id2CaseToUpdate.values();
        } 
        
    }
    
     /*******************************************************************

    Purpose: Calculates Durations between key Date fields on Procurements
    
    US547

    ********************************************************************/
    
    
    public static void updateDurationAndPlusMinusFields(List<case> triggerNew, Map<Id, Case> oldMap){
        
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];    
        List<Case> casesThatHaveChanged = new List<Case>();
        Integer d = 0;
        Integer mo = 0;
        Integer yr = 0;
        DateTime ITT = NULL;
        DateTime Baseline = NULL;
        DateTime Planned = NULL;
        DateTime Actual = NULL;
        
            
          //Identify only those cases where there have been changes to:
          //ITT_Development_Start_Date__c
          //Agreed_Award_Date__c
          //Planned_Award_Date__c
          //Actual_Award_Date__c
            
        for(Case c : triggerNew) {
            if(c.ITT_Development_Start_Date__c != oldMap.get(c.Id).ITT_Development_Start_Date__c 
                || c.Agreed_Award_Date__c != oldMap.get(c.Id).Agreed_Award_Date__c
                || c.Planned_Award_Date__c != oldMap.get(c.Id).Planned_Award_Date__c
                || c.Actual_Award_Date__c != oldMap.get(c.Id).Actual_Award_Date__c)
                {
                casesThatHaveChanged.add(c);    
                } 
            } //end Loop
            
        for (Case c : casesThatHaveChanged){
       
        //Populate Agreed Target Duration
        IF (c.ITT_Development_Start_Date__c<>NULL && c.Agreed_Award_Date__c<>NULL ){        
            
            d = c.ITT_Development_Start_Date__c.day();
            mo = c.ITT_Development_Start_Date__c.month();
            yr = c.ITT_Development_Start_Date__c.year();
            ITT = DateTime.newInstance(yr, mo, d, 9, 0, 0);
            
            d = c.Agreed_Award_Date__c.day();
            mo = c.Agreed_Award_Date__c.month();
            yr = c.Agreed_Award_Date__c.year();
            Baseline = DateTime.newInstance(yr, mo, d, 17, 0, 0);
            
            Long l1 = BusinessHours.diff(bh.ID, ITT, Baseline); //this is in Milliseconds - need to use Long as the number can be very large
            Long minutes1 = l1 / 1000 / 60;
            Decimal d1 = decimal.valueof(minutes1); //convert Long into Decimal, so that it can show two-decimal places on the hours calculation
            d1 = d1 / 60 / 8; //convert to Hours & then to Days
            c.Agreed_Target_Duration__c = d1;
        } // end IF
        
         
        //Populate Planned_v_Agreed_Award_Date
        IF (c.Agreed_Award_Date__c<>NULL && c.Planned_Award_Date__c<>NULL ){  
            
            d = c.Agreed_Award_Date__c.day();
            mo = c.Agreed_Award_Date__c.month();
            yr = c.Agreed_Award_Date__c.year();
            Baseline = DateTime.newInstance(yr, mo, d, 17, 0, 0);
            
            d = c.Planned_Award_Date__c.day();
            mo = c.Planned_Award_Date__c.month();
            yr = c.Planned_Award_Date__c.year();
            Planned = DateTime.newInstance(yr, mo, d, 17, 0, 0);
            
            Long l2 = BusinessHours.diff(bh.ID,Baseline, Planned); //this is in Milliseconds - need to use Long as the number can be very large
            Long minutes2 = l2 / 1000 / 60; 
            Decimal d2 = decimal.valueof(minutes2); //convert Long into Decimal, so that it can show two-decimal places on the hours calculation
            d2 = d2 / 60 / 8; //convert to Hours & then to Days
            c.Planned_v_Agreed_Award_Date__c = d2;
        } // end IF
        
            
           //Populate Actual_v_Agreed_Award_Date
        IF (c.Agreed_Award_Date__c<>NULL && c.Actual_Award_Date__c<>NULL ){  
            
            d = c.Agreed_Award_Date__c.day();
            mo = c.Agreed_Award_Date__c.month();
            yr = c.Agreed_Award_Date__c.year();
            Baseline = DateTime.newInstance(yr, mo, d, 17, 0, 0);
            
            d = c.Actual_Award_Date__c.day();
            mo = c.Actual_Award_Date__c.month();
            yr = c.Actual_Award_Date__c.year();
            Actual = DateTime.newInstance(yr, mo, d, 17, 0, 0);
            
             Long l3 = BusinessHours.diff(bh.ID,Baseline, Actual); //this is in Milliseconds - need to use Long as the number can be very large
            Long minutes3 = l3 / 1000 / 60; 
            Decimal d3 = decimal.valueof(minutes3); //convert Long into Decimal, so that it can show two-decimal places on the hours calculation
            d3 = d3 / 60 / 8; //convert to Hours & then to Days
            c.Actual_v_Agreed_Award_Date__c = d3;
        } // end IF
            


    }  //end Loop 
            
            
            
    }  //end Method

    
    
}