/*

* CreatedDate: 14/09/2021 
* Description: Class to acheieve Email Threading on Opportunity Object
*/
@TestVisible
global class OpportunityEmailServiceInbound implements Messaging.InboundEmailHandler {
    
    @TestVisible
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        String sub= email.subject;
        System.debug('sub---- '+ sub);

        if (sub.contains('REF #')){
            string [] ref = sub.split('REF # ');
            string oppUrn = ref[1].substringBefore(')').trim();
            system.debug('oppUrn>>>Final ID>>>> '+oppUrn);    
            Opportunity opp = [Select id from Opportunity where Opportunity_URN__c = :oppUrn]; 
            Id recordId = Id.valueOf(opp.Id);
            
            If (recordId.getSObjectType().getDescribe().getName() == 'Opportunity'){
                //Add Inbound Email Message for contact
                EmailMessage emlMessage = new EmailMessage();
                emlMessage.ToAddress =  String.join(email.toAddresses, ',');
                emlMessage.FromAddress = email.FromAddress;
                emlMessage.FromName = email.FromName;
                emlMessage.Subject = email.subject;
                emlMessage.status = '2';
                emlMessage.HtmlBody = email.htmlBody;
                System.debug('htmlBody:>>>> ' + email.htmlBody );
                emlMessage.Incoming= True;
                emlMessage.TextBody = email.plainTextBody;
                System.debug('TextBody:>>>>> ' + email.plainTextBody);
                emlMessage.RelatedToId = recordId;
                insert emlMessage;
                System.debug('Reply Email: ' + emlMessage ); 
                
                // Add Email Message Relation for id of the sender
                EmailMessageRelation emr = new EmailMessageRelation();
                emr.EmailMessageId = emlMessage.id;
                emr.RelationAddress = email.FromAddress;
                emr.RelationType = 'FromAddress';
                insert emr; 
                system.debug('>>>>>=='+ emr );
            }
        }
        return result;
        
    }
}