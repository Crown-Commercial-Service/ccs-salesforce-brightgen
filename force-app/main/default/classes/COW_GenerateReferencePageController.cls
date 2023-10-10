/*********************************************************************
 Name:  COW_GenerateReferencePageController
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: controller for COW_GenerateReferencePage                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-05		 Initial version 	US596
 *********************************************************************/
public with sharing class COW_GenerateReferencePageController {
	
	public static final String RECORDID_PARAM = 'recordId';
	public static final String CATCODE_PARAM = 'catCode';
	public static final String REFFIELD_PARAM = 'refField';
	
	public Id recordId {get; private set;}
	public String categoryCode {get; private set;}
	public String referenceField {get; private set;}
	
	public Boolean allowRetry {get; private set;}
	
	public COW_GenerateReferencePageController()
	{
		categoryCode = ApexPages.currentPage().getParameters().get(CATCODE_PARAM);
		recordId = (Id) ApexPages.currentPage().getParameters().get(RECORDID_PARAM);
		referenceField = ApexPages.currentPage().getParameters().get(REFFIELD_PARAM);
		allowRetry = false;
	}	
	
	public void actionGenerateRef()
	{
		if(String.isBlank(referenceField))
		{
			Schema.sobjectType sobjType = recordId.getSObjectType();
			if(COW_ContractReferenceUtil.referenceFields.containsKey(sobjType))	// check if ref field is maybe predefined
			{
				referenceField = COW_ContractReferenceUtil.referenceFields.get(sobjType);
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
					String.format(Label.COW_ProvideFieldParameter,new List<String>{REFFIELD_PARAM})));
				return;
			}
		}
		
		try
		{
			String refCode = COW_ContractReferenceUtil.populateRefrence(recordId,categoryCode,referenceField);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,
				String.format(Label.COW_ReferenceCreated,new List<String>{refCode})));
		}
		catch(QueryException qe)
		{
			allowRetry = true;	// if you were not allowed to lock record, you can retry
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
				String.format(Label.COW_REFERENCECONFLICT, new List<String>{categoryCode})));
		}
		catch(exception e)
		{
			ApexPages.addMessages(e);
		}
	}
	
	public pageReference backAction()
	{
		return new Pagereference('/' + recordId);
	}
	
	public pageReference retryAction()
	{
		pageReference ret = new Pagereference(Apexpages.currentPage().getUrl());
		ret.setRedirect(true);
		return ret;
	}
    
}