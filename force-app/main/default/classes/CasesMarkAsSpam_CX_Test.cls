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
		1.1  Cezary Zeleznicki 	2016-11-03		 Procurement RT change
		1.2	 Jim MacAulay  		2017-07-27		Changed profile for ProcUser due to sharing changes
 *********************************************************************/
@isTest
private class CasesMarkAsSpam_CX_Test {
	
	@testSetup
	static void createData() {
		Id enquiryCaseRT = [
			SELECT Id, SobjectType, DeveloperName 
			FROM RecordType 
			WHERE SobjectType = 'Case'
				AND DeveloperName = 'Enquiry'
		].Id;

		insert UnitTestDataFactory.createOpsWorkflowStages();
		insert UnitTestDataFactory.createOpsWorkflowTemplates();

		Account org = UnitTestDataFactory.createOrganisationAccount('Test org for unit test - EmailMessageUtilTest');
		insert org;
		Contact con = UnitTestDataFactory.createContact(org.Id);
		insert con;
		Case c = UnitTestDataFactory.createProcurementCase(org.id);
		c.ContactId = con.Id;
		Case c2 = c.clone();
		c2.Origin = 'Email';
		c2.RecordTypeId = enquiryCaseRT;

		Case c3 = c.clone();
		c3.Status = 'Closed';
		c3.Resolution_1__c = 'Test';
        
        Case c4 = c.clone();
		c4.Status = 'Closed';
		c4.Resolution_1__c = 'Spam';
        
        Case c5 = c.clone();
		c5.Status = 'Closed';
		c5.Resolution_1__c = '';
            
        insert new List<Case>{c, c2, c3,c4,c5};
	}

	static testMethod void test_markAsSpam() {
		List<Case> cases = [SELECT Id FROM Case];
		ApexPages.StandardSetController stSetController = new ApexPages.StandardSetController(cases);
		stSetController.setSelected(cases);
		
		Test.startTest();
		CasesMarkAsSpam_CX cmas = new CasesMarkAsSpam_CX(stSetController);
		PageReference returnedPage = cmas.markAsSpam();
		Test.stopTest();

		Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe();
		String param = result.getKeyPrefix();
		for(Case c : [SELECT Id, IsClosed, Resolution_1__c FROM Case WHERE Resolution_1__c != 'Test' AND Resolution_1__c != '' AND Status = 'Closed']) {
            System.debug('test_markAsSpam' +'' + c + c.Resolution_1__c + ' ' + 'CASE SHOULD BE CLOSED' +c.IsClosed);
			System.assertEquals(CaseUtil.RESOLUTION_SPAM, c.Resolution_1__c,
				'Case resolution should be set to Spam');
           
			
            System.assert(c.IsClosed, 'Case should be closed');
		}
		
	}

	static testMethod void test_markAsSpam_SingleRecord() {
		List<Case> cases = [SELECT Id FROM Case];
		Id caseForUpdateId = cases[0].Id;
 
		ApexPages.StandardSetController stSetController = new ApexPages.StandardSetController(cases);
		PageReference pageRef = Page.CasesMarkAsSpam;
		pageRef.getParameters().put('id', String.valueOf(caseForUpdateId));
		Test.setCurrentPage(pageRef);

		Test.startTest();
		CasesMarkAsSpam_CX cmas = new CasesMarkAsSpam_CX(stSetController);
		PageReference returnedPage = cmas.markAsSpam();
		Test.stopTest();

		for(Case c : [SELECT Id, IsClosed, Resolution_1__c FROM Case WHERE Resolution_1__c != 'Test' AND Resolution_1__c != '']) {
			if(c.Id == caseForUpdateId) 
            {
                
				System.assertEquals(CaseUtil.RESOLUTION_SPAM, c.Resolution_1__c,
				'Case resolution should be set to Spam');
				System.assert(c.IsClosed, 'Case should be closed');
			} else {
				System.assert(!c.IsClosed, 'Case should not be closed');
			}
		}
	
	}
	
	static testMethod void test_bulkMarkSpam_Exception() {
		List<Case> cases = [SELECT Id FROM Case FOR UPDATE];
		ApexPages.StandardSetController stSetController = new ApexPages.StandardSetController(cases);
		stSetController.setSelected(cases);
      
        User procUser = UnitTestDataFactory.createUserSystemAdmin('CCS System Administrator','00Eb0000000M4oQEAS');
		insert procUser;
        
        User user = UnitTestDataFactory.createUserFrameworkManager('Read Only');
		insert user;

		Test.startTest();
		CasesMarkAsSpam_CX cmas = new CasesMarkAsSpam_CX(stSetController);
        List<Case> cases1 = [SELECT Id, Status FROM Case];
        cases1[0].Status = '';
		System.runAs(user) 
        {
			cmas.markAsSpam();
            try
            {
              update cases1; 
                
            } catch(DmlException e)
            {
                 List<ApexPages.Message> msgs = ApexPages.getMessages();
               	 Boolean containsException = false;
		            for(ApexPages.Message am : msgs) {
                        if(am.getDetail().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')) 
                        {
				            containsException = true;
			            }
                   System.assert(containsException, 'Exception should be thrown');
		        } 
            }
		}
        
        
		for(Case c : [SELECT Id, IsClosed, Resolution_1__c FROM Case WHERE Resolution_1__c = '' ]) {
			System.assert(String.isBlank(c.Resolution_1__c),'Case resolution should be empty');
			System.assert(!c.IsClosed, 'Case should not be closed');
		}
        
		
        	Test.stopTest();
        
	}
}