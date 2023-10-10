/*****************************************************************************************************************************
Name: HomePageInfoCtrl_UT 

Purpose: Allow custom text to be displayed on a custom lightning component for Home Pages. Allow user to update text stored in Custom Setting Homepage_Custom_Information__c

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      04/11/2020      INITIAL DEVELOPMENT

*******************************************************************************************************************************/
@isTest 
public class HomePageInfoCtrl_UT {
    
    @isTest 
    static void getCustomSetting(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        custSetting.Info_Text_Pt_1__c='1';
        custSetting.Info_Text_Pt_2__c='2';
        custSetting.Info_Text_Pt_3__c='3';
        custSetting.Info_Text_Pt_4__c='4';
        insert custSetting;
                  
        test.startTest();
        
        string savedText = HomePageInfoCtrl.getCurrentData();
        
        test.stopTest();
        
        system.debug('savedText - '+savedText);
        system.assert(savedText=='1234');
    }
    
	@isTest 
    static void updateCustomSetting_11(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        insert custSetting;
                  
        test.startTest();
        
		string newText='Lorem ipsum';
        HomePageInfoCtrl.updateData(newText);
        
        test.stopTest();
        
		string savedText = HomePageInfoCtrl.getCurrentData();
        system.debug('savedText - '+savedText);
        system.assert(savedText=='Lorem ipsum');
    }

	@isTest 
    static void updateCustomSetting_256(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        insert custSetting;
                  
        test.startTest();
        
		string newText='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lo bortis.';
        HomePageInfoCtrl.updateData(newText);
        
        test.stopTest();
        
		string savedText = HomePageInfoCtrl.getCurrentData();
        system.debug('savedText - '+savedText);
        system.assert(savedText=='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lo bortis.');
    }

	@isTest 
    static void updateCustomSetting_511(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        insert custSetting;
                  
        test.startTest();
        
		string newText='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, ne';
        HomePageInfoCtrl.updateData(newText);
        
        test.stopTest();
        
		string savedText = HomePageInfoCtrl.getCurrentData();
        system.debug('savedText - '+savedText);
        system.assert(savedText=='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, ne');
         						     
    }

	@isTest 
    static void updateCustomSetting_766(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        insert custSetting;
                  
        test.startTest();
        
		string newText='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, nec volutpat metus tempor sit amet. Pellentesque at accumsan magna. In et elit quis dolor laoreet aliquet eu vel mauris. Maecenas luctus fermentum consectetur. Quisque viverra tristique lectus et consequat. Aliquam volutpat fringilla pellentesque. Proin ves';
        HomePageInfoCtrl.updateData(newText);
        
        test.stopTest();
        
		string savedText = HomePageInfoCtrl.getCurrentData();
        system.debug('savedText - '+savedText);
        system.assert(savedText=='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, nec volutpat metus tempor sit amet. Pellentesque at accumsan magna. In et elit quis dolor laoreet aliquet eu vel mauris. Maecenas luctus fermentum consectetur. Quisque viverra tristique lectus et consequat. Aliquam volutpat fringilla pellentesque. Proin ves');
    }
	
	@isTest 
    static void updateCustomSetting_1021(){
        
        Homepage_Custom_Information__c custSetting = new Homepage_Custom_Information__c();
        insert custSetting;
                  
        test.startTest();
        
		string newText='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, nec volutpat metus tempor sit amet. Pellentesque at accumsan magna. In et elit quis dolor laoreet aliquet eu vel mauris. Maecenas luctus fermentum consectetur. Quisque viverra tristique lectus et consequat. Aliquam volutpat fringilla pellentesque. Proin vestibulum enim lacus, ac congue risus luctus varius. Nullam imperdiet rhoncus commodo. Morbi pharetra dictum ullamcorper. Sed id sagittis justo. Donec sodales et diam at ultricies. Pellentesque porta odio a ipsum luctus, sed lobortis sem convallis. Phasellu';
        HomePageInfoCtrl.updateData(newText);
        
        test.stopTest();
        
		string savedText = HomePageInfoCtrl.getCurrentData();
        system.debug('savedText - '+savedText);
        system.assert(savedText=='Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam faucibus ornare velit, eget consectetur arcu hendrerit nec. Aliquam scelerisque volutpat congue. Proin ac est cursus, finibus nisl vel, auctor neque. Cras scelerisque nisl eros, vel lobortis ante tempus id. Morbi pharetra vulputate ultricies. In id turpis at neque aliquet vestibulum sed eget turpis. Sed sed tellus vestibulum, porttitor leo at, posuere lectus. Aliquam at elementum dolor. Maecenas eu molestie orci. Aenean dictum risus lectus, nec volutpat metus tempor sit amet. Pellentesque at accumsan magna. In et elit quis dolor laoreet aliquet eu vel mauris. Maecenas luctus fermentum consectetur. Quisque viverra tristique lectus et consequat. Aliquam volutpat fringilla pellentesque. Proin vestibulum enim lacus, ac congue risus luctus varius. Nullam imperdiet rhoncus commodo. Morbi pharetra dictum ullamcorper. Sed id sagittis justo. Donec sodales et diam at ultricies. Pellentesque porta odio a ipsum luctus, sed lobortis sem convallis. Phasell');
    }

}