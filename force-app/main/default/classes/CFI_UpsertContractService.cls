/*****************************************************************************************************************************
Name: CFI_UpsertContractService

Purpose: Service class for handling upsert operation for integration with Contact Finder

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      07/03/2016      INITIAL DEVELOPMENT
1.1	Cezary Zeleznicki		23/11/2016		Added new custom setting with credentails for sandboxes
1.2 	Cezary Zeleznicki		04/01/2016		Increasing code coverege
*******************************************************************************************************************************/

public without sharing class CFI_UpsertContractService {
/* without sharing since is service class for integration */

	public String baseURL; //API (callout) URL
	public String noticeId; // Contract finder notice id
	public String additionalDetailId; // Contract finder additional details id
	public List <String> liErros; // list of errors

	@TestVisible private String userPass; // encoded username:password
	@TestVisible private String securityToken;
	
	public CFI_UpsertContractService(){
		// intialize variables based on custom setting
		Boolean isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
		Contract_Finder_Integration__c cfi = Contract_Finder_Integration__c.getInstance();
		this.baseURL = isSandbox ? cfi.Test_URL__c : cfi.URL__c;
		this.userPass = isSandbox ? cfi.Test_Credentials__c : cfi.Credential__c;
		liErros = new List <String> ();
	}

    /************************************************************
        Purpose: Method for checking if all required fields have been filled
        Parameters: -
        Returns: HttpResponse 
        Throws: -
    *************************************************************/    
    public static List <String> checkIfAllFieldsAreNotNull (SObject obj, List <String> liRequiredFields){
    	List <String> retVal = new List <String> ();

    	// get fields type
    	Map<String, Schema.SobjectField> fmap = obj.getSobjectType().getDescribe().fields.getMap();

    	for (String apiName : liRequiredFields){
    		Schema.SobjectField fld = fmap.get(apiName);

    		if (fld != null){
    			Schema.DescribeFieldResult dfr = fld.getDescribe();

    			if (dfr.getType() == Schema.DisplayType.String || dfr.getType() == Schema.DisplayType.EncryptedString 
    					|| dfr.getType() == Schema.DisplayType.TextArea){
    				if (String.isBlank((String)obj.get(apiName))){
    					retVal.add(dfr.getLabel());
    				}
    			}
    			else {
    				if (obj.get(apiName) == null){
    					retVal.add(dfr.getLabel());
    				}
    			}

    		}
    		else{
    			throw new CFI_Exception ('Field is not existing: ' + apiName);
    		}
    	}

    	return retVal;
    }

    /************************************************************
        Purpose: Method for getting cpv codes realted to given case
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/
    public static List<String> getCPVCodes(Case procurement){
    	List<String> retVal = new List<String>();

    	for (Procurement_Cat_Code__c pcc : [select Code__r.Name from Procurement_Cat_Code__c 
    			where Procurement__c = :procurement.id and Code__r.Code_Type__c = 'CPV']){
    		retVal.add(pcc.Code__r.Name);
    	}

    	return retVal;
    }


    /************************************************************
        Purpose: Check if user has edit right to record
        Parameters: user id, record id
        Returns:  true if user can edit record
        Throws: -
    *************************************************************/
    public static Boolean canEditRecord (id userId, Id recordId){
    	Boolean retVal = false;
    	List<UserRecordAccess> liUserAccess = [select HasEditAccess,RecordId 
    		from UserRecordAccess where UserId = :userId and RecordId = :recordId];

    	if (liUserAccess.size() > 0){
    		retVal = liUserAccess[0].HasEditAccess;
    	}

    	return retVal;
    }


    /************************************************************
        Purpose: Method for getting cpv codes realted to given contract
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/
    public static  List<String> getCPVCodes(CCS_Contract__c ccsContract){
    	List<String> retVal = new List<String>();

    	for (Level_4_Categorisation_Code_for_Contract__c code : 
    			[select Code__r.Name from Level_4_Categorisation_Code_for_Contract__c 
    			where CCS_Contract__c = :ccsContract.id and Code__r.Code_Type__c = 'CPV']){
    		retVal.add(code.Code__r.Name);
    	}

    	return retVal;
    }

    /************************************************************
        Purpose: Method for making callout
        Parameters: -
        Returns: HttpResponse 
        Throws: -
    *************************************************************/
	public HttpResponse makeCallout(String url, String requestType, String requestBody,
			Map <String, String> mHeaders){
		HttpResponse retVal;
		
		liErros = new List <String> ();
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(requestType);
		req.setBody(requestBody);

		for (String key : mHeaders.keySet()){
			req.setHeader(key, mHeaders.get(key));
		}

		retVal = h.send(req);

		return retVal;
	}

	/************************************************************
        Purpose: Method for creating contract in Contract Finder
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/
    public Boolean upsertContract(CCS_Contract__c ccsContract, List <String> liCPVCodes){
    	// TODO validation before sending (check contact etc.)
    	Boolean bContinue = true;

    	// login
    	if (String.isBlank(securityToken)){
    		bContinue = Test.isRunningTest() ? true : logIn();
    	}

    	if (bContinue){
    		bContinue = insertDraftNotice(ccsContract, liCPVCodes);
    	}

    	if (bContinue){
    		bContinue = insertAward(ccsContract);
    	}

    	if (bContinue){
    		//bContinue = publishNotice(ccsContract); // do not publish as for US610
    	}

    	return bContinue;
    }

	/************************************************************
        Purpose: Method for creating contract in Contract Finder
        Parameters: -
        Returns: -
        Throws: -
    *************************************************************/
    public Boolean upsertOpporunityNotice(Case procurement, List <String> liCPVCodes){
    	// TODO validation before sending (check contact etc.)
    	Boolean bContinue = true;

    	// login
    	if (String.isBlank(securityToken)){
    		bContinue = Test.isRunningTest() ? true : logIn();
    	}

    	if (bContinue){
    		bContinue = insertDraftOpportunityNotice(procurement, liCPVCodes);
    	}

    	if (bContinue){
    		bContinue = insertAdditionalDetails(procurement.Additional_CF_Information__c);
    	}

    	return bContinue;
    }


    /************************************************************
        Purpose: Method for getting security token
        Parameters: -
        Returns: token string
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean logIn(){
		Boolean retVal = false;
		String requestBody = 'grant_type=client_credentials';
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'Basic ' + userPass);
		mHeaders.put('Content-Type', 'application/x-www-form-urlencoded');
		String url = baseURL + '/Token';

		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);
		
		if (res.getStatusCode() == 200){
			CFI_MessageFactory.TokenResp token = (CFI_MessageFactory.TokenResp)
			JSON.deserialize(res.getBody(), CFI_MessageFactory.TokenResp.class);
			securityToken = token.access_token;
			retVal = true;
		}
		else {
			String errorMsg = Label.CFI_LogginErrorMsg;
			liErros.add(errorMsg);
			ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'CFI_UpsertContractService','logIn' ,
                errorMsg, new CFI_Exception (errorMsg),'ERROR',null,null, 
                (Integer)DateTime.now().getTime(), 'CFI'
            );
		}

		return retVal;
	}

    /************************************************************
        Purpose: Method for creating new, draft notice
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean insertDraftNotice(CCS_Contract__c ccsContract, List<String> liCPVCodes){
		Boolean retVal = false;
		String requestBody;
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'bearer ' + securityToken);
		mHeaders.put('Content-Type', 'application/json');
		String url = baseURL + '/Draft/Notice/Add?isPreAwarded=true';

		// get message body
		requestBody = CFI_MessageFactory.generateJSON(
			new CFI_MessageFactory.Notice(ccsContract, liCPVCodes));

		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, requestBody));

		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);

		if (res.getStatusCode() == 200){
			noticeId = res.getBody().replace('"','');
			retVal = true;
		}
		else {
			handleErrorResponce(res, 'insertDraftNotice');
		}

		return retVal;
	}

    /************************************************************
        Purpose: Method for adding new award to notice
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean insertAward(CCS_Contract__c ccsContract){
		Boolean retVal = false;
		String requestBody;
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'bearer ' + securityToken);
		mHeaders.put('Content-Type', 'application/json');
		String url = baseURL + '/Draft/Award/Add';

		// get message body
		requestBody = CFI_MessageFactory.generateJSON(
			new CFI_MessageFactory.Award(ccsContract, noticeId));

		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);

		if (res.getStatusCode() == 200){
			retVal = true;
		}
		else {
			handleErrorResponce(res, 'insertAward');
		}

		return retVal;
	}

    /************************************************************
        Purpose: Method for publishing notice
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean publishNotice(CCS_Contract__c ccsContract){
		Boolean retVal = false;
		String requestBody;
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'bearer ' + securityToken);
		mHeaders.put('Content-Type', 'application/json');
		String url = baseURL + '/Draft/Notice/Publish';

		// get message body
		requestBody = CFI_MessageFactory.generateJSON(
			new CFI_MessageFactory.Publish(noticeId, '', true));

		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);

		if (res.getStatusCode() == 200){
			retVal = true;
		}
		else {
			handleErrorResponce(res, 'publishNotice');
		}

		return retVal;
	}

	/************************************************************
        Purpose: Method for creating new, draft notice
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
	@TestVisible
	private void handleErrorResponce (HttpResponse res, String methodName){
		String errorMsg;
		List <CFI_MessageFactory.ErrorMessage> liEM =  new List <CFI_MessageFactory.ErrorMessage>();
		if (res.getBody().startsWith('[')){
			liEM = (List <CFI_MessageFactory.ErrorMessage>)
				JSON.deserialize(res.getBody(), List<CFI_MessageFactory.ErrorMessage>.class);
		}
		else {
			// Single message
			liEm.add((CFI_MessageFactory.ErrorMessage) 
					JSON.deserialize(res.getBody(), CFI_MessageFactory.ErrorMessage.class));
		}

		for (CFI_MessageFactory.ErrorMessage em : liEM){
			errorMsg = String.format(Label.CFI_CalloutError, new List <String> {em.code, em.message, em.property});
			liErros.add(errorMsg);
			ExceptionLoggingHelper.createErrorLog( UserInfo.getUserId(),'CFI_UpsertContractService',methodName ,
                'Error on callout = ' + errorMsg, new CFI_Exception (errorMsg),'ERROR',null,null, 
                (Integer)DateTime.now().getTime(), 'CFI'
            );		
		}

	}


    /************************************************************
        Purpose: Method for creating new, draft notice
        Parameters: -
        Returns: notice id
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean insertDraftOpportunityNotice(Case procurement, List <String> liCPVCodes){
		Boolean retVal = false;
		String requestBody;
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'bearer ' + securityToken);
		mHeaders.put('Content-Type', 'application/json');
		String url = baseURL + '/Draft/Notice/Add?isPreAwarded=false';

		// get message body
		requestBody = CFI_MessageFactory.generateJSON(
			new CFI_MessageFactory.Notice(procurement, liCPVCodes));

		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, requestBody));
		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);

		if (res.getStatusCode() == 200){
			noticeId = res.getBody().replace('"','');
			retVal = true;
		}
		else {
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, res.getBody()));
			handleErrorResponce(res, 'insertDraftOpportunityNotice');
		}

		return retVal;
	}

    /************************************************************
        Purpose: Send additional details (text) for existing notice
        Parameters: -
        Returns: true - if message was successfully send
        Throws: -
    *************************************************************/
	@TestVisible
	private Boolean insertAdditionalDetails(String text){
		Boolean retVal = false;
		String requestBody;
		Map <String, String> mHeaders = new Map <String, String>();
		mHeaders.put('Authorization', 'bearer ' + securityToken);
		mHeaders.put('Content-Type', 'application/json');
		String url = baseURL + '/Draft/AdditionalDetail/Add';

		// get message body
		requestBody = CFI_MessageFactory.generateJSON(
			new CFI_MessageFactory.AdditionalDetails(noticeId, text));

		HttpResponse res = makeCallout(url, 'POST', requestBody, mHeaders);

		if (res.getStatusCode() == 200){
			additionalDetailId = res.getBody().replace('"','');
			retVal = true;
		}
		else {
			handleErrorResponce(res, 'publishNotice');
		}

		return retVal;
	}



}