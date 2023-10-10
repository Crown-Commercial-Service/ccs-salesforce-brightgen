/*****************************************************************************************************************************
Name: OppTeamMbrTrgUT 

Purpose: Opportunity Team Member Trigger

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      09/10/2020      INITIAL DEVELOPMENT - US0948 Enforce correct setup of Opp Team

*******************************************************************************************************************************/

trigger OppTeamMbrTrg on OpportunityTeamMember (before insert, before update) {

    //US0948 
    if(trigger.isbefore && (trigger.isInsert || trigger.isUpdate) ){
        
        set<id> oppIds = new set<id>();
        set<id> mbrIds = new set<id>();//null on insert
        map<OpportunityTeamMember,id> teamMapToOpp = new map<OpportunityTeamMember,id>();
        set<string> mbrType = new set<string>();
        map<id,OpportunityTeamMember> oppManagers = new map<id,OpportunityTeamMember>();
        for(OpportunityTeamMember mbr : trigger.new){
            oppIds.add(mbr.OpportunityId);
            teamMapToOpp.put(mbr, mbr.OpportunityId);
            system.debug('mbrType - '+mbrType);
            if(mbrType.contains(mbr.OpportunityId+mbr.TeamMemberRole)){
                if(mbr.TeamMemberRole== 'Category Opportunity Owner' || mbr.TeamMemberRole== 'CxD Opportunity Owner'){
                    mbr.addError('Only one opportunity owner from CxD and Category is permissable.');
                    system.debug('duplicated role');
                }
                /*else if(mbr.TeamMemberRole=='Category Additional Support' || mbr.TeamMemberRole=='CxD Additional Support'){
                    mbr.addError('This support role has been assigned.');
                    system.debug('duplicated role');
                }*/
                
            }
            if(mbr.TeamMemberRole== 'Category Opportunity Owner' || mbr.TeamMemberRole== 'CxD Opportunity Owner'){
                if(oppManagers.containsKey(mbr.OpportunityId)){
                    OpportunityTeamMember mbr2 = oppManagers.get(mbr.OpportunityId);
                    if(mbr.Opportunity_Owner_Id__c!= string.valueOf(mbr.UserId).left(15) && mbr2.Opportunity_Owner_Id__c!= string.valueOf(mbr2.UserId).left(15)){
                        mbr.addError('Please ensure the opportunity owner is assigned as the CxD or Category Opportunity owner.');
                        system.debug('User Id - '+userInfo.getUserId());
                        system.debug('OppOwner|MbrUser|MbrUser2 - '+mbr.Opportunity_Owner_Id__c+'|'+mbr.UserId+'|'+mbr2.UserId);
                        system.debug('mbr - '+mbr);
                        system.debug('mbr2 - '+mbr2);
                    }
                }
                else{
                    oppManagers.put(mbr.OpportunityId,mbr);
                }
            }
            if(trigger.isUpdate){
                mbrIds.add(mbr.id);
            }
            mbrType.add(mbr.OpportunityId+mbr.TeamMemberRole);
            
        }
        
        Map<id,Opportunity> oppMap = new Map<id,Opportunity>([SELECT id, (SELECT id, TeamMemberRole, UserId, Opportunity_Owner_Id__c FROM OpportunityTeamMembers WHERE id NOT IN: mbrIds) 
                                        FROM Opportunity WHERE id IN: oppIds]);
        system.debug('oppMap - ' +oppMap);
        system.debug('mbrIds - ' +mbrIds);
                       
        for(OpportunityTeamMember mbr : trigger.new){
            Opportunity opp = oppMap.get(mbr.OpportunityId);
            system.debug('mbr - ' +mbr);
            system.debug('opp - ' +opp);
            system.debug('opp.OpportunityTeamMembers -'+opp.OpportunityTeamMembers);
            if(opp.OpportunityTeamMembers.size()>0){
                for(OpportunityTeamMember existinMbr : opp.OpportunityTeamMembers){
                    system.debug('existinMbr - '+existinMbr);
                    if(mbr.TeamMemberRole == existinMbr.TeamMemberRole){
                        if(mbr.TeamMemberRole== 'Category Opportunity Owner' || mbr.TeamMemberRole== 'CxD Opportunity Owner'){
                            mbr.addError('Only one opportunity owner from CxD and Category is permissable.');
                            system.debug('duplicated role');
                            break;
                        }
                        /*else if(mbr.TeamMemberRole=='Category Additional Support' || mbr.TeamMemberRole=='CxD Additional Support'){
                            mbr.addError('This support role has been assigned.');
                            system.debug('duplicated role');
                            break;
                        }*/
                    }
                    if((mbr.TeamMemberRole== 'Category Opportunity Owner' || mbr.TeamMemberRole== 'CxD Opportunity Owner')
                        && (existinMbr.TeamMemberRole== 'Category Opportunity Owner' || existinMbr.TeamMemberRole== 'CxD Opportunity Owner') ){
                        if(mbr.Opportunity_Owner_Id__c!= string.valueOf(mbr.UserId).left(15) && existinMbr.Opportunity_Owner_Id__c!= string.valueOf(existinMbr.UserId).left(15)){
                            mbr.addError('Please ensure the opportunity owner is assigned as the CxD or Category Opportunity owner.');
                            break;
                        }
                    }
                    else
                    system.debug('not duplicated role');
                }
            }
        }
        
    }

}