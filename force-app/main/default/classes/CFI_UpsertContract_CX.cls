/*****************************************************************************************************************************
Name: CFI_UpsertContractService_Test

Purpose: Controller extension for upserting contract in Contract Finder

History
-------
VERSION AUTHOR                                DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com            12/03/2016      INITIAL DEVELOPMENT
1.1 -   danny.evans@crowncommercial.gov.uk    03/09/2018      Added On behalf of Customer and Parent Group
*******************************************************************************************************************************/

public with sharing class CFI_UpsertContract_CX {

    private final CCS_Contract__c ccsContract;
    public List <String> liFields = new LIST<String> {'Contract_Reference__c', 'name',
                'Customer__r.name', 'Start_Date__c', 'End_Date__c', 'Contract_Value__c',
                'Contract_Finder_Notice_Id__c', 'Synchronised_With_Contract_Finder__c',
                'Supplier__r.name', 'Supplier__r.DUNS_Number__c',
                'Supplier__r.BillingStreet', 'Supplier__r.BillingPostalCode', 
                'Supplier__r.BillingCity', 'Supplier__r.BillingCountry', 
                'Supplier__r.SME_Status__c','Supplier__r.Voluntary_Sector_Organisation__c',
                'Supplier_Contact__r.name',
                'Deadline_Date__c', 'Is_Suitable_For_SME__c', 'Is_Suitable_for_VCSE__c',
                'Regions__c', 'Description__c', 'Extension_Options__c', 'Date_Contract_Awarded__c',
                'OJEU_Procedure_Type__c', 'Contract_Type__c', 'Customer__r.Parent_Group__c' //Added for US537
            };

    public List <String> liContractRequiredFields = new LIST<String> {'Contract_Reference__c', 'name',
                'Start_Date__c', 'End_Date__c', 'Contract_Value__c', 'Deadline_Date__c', 'Regions__c', 
                'Description__c','Date_Contract_Awarded__c', 'OJEU_Procedure_Type__c', 'Contract_Type__c',
                'Customer__c', 'Supplier__c', 'Supplier_Contact__c'
            };

    public List <String> liSupplierRequiredFields = new LIST<String> {
                'name', 'DUNS_Number__c','BillingStreet', 'BillingPostalCode', 'BillingCity', 'BillingCountry'
            };

    
    public CFI_UpsertContract_CX(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()){
            stdController.addFields(liFields);
        }
        this.ccsContract = (CCS_Contract__c)stdController.getRecord();
        displayWelcomeMessage();
    }

    public Boolean hasEditAccess{
        get {
            if (hasEditAccess == null){
                hasEditAccess = CFI_UpsertContractService.canEditRecord(UserInfo.getUserId(),
                    this.ccsContract.Id);
            }
            return hasEditAccess;
        }
        set;
    }

    
    public Boolean disableUpsert{
        get {
            if (disableUpsert == null){
                disableUpsert = String.isNotBlank(ccsContract.Contract_Finder_Notice_Id__c)
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
                for (String strMissedFld : CFI_UpsertContractService.checkIfAllFieldsAreNotNull(ccsContract, 
                        liContractRequiredFields)){
                    liMissedReqFields.add('<li>Contract - ' + strMissedFld + '</li>');
                }

                // check supplier (account) fields
                if (ccsContract.Supplier__c != null){
                    for (String strMissedFld : CFI_UpsertContractService.checkIfAllFieldsAreNotNull(ccsContract.Supplier__r, 
                            liSupplierRequiredFields)){
                        liMissedReqFields.add('<li>Supplier - ' + strMissedFld + '</li>');
                    }
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
                liCPVCodes = CFI_UpsertContractService.getCPVCodes(ccsContract);
            }

            return liCPVCodes;
        }
        set;
    }


    /************************************************************
        Purpose: Method for sending Contract to Contract Finder
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/

    public PageReference upsertContract(){
        try{
            if(disableUpsert){
                displayWelcomeMessage();
            }
            else{
                CFI_UpsertContractService ucs = new CFI_UpsertContractService();
                Boolean bSync = ucs.upsertContract(ccsContract, liCPVCodes);

                if (ucs.liErros != null && ucs.liErros.size() > 0){
                    handleErrors(ucs);
                }
                if(String.isNotBlank(ucs.noticeId)){
                    ccsContract.Contract_Finder_Notice_Id__c = ucs.noticeId;
                    ccsContract.Synchronised_With_Contract_Finder__c = bSync;

                    update ccsContract;
                    if (bSync){
                        displayMessage(ApexPages.Severity.INFO, Label.CFI_SuccessMessage + ucs.noticeId);
                    }

                    disableUpsert = true;
                }
            }

        }
        catch (Exception ex){
            displayMessage(ApexPages.Severity.ERROR, 
                String.format(Label.CFI_UnexpectedError, new List <String> {ex.getMessage()}));
        }
        return null;
    }

    /************************************************************
         Purpose: Helper method for dispalying apex messages
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/

    public void displayMessage(ApexPages.Severity lvl, String msg){
        ApexPages.addMessage(new ApexPages.Message(lvl, msg));
    }

    /************************************************************
        Purpose: Helper method for error handling
        Parameters: -
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
        if (String.isNotBlank(ccsContract.Contract_Finder_Notice_Id__c)){
            displayMessage(ApexPages.Severity.INFO, Label.CFI_StartMsgContractCreated);
        }
        else if (!hasEditAccess){
            displayMessage(ApexPages.Severity.INFO, Label.CFI_Only_Edit_Access_Can_Send);
        }
        else if(liMissedReqFields.size() > 0){
            displayMessage(ApexPages.Severity.WARNING, Label.CFI_ReqFieldMissing_AN + ' ' + String.join(liMissedReqFields, ' '));
        }
        else{
            displayMessage(ApexPages.Severity.INFO, Label.CFI_StartMsg);
        }
    }  
}