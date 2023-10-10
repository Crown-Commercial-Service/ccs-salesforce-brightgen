/*
* Author: Emeric Gabor
* CreatedDate: 14/09/2021 
* Description: Class to acheieve Test Coverage of OpportunityEmailServiceInbound
*/


@isTest
public class OpportunityEmailServiceInbound_Test {
    static testMethod void insertNewOpportunity() {
    
        User u = [SELECT ID FROM User WHERE Email= 'john.denford@crowncommercial.gov.uk' LIMIT 1];
        
        Test.startTest();
        System.runAs(u){
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity Triggers',
            CloseDate =  System.Today(),           
            StageName = 'Stage 0 = Need Identified'            
        );
        insert testOpportunity;
        
        Opportunity opp = [Select id,Opportunity_URN__c from Opportunity WHERE Id =: testOpportunity.Id LIMIT 1]; 
 
        
        SYSTEM.DEBUG('---'+testOpportunity.Opportunity_URN__c);


       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
          email.subject = 'Create Contact (REF # '+opp.Opportunity_URN__c+')';
          email.fromAddress = 'someaddress@email.com';
          email.toAddresses = new String[] { 'someaddress01@email.com'};


          email.plainTextBody = 'email body';
          Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
          attachment.body = blob.valueOf('my attachment text');
          attachment.fileName = 'textfileone.txt';
          attachment.mimeTypeSubType = 'text/plain';
          email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
         
          OpportunityEmailServiceInbound  testInbound=new OpportunityEmailServiceInbound ();
          testInbound.handleInboundEmail(email, env);

       }
        Test.stopTest();
    }
}