/*********************************************************************
 Name:  CaseUtil_Test
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Contains util methods related to Case object
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-20     Initial version
		1.1  Cezary Zeleznicki	2016-11-03		 Procurement RT change
 *********************************************************************/
@isTest
private class CaseUtil_Test {
	
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
		insert new List<Case>{c, c2, c3};
		c3.Status = 'Closed';
		c3.Resolution_1__c = 'Duplicate';
		update c3;
	}
	
	static testMethod void test_bulkMarkSpam() {
		Map<Id, Case> id2Cases = new Map<Id, Case>([SELECT Id FROM Case]);
		List<Case> cases;

		Test.startTest();
		cases = CaseUtil.bulkMarkSpam(id2Cases.keySet());
		Test.stopTest();

		for(Case c : cases) {
			String status = CaseUtil.CASE_STATUS_CLOSED;
			if(CaseUtil.PROCUREMENT_RT_DEV_NAMES.contains(c.RecordType.DeveloperName)) {
				status = CaseUtil.CASE_STATUS_ABANDONED;
			}
			System.assertEquals(status, c.Status, 'Case status should be Closed/Abandoned');
			System.assertEquals(CaseUtil.RESOLUTION_SPAM, c.Resolution_1__c, 'Resolution should be set as Spam');
		}
	}
}