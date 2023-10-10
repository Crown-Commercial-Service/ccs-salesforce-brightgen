/*****************************************************************************************************************************
Name: OppTeamMbrTrgUT 

Purpose: Test Opportunity Team Meber Trigger

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      09/10/2020      INITIAL DEVELOPMENT

*******************************************************************************************************************************/

@isTest (seeAllData=true)//required as methods being tested post to chatter
public class OppTeamMbrTrgUT {
    
    @isTest static void insertFullTeam(){
        
        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
                      
        test.startTest();
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;   
        
        system.debug('User Id - '+userInfo.getUserId());
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, userInfo.getUserId(), 'Category Opportunity Owner');
        OpportunityTeamMember mbr2 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[0].id, 'CxD Opportunity Owner');
        OpportunityTeamMember mbr3 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[1].id, 'Category Additional Support');
        OpportunityTeamMember mbr4 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[2].id, 'CxD Additional Support');
        list<OpportunityTeamMember> mbrList = new list<OpportunityTeamMember>();
        mbrList.add(mbr);
        mbrList.add(mbr2);
        mbrList.add(mbr3);
        mbrList.add(mbr4);
        insert mbrList;
        
        system.debug('mbr - '+mbr);
        system.debug('mbr2 - '+mbr2);
        system.debug('mbr3 - '+mbr3);
        system.debug('mbr4 - '+mbr4);
        test.stopTest();
    }
    
    @isTest static void insertTooManyOwners(){

        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
        
        test.startTest();
        
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, userInfo.getUserId(), 'Category Opportunity Owner');
        OpportunityTeamMember mbr2 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[0].id, 'Category Opportunity Owner');
        
        //insert together will fail
        try {
            list<OpportunityTeamMember> mbrList = new list<OpportunityTeamMember>();
            mbrList.add(mbr);
            mbrList.add(mbr2);
            insert mbrList;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('Only one opportunity owner from CxD and Category is permissable.'), 'Team Member insert fail - ' + e.getMessage());
        }
        
        //insert separately 
        insert mbr;
        System.assert(mbr.id!=null,'Team Member insert success.');
        
        try {
            insert mbr2;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('Only one opportunity owner from CxD and Category is permissable.'), 'Team Member insert fail - ' + e.getMessage());
        }
        system.debug('mbr - '+mbr);
        system.debug('mbr2 - '+mbr2);
        
        test.stopTest();
    }
    
/*    @isTest static void insertTooManySupport(){

        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
        
        test.startTest();
        
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, userInfo.getUserId(), 'Category Additional Support');
        OpportunityTeamMember mbr2 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[0].id, 'Category Additional Support');
        
        //insert together will fail
        try {
            list<OpportunityTeamMember> mbrList = new list<OpportunityTeamMember>();
            mbrList.add(mbr);
            mbrList.add(mbr2);
            insert mbrList;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('This support role has been assigned.'), 'Team Member insert fail - ' + e.getMessage());
        }
        
        //insert separately 
        insert mbr;
        System.assert(mbr.id!=null,'Team Member insert success.');
        
        try {
            insert mbr2;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('This support role has been assigned.'), 'Team Member insert fail - ' + e.getMessage());
        }
        system.debug('mbr - '+mbr);
        system.debug('mbr2 - '+mbr2);
        
        test.stopTest();
    }
*/    
    @isTest static void insertOwnerIncorrect(){

        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
        
        test.startTest();
        
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[0].id, 'Category Opportunity Owner');
        OpportunityTeamMember mbr2 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[1].id, 'CxD Opportunity Owner');
        
        //insert together will fail
        try {
            list<OpportunityTeamMember> mbrList = new list<OpportunityTeamMember>();
            mbrList.add(mbr);
            mbrList.add(mbr2);
            insert mbrList;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('Please ensure the opportunity owner is assigned as the CxD or Category Opportunity owner.'), 'Team Member insert fail - ' + e.getMessage());
        }
        
        //insert separately 
        insert mbr;
        System.assert(mbr.id!=null,'Team Member insert success.');
        
        try {
            insert mbr2;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('Please ensure the opportunity owner is assigned as the CxD or Category Opportunity owner.'), 'Team Member insert fail - ' + e.getMessage());
        }
        system.debug('mbr - '+mbr);
        system.debug('mbr2 - '+mbr2);
        
        test.stopTest();
    }
    
    @isTest static void updateTooManyOwners(){

        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
        
        test.startTest();
        
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, UserInfo.getUserId(), 'Category Opportunity Owner');
        OpportunityTeamMember mbr2 = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, uList[1].id, 'CxD Opportunity Owner');
        
        //insert together
        list<OpportunityTeamMember> mbrList = new list<OpportunityTeamMember>();
        mbrList.add(mbr);
        mbrList.add(mbr2);
        insert mbrList;
        System.assert(mbr.id!=null,'Team Member insert success.');
        
        //update to duplicate role 
        try {
            mbr2.TeamMemberRole='Category Opportunity Owner';
            update mbr2;
        } 
        catch (Exception e) {
            System.assert(e.getMessage().contains('Only one opportunity owner from CxD and Category is permissable.'), 'Team Member insert fail - ' + e.getMessage());
        }
        system.debug('mbr - '+mbr);
        system.debug('mbr2 - '+mbr2);
        
        test.stopTest();
    }
    


}