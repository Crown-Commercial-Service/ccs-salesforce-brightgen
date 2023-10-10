/*****************************************************************************************************************************
Name: HomePageInfoCtrl 

Purpose: Allow custom text to be displayed on a custom lightning component for Home Pages. Allow user to update text stored in Custom Setting Homepage_Custom_Information__c

History
-------
VERSION AUTHOR            DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   Emeric Gabor      04/11/2020      INITIAL DEVELOPMENT 

*******************************************************************************************************************************/


public class HomePageInfoCtrl {
    
	@AuraEnabled
    public static string getCurrentData(){
		
		Homepage_Custom_Information__c custSetting = [SELECT id, Info_Text_Pt_1__c, Info_Text_Pt_2__c, Info_Text_Pt_3__c, Info_Text_Pt_4__c
														FROM Homepage_Custom_Information__c LIMIT 1];
		system.debug('Info_Text_Pt_1__c - '+custSetting.Info_Text_Pt_1__c);	
        system.debug('Info_Text_Pt_2__c - '+custSetting.Info_Text_Pt_2__c);	
        system.debug('Info_Text_Pt_3__c - '+custSetting.Info_Text_Pt_3__c);	
        system.debug('Info_Text_Pt_4__c - '+custSetting.Info_Text_Pt_4__c);	
		
        string customText='';
        if(custSetting!= null){
            if(custSetting.Info_Text_Pt_1__c!= null){
                customText+=custSetting.Info_Text_Pt_1__c;
            }
            if(custSetting.Info_Text_Pt_2__c!= null){
                customText+=custSetting.Info_Text_Pt_2__c;
            }
            if(custSetting.Info_Text_Pt_3__c!= null){
                customText+=custSetting.Info_Text_Pt_3__c;
            }
            if(custSetting.Info_Text_Pt_4__c!= null){
                customText+=custSetting.Info_Text_Pt_4__c;
            }
		}
        
        customText=customText.replace('|',' ');
		
		return customText;
    }
	
	@AuraEnabled
    public static boolean updateData(string newText){
        
        system.debug('newText - '+newText);
        system.debug('newText.length() - '+newText.length());
        newText=newText.replace(' ','|');
		
		Homepage_Custom_Information__c custSetting = [SELECT id, Info_Text_Pt_1__c, Info_Text_Pt_2__c, Info_Text_Pt_3__c, Info_Text_Pt_4__c
														FROM Homepage_Custom_Information__c LIMIT 1];
														
		boolean fullTextSaved=true;
        if(newText.length()<256){
			custSetting.Info_Text_Pt_1__c=newText;
			custSetting.Info_Text_Pt_2__c=null;
			custSetting.Info_Text_Pt_3__c=null;
			custSetting.Info_Text_Pt_4__c=null;
            system.debug('1');
		}
		else if(newText.length()<511){
			custSetting.Info_Text_Pt_1__c=newText.left(255);
			custSetting.Info_Text_Pt_2__c=newText.mid(255,255);
			custSetting.Info_Text_Pt_3__c=null;
			custSetting.Info_Text_Pt_4__c=null;
            system.debug('2');
		}
		else if(newText.length()<766){
			custSetting.Info_Text_Pt_1__c=newText.left(255);
			custSetting.Info_Text_Pt_2__c=newText.mid(255,255);
			custSetting.Info_Text_Pt_3__c=newText.mid(510,255);
			custSetting.Info_Text_Pt_4__c=null;
            system.debug('3');
		}
		else if(newText.length()<1021){
			custSetting.Info_Text_Pt_1__c=newText.left(255);
			custSetting.Info_Text_Pt_2__c=newText.mid(255,255);
			custSetting.Info_Text_Pt_3__c=newText.mid(510,255);
			custSetting.Info_Text_Pt_4__c=newText.mid(765,newText.length()-765);
            system.debug('4');
		}
		else if(newText.length()>1020){
			custSetting.Info_Text_Pt_1__c=newText.left(255);
			custSetting.Info_Text_Pt_2__c=newText.mid(255,255);
			custSetting.Info_Text_Pt_3__c=newText.mid(510,255);
			custSetting.Info_Text_Pt_4__c=newText.mid(765,255);
			fullTextSaved=false;
            system.debug('5');
		}
		
		update custSetting;
		return fullTextSaved;
    }

}