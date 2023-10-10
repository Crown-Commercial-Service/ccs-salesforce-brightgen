/*****************************************************************************************************************************
Name: CFI_UpsertContractService_Test

Purpose: Controller extension for upserting opporunity notice in Contract Finder

History
-------
VERSION AUTHOR                                 DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com             12/03/2016      INITIAL DEVELOPMENT
1.1     Cezary Zeleznicki                      11/04/2016      Procurement RT change
1.2 -   danny.evans@crowncommercial.gov.uk     03/09/2018      Added On behalf of Customer and Parent Group
*******************************************************************************************************************************/

public with sharing class CFI_UpsertOpportunityNotice_CX {

    private final Case procurement;
    public List <String> liFields = new LIST<String> {'Procurement_Reference__c','Regions__c',
        'Contract_Finder_Notice_Id__c','Contract_Finder_Title__c','Tender_End_Date__c',
        'Contract_Start_Date__c', 'Contract_End_Date__c', 'Contract_Low_Value__c', 
        'Contract_High_Value__c', 'SME_Suitable__c','VCSE_Suitable__c', 'Additional_CF_Information__c',
        'Contract_Finder_Desc__c', 'RecordType.DeveloperName', 'Contract_Type__c',
        'Synchronised_With_Contract_Finder__c', 'Account.name', 'Account.Parent_Group__c' //Added for US537
    };
    public List <String> liRequiredFields = new LIST<String> {'Procurement_Reference__c','Regions__c',
        'Contract_Finder_Title__c','Tender_End_Date__c', 'Contract_Start_Date__c', 'Contract_End_Date__c', 
        'Contract_Low_Value__c', 'Additional_CF_Information__c', 'Contract_Finder_Desc__c'
    };

   
    public CFI_UpsertOpportunityNotice_CX(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()){
            stdController.addFields(liFields);
        }
        this.procurement = (Case)stdController.getRecord();
        displayWelcomeMessage();
    }

    public Boolean hasEditAccess{
        get {
            if (hasEditAccess == null){
                hasEditAccess = CFI_UpsertContractService.canEditRecord(UserInfo.getUserId(),
                    this.procurement.Id);
            }
            return hasEditAccess;
        }
        set;
    }

    public Boolean disableUpsert{
        get {
            if (disableUpsert == null){
                disableUpsert = String.isNotBlank(procurement.Contract_Finder_Notice_Id__c)
                || procurement.RecordType.DeveloperName.contains('Call_Off')
                || procurement.RecordType.DeveloperName == 'Procurement_Single_Tender_Action'
                || liMissedReqFields.size() > 0 || !hasEditAccess;
            }
            return disableUpsert;
        }
        set;
    }

    public List <String> liMissedReqFields{
        get {
            if (liMissedReqFields == null){
                liMissedReqFields = new List <String>();

                // check contract fields
                for (String strMissedFld : CFI_UpsertContractService.checkIfAllFieldsAreNotNull(procurement, 
                        liRequiredFields)){
                    liMissedReqFields.add('<li>' + strMissedFld + '</li>');
                }

                if (liCPVCodes.size() == 0){
                    liMissedReqFields.add('<li>CPV Codes</li>');
                }

            }

            return liMissedReqFields;
        }
        set;
    }

    List <String> liCPVCodes{
        get {
            if (liCPVCodes == null){
                liCPVCodes = CFI_UpsertContractService.getCPVCodes(procurement);
            }

            return liCPVCodes;
        }
        set;
    }


    /************************************************************
        Purpose: Method for sending Notice to Contract Finder
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/

    public PageReference upsertOpporunityNotice(){
        try{
            if (disableUpsert){
                displayWelcomeMessage();
            }
            else{
                CFI_UpsertContractService ucs = new CFI_UpsertContractService();
                Boolean bSync = ucs.upsertOpporunityNotice(procurement, liCPVCodes);

                if (ucs.liErros != null && ucs.liErros.size() > 0){
                    handleErrors(ucs);
                }
                if(String.isNotBlank(ucs.noticeId)){
                    procurement.Contract_Finder_Notice_Id__c = ucs.noticeId;
                    procurement.Contract_Finder_Additional_Detail_Id__c = ucs.additionalDetailId;
                    procurement.Synchronised_With_Contract_Finder__c = 
                        String.isNotBlank(ucs.additionalDetailId);

                    update procurement;
                    disableUpsert = true;

                    if (String.isNotBlank(ucs.additionalDetailId)){
                        displayMessage(ApexPages.Severity.INFO, Label.CFI_ON_SucessMsg + ucs.noticeId);
                    }
                    else {
                        displayMessage(ApexPages.Severity.WARNING, Label.CFI_ON_FailAdditionalDetails + ucs.noticeId);
                    }
                }
            }

        }
        catch (Exception ex){
            displayMessage(ApexPages.Severity.ERROR, String.format(Label.CFI_UnexpectedError, 
                new List <String> {ex.getMessage()}));
        }
        return null;
    }

    /************************************************************
        Purpose: Helper method for dispalying apex messages
        Parameters: ApexPages.Severit, message
        Returns: -
        Throws: -
    *************************************************************/

    public void displayMessage(ApexPages.Severity lvl, String msg){
        ApexPages.addMessage(new ApexPages.Message(lvl, msg));
    }

    /************************************************************
        Purpose: Helper method for error handling
        Parameters: CFI_UpsertContractService
        Returns: -
        Throws: -
    *************************************************************/

    private void handleErrors(CFI_UpsertContractService ucs){
        for (String errMsg : ucs.liErros){
            displayMessage(ApexPages.Severity.ERROR, errMsg);
        }
    }

    /************************************************************
        Purpose: Method for displaying welcome message to the user based on record state
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/
    @TestVisible
    private void displayWelcomeMessage(){
        if (String.isNotBlank(procurement.Contract_Finder_Notice_Id__c)){
            displayMessage(ApexPages.Severity.INFO, Label.CFI_On_StartMsgAlreadyCreated);
        }
        else if (!hasEditAccess){
            displayMessage(ApexPages.Severity.INFO, Label.CFI_ON_Only_Edit_Access_Can_Send);
        }
        else if (procurement.RecordType.DeveloperName.contains('Call_Off')){
            displayMessage(ApexPages.Severity.INFO, Label.CFI_StartMsgCallOff);
        }
        else if (procurement.RecordType.DeveloperName == 'Procurement_Single_Tender_Action'){            
            displayMessage(ApexPages.Severity.INFO, Label.CFI_StartMsgSinTenAction);
        }
        else if(liMissedReqFields.size() > 0){
            displayMessage(ApexPages.Severity.WARNING, Label.CFI_ReqFieldMissing_ON + ' ' + String.join(liMissedReqFields, ' '));
        }
        else{
            displayMessage(ApexPages.Severity.INFO, Label.CFI_ON_StartMsg);
        }
    }
 }