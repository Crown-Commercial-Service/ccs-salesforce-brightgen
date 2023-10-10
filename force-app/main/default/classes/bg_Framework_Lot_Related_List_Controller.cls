/*********************************************************************
 Name:  bg_Framework_Lot_Related_List_Controller
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
   1.0   Conor Spark      September 2017                        Initial version
   1.1   Conor Spark      October   2017                        Update to include fullscreen
 *********************************************************************/
public class bg_Framework_Lot_Related_List_Controller 
{
    private List<Master_Framework_Lot__c> mfl;
    private Master_Framework__c mf;
    public Boolean canDelete{get; set;}
    public Boolean fullscreen{get; set;}
    public String redirectURL{get; set;}
    public Boolean shouldRedirect {public get; private set;}

    public bg_Framework_Lot_Related_List_Controller(ApexPages.StandardController controller) 
    {
     this.mf=(Master_Framework__c)controller.getRecord();
     shouldRedirect = false;

      if (Master_Framework_Lot__c.sObjectType.getDescribe().isDeletable()) 
        {
            canDelete = true;
        }else
        {
            canDelete = false;
        }
        String fscreen= ApexPages.currentPage().getParameters().get('fullscreen');
        if (fscreen == 'true')  
        {
            fullscreen = true;
        }else
        {
            fullscreen = false;
        }
        
     }
     
     //Retrieves the Framework Lots for the current Framework
     public List<Master_Framework_Lot__c> getFrameworkLots()
     {
         mf = [Select id, Name FROM Master_Framework__c where id =:mf.id];
         if (fullscreen){
             mfl = [Select id, Name, Master_Framework_Lot_Number__c, Nominal_Code__c, Award_Date__c, Final_Call_Off_Date__c, Expiry_Date__c,
             CB_vs_pre_defined_period__c,   CB_vs_previous_year__c, CB_vs_current_comparator__c
              from Master_Framework_Lot__c where Master_Framework__c =:mf.Id and Include_in_Related_List__c = true
              order by Master_Framework_Lot_Number__c];
              return mfl;
         }else{
         
             mfl = [Select id, Name, Master_Framework_Lot_Number__c, Nominal_Code__c, Award_Date__c, Final_Call_Off_Date__c, Expiry_Date__c,
             CB_vs_pre_defined_period__c,   CB_vs_previous_year__c, CB_vs_current_comparator__c
              from Master_Framework_Lot__c where Master_Framework__c =:mf.Id and Include_in_Related_List__c = true
              order by Master_Framework_Lot_Number__c LIMIT 5];
             return mfl;
         }
     }

     //redirects the page to the fullscreen version of the related list
     public PageReference redirectFullscreen()
     {
        shouldRedirect = true;
        redirectURL = '/apex/bg_Framework_Lot_Related_List?id='+mf.id + '&fullscreen=true';
        return null;
         

     }
     
     //redirects to a create new framework lot
     public Pagereference newFrameworkLot()
     {
         
        return new PageReference('/a0b/e?' + System.Label.Master_Framework_ID + '_lkid=' + mf.id + 
            '&' + System.Label.Master_Framework_ID + '='+ mf.Name + ' &retURL=%2F' + mf.id);

     }
        
     //redirects to the edit of the current framework lot
     public Pagereference editFrameworkLot()
     {
         String flid= ApexPages.currentPage().getParameters().get('flid'); 
         
        return new PageReference('/'+flid+'/e?retURL=%2F' + mf.Id );

     }
     
     //deletes current framework lot
      public Pagereference deleteFrameworkLot()
     {
         String flid= ApexPages.currentPage().getParameters().get('flid'); 
         
         Master_Framework_Lot__c mfToDelete = [Select id from Master_Framework_Lot__c where id =:flid limit 1];
         if(mfToDelete !=null && mfToDelete.id !=null){
          delete mfToDelete;
         }
        return null;

     }

     //returns value of current user's ability to delete framework lots
     public Boolean getCanDelete()
     {
       

        return canDelete;
        
     }
}