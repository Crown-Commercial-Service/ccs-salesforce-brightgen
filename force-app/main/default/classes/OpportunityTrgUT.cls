/*****************************************************************************************************************************
Name: OppTeamMbrTrgUT 

Purpose: Test Opportunity Trigger

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      09/10/2020      INITIAL DEVELOPMENT

*******************************************************************************************************************************/

@isTest (seeAllData=true)//required as methods being tested post to chatter
public class OpportunityTrgUT {
    
    @isTest static void updateOppFullTeam(){
        
        //cannot create test users without mixed DML or testSetup. TestSetup not allowed with seeAllData=true
        list<user> uList =[SELECT id FROM User WHERE profile.Name = 'CCS Framework Management User' AND id <>: UserInfo.getUserId() LIMIT 4];
                 
        test.startTest();
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;   
        
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
        
        opp.StageName='Stage 2 = Support Required';
        opp.Likelihood__c='Likely';
        update opp;
        
        test.stopTest();
    }

    @isTest static void updateOppPartialTeam(){
                  
        test.startTest();
        Opportunity opp = UnitTestDataFactory.createOpportunity(null);
        insert opp;   
        
        OpportunityTeamMember mbr = UnitTestDataFactory.createOpportunityTeamMbr(opp.Id, userInfo.getUserId(), 'Category Opportunity Owner');
        insert mbr;
        
        opp.StageName='Stage 2 = Support Required';
        opp.Likelihood__c='Possibly';
        update opp;
        
        test.stopTest();
    }

}