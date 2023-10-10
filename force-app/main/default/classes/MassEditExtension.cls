public with sharing class MassEditExtension {
    public ApexPages.StandardSetController setController{get;set;}    
    
    public MassEditExtension(ApexPages.StandardSetController setCon){
        setController = setCon;
    }
    
    public PageReference save(){
        setController.save();
        return null;
    }
}