/*****************************************************************************************************************************
Name: OpportunityTrg 

Purpose: Opportunity Trigger

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      09/10/2020      INITIAL DEVELOPMENT - US0948 post to chatter reminder to setup opp team
1.1 -   Divya Muvvala	  14/10/2021	  US1087 
1.2 -   Divya Muvvala     12/11/2021	  US1100    

*******************************************************************************************************************************/

trigger OpportunityTrg on Opportunity (after insert, after update) {

    //US1100
    //map of Owner Ids to their matching Owner Record 
    Map<Id,User> ownerMap;
    //set of Opportunity Owner Ids from the inserted / updated records 
    Set<Id> oppOwnerIds = new Set<Id>();
    //will hold the name of the Oppturnity Owner 
    String nameOfOwner;
    
    // loop through all opps
    for(Opportunity opps : trigger.new){ 
        // add the owner id to the set of owner ids
        oppOwnerIds.add(opps.OwnerId); 
        System.debug('Opportunity Id'+opps.OwnerId); 
    } 

    ownerMap = new Map<Id,User>([SELECT Id, Name FROM User WHERE Id IN :oppOwnerIds]);
    
    //US0948
    if(trigger.isAfter && trigger.isInsert){
        //Trigger Handler
        
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        
        handler.OnAfterInsert(Trigger.New);
        
           
        	//chatter post with mention
        	ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        	ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        	ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        	ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
         
        	messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
         
        	mentionSegmentInput.id = UserInfo.getUserId();
        	messageBodyInput.messageSegments.add(mentionSegmentInput);
         
        	textSegmentInput.text = 'Please ensure you assign yourself as the CxD or Category Opportunity owner as applicable in the Team object.';
        	messageBodyInput.messageSegments.add(textSegmentInput);
        	system.debug('** messageBodyInput -'+messageBodyInput);
        	feedItemInput.body = messageBodyInput;
        	feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        
        	//email list
        	Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();
        	OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = 'noreply@crowncommercial.gov.uk' LIMIT 1];
        	system.debug('** Opp handler - '+ handler);
        
        	for(Opportunity opp: trigger.new){
            	//chatter post without mention//ConnectApi.FeedElement fi = ConnectAPI.ChatterFeeds.postFeedElement(null, opp.Id, ConnectApi.FeedElementType.FeedItem, 'Please ensure you assign yourself as the CxD or Category Opportunity owner as applicable in the Team object');
            	system.debug('** opp ID - '+opp.id);
            	feedItemInput.subjectId = opp.id;
            	nameOfOwner = ownerMap.get(opp.OwnerId).Name;
                
                if (!Test.isRunningTest() && (nameOfOwner != 'Data Warehouse')){
                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                }
            
            	//construct email
            	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            	message.toAddresses = new String[] { UserInfo.getUserEmail() };
            	message.subject = Opp.Name+ ' - Automated Reminder';
            	message.plainTextBody = 'Hi '+ UserInfo.getName()+',\n\nPlease ensure you assign yourself as the CxD or Category Opportunity owner as applicable in the Team object.\n\nRegards,\nSystem Administrator' ;
            	if ( owea!=null ) {
                	message.setOrgWideEmailAddressId(owea.id);
            	}
            
            	message.setSaveAsActivity(false);
            	messages.add(message);
        	}
        	//send emails
        	if(messages.size()>0 && (nameOfOwner != 'Data Warehouse')){
            	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }else{
                System.debug('*** Don\'t send email to record owner - Data Warehouse');
            }
    	
    }
    else if(trigger.isAfter && trigger.isUpdate ){
        
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        
        handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        
        Map<id,Opportunity> oppMap = new Map<id,Opportunity>([SELECT id, (SELECT id, TeamMemberRole FROM OpportunityTeamMembers) 
                                        FROM Opportunity WHERE id IN: trigger.newMap.keyset()]);
        system.debug('oppMap - ' +oppMap);

        //email list
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> ();
        OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = 'noreply@crowncommercial.gov.uk' LIMIT 1];
        
        for(Opportunity opp: trigger.new){
            boolean postReminder = false;
            boolean catMgr = false;
            boolean cxdMgr = false;
            boolean addSupp = false;
            nameOfOwner = ownerMap.get(opp.OwnerId).Name;
            system.debug('postReminder1 - ' +postReminder);
            if(opp.StageName!=trigger.oldMap.get(opp.id).StageName){
                list<OpportunityTeamMember> mbrList = oppMap.get(opp.id).OpportunityTeamMembers;
                system.debug('mbrList - ' +mbrList);
                if(mbrList.size()>0){
                    
                    for(OpportunityTeamMember mbr : mbrList){
                        if(mbr.TeamMemberRole=='Category Opportunity Owner'){
                            catMgr=true;
                            system.debug('catMgr - ' +catMgr);
                        }
                        else if(mbr.TeamMemberRole=='CxD Opportunity Owner'){
                            cxdMgr=true;
                            system.debug('cxdMgr - ' +cxdMgr);
                        }
                        else if(mbr.TeamMemberRole=='Category Additional Support' || mbr.TeamMemberRole=='CxD Additional Support'){
                            addSupp=true;
                            system.debug('addSupp - ' +addSupp);
                        }
                    }
                    if(!catMgr || !cxdMgr || !addSupp){
                        postReminder=true;
                        system.debug('postReminder - ' +postReminder);
                    }
                }
                else{
                    postReminder=true;
                    system.debug('postReminder - ' +postReminder);
                }
            }
            system.debug('postReminder - ' +postReminder);
            if(postReminder){
                //chatter post with mention
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                 
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                 
                mentionSegmentInput.id = UserInfo.getUserId();
                messageBodyInput.messageSegments.add(mentionSegmentInput);
                
                string chatterBody='Looks like you are missing team members. Please add to the team: ';
                if(!catMgr)
                    chatterBody+='Category Opportunity Owner, ';
                if(!cxdMgr)
                    chatterBody+='CxD Opportunity Owner, ';
                if(!addSupp)
                    chatterBody+='Category Additional Support or CxD Additional Support, ';
                chatterBody=chatterBody.removeEnd(', ');
                chatterBody+='.';
                textSegmentInput.text = chatterBody;
                messageBodyInput.messageSegments.add(textSegmentInput);
                 
                feedItemInput.body = messageBodyInput;
                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                
                feedItemInput.subjectId = opp.id;
                if (!Test.isRunningTest() && (nameOfOwner != 'Data Warehouse')){
                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
                } 
                
                //construct email
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = new String[] { UserInfo.getUserEmail() };
                message.subject = Opp.Name+' - Automated Reminder';
                message.plainTextBody = 'Hi '+ UserInfo.getName()+',\n\nPlease ensure you assign yourself as the CxD or Category Opportunity Owner as applicable and that you also populate the Team Details accordingly, with the Support Members.\n\nRegards,\nSystem Administrator' ;
                if ( owea !=null) {
                    message.setOrgWideEmailAddressId(owea.Id);
                }
                message.setSaveAsActivity(false);
                messages.add(message);           
            }
        }
        
        //send emails
        if(messages.size()>0 && (nameOfOwner != 'Data Warehouse')){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }       
    }
}