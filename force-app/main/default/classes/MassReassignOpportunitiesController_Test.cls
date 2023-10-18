@isTest
public without sharing class MassReassignOpportunitiesController_Test 
{
    @isTest
    public static void testReassign()
	{
		
		Account testAccount = new Account();
		testAccount.Name = 'test';
		insert testAccount;
		
		Opportunity testOpty = new Opportunity();
		testOpty.StageName = 'Discover';
		testOpty.CloseDate = System.today()+1;
		testOpty.AccountId=testAccount.Id;
		testOpty.Name='testOpty';
		testOpty.Type = 'testType';
		insert testOpty;
		
		MassReassignOpportunitiesController controller = new MassReassignOpportunitiesController();
		controller.refreshOptyList();
		controller.filterId = controller.listviewoptions[1].getValue();
		controller.refreshOptyList();
		controller.searchRecord.stageName = 'Discover';
		controller.helperRecord.ClosedDate_From__c=System.today();
		controller.helperRecord.ClosedDate_To__c=System.today()+2;
		controller.helperRecord.From__c=System.today();
		controller.helperRecord.To__c=System.today()+1;
		controller.searchRecord.Type = 'testType';
		controller.refreshOptyListBySearch();
		
		System.assert(controller.optyList.size()>0);
		
		controller.optyList[0].selected = true;
		controller.helperRecord.Assign_to__c = UserInfo.getUserId();
		controller.Assign();
	}
}