@isTest
private class ProcurmentStagePreventDeletionTest {

  static final String ORG_NAME = 'Test Org';
  
  static testmethod void testPreventPsDel()
  {
    // create custom settings
    insert UnitTestHelper.createOpsWorkflowStages();
    insert UnitTestHelper.createOpsWorkflowTemplates();
    
    Account org = UnitTestHelper.createOrganisationAccount(ORG_NAME);
    insert org;
    Case c = UnitTestHelper.createProcurementCase(org.id);
    insert c;
      
        Procurement_Stage__c psRecord = new Procurement_Stage__c(Procurement__c= c.Id, name='ITT Live', Seq__c=40);
        insert psRecord;
        
        try{
            delete psRecord;
        }catch(DMLexception e){
            system.assert(e.getMessage().contains('You can not delete ITT Live from a Procurement'),'You can not delete ITT Live from a Procurement');                       
        }
    }
}