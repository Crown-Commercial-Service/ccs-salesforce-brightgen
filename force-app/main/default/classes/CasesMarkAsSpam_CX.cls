/*********************************************************************
 Name:  CasesMarkAsSpam_CX
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller for CasesMarkAsSpam page
				responsible for bulk mark cases from list view
				as spam
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-21     Initial version
 *********************************************************************/
public with sharing class CasesMarkAsSpam_CX {

	private final ApexPages.StandardSetController stSetController;

	public CasesMarkAsSpam_CX(ApexPages.StandardSetController stSetController) {
		this.stSetController = stSetController;
	}

	public PageReference markAsSpam() {
		List<Case> cases = (List<Case>) stSetController.getSelected();
		Case c;
		if(cases.isEmpty()) {
			c = new Case(Id = ApexPages.currentPage().getParameters().get('id'));
			cases = new List<Case>{c};
		}

		Map<Id, Case> id2selectedCases = new Map<Id, Case>(cases);
		try {
			update CaseUtil.bulkMarkSpam(id2selectedCases.keySet());
		} catch(Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
		
		Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
		String param = result.getKeyPrefix();
		if(c != null) {
			param = c.Id;
		}
		PageReference pageRef = new PageReference('/' + param); 
		pageRef.setRedirect(true); 
		return pageRef; 
	}
}