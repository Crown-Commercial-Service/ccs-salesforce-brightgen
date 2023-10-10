/** **************************************************************************************************************************
* bg_DeleteSupplierContactsController.cls
* @author Ibraaheem Fazal - BrightGen Ltd 
* Date 13/10/17
*****************************************************************************************************************************/

public class bg_DeleteSupplierContactsController {
    
    public Master_Framework_Lot_Contact__c frameworkContact = new Master_Framework_Lot_Contact__c();
    public List<Master_Framework_Lot_Contact__c> frameworkLotContactList = new List<Master_Framework_Lot_Contact__c>();
    public List<boolean> decision;
    public List<integer> itterator;
    public boolean check = false;
    public bg_ContactSearchResultCarrier searchRes{get; set;}
    
    public bg_DeleteSupplierContactsController()
    {
        searchRes = new bg_ContactSearchResultCarrier();
    }
    
    public Master_Framework_Lot_Contact__c getframeworkContact () {
        
        return frameworkContact;
        
    }
    
    public List<Master_Framework_Lot_Contact__c> getframeworkLotContactList () {
        
        return frameworkLotContactList;
        
    }
    
    public List<integer> getitterator () {
        
        return itterator;
        
    }
    
    public List<boolean> getdecision () {
        
        return decision;
        
    }
    
    //Method to find the the framework lots that the contact can be deleted to i.e. lots for where the contcts has already been added too
    
    public pageReference find () {
        if(searchRes.contactRecord!=null)
        {
           frameworkContact.Supplier_Contact__c = searchRes.contactRecord.Id; 
        }
        
        if(frameworkContact.Supplier_Contact__c != null) {
            
            Id frameworkId = ApexPages.currentPage().getParameters().get('FrameworkID');
            decision = new List<boolean>();
            itterator = new List<integer>();
            frameworkLotContactList = [Select id, Master_Framework_Lot__r.Name, Master_Framework_Lot__r.Master_Framework__r.Name from Master_Framework_Lot_Contact__c where Supplier_Contact__c = : frameworkContact.Supplier_Contact__c and Master_Framework_Lot__r.Master_Framework__r.id  =: frameworkId];
            
            if(frameworkLotContactList.size() == 0 && check == false) {
                
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'There are no framework lots this contact can be deleted from');
                ApexPages.addMessage(myMsg);
                
            }
            
            for(integer i=0; i<frameworkLotContactList.size(); i++) {
                
                itterator.add(i);
                decision.add(false);
                
            }
            
        } else {
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Supplier Contact');
            ApexPages.addMessage(myMsg);
            
        }
        check = false;
        return null;
        
    }
    
    //Mehtod to delete the contact to the selected framework lots
    
    public pageReference remove () {
        
        //Check to see if any lots have been selected
        
        if(frameworkContact.Supplier_Contact__c != null) {
            
            boolean check = false;
            
            for(boolean temp : decision) {
                
                if(temp == true) {
                    
                    check = true;
                    break;
                    
                }
                
            }
            
            //If lots have been selected find the contact on the lot and delete
            
            if(check) {
                
                List<Master_Framework_Lot_Contact__c> frameworkLotContactsDelete = new List<Master_Framework_Lot_Contact__c>();
                integer count = 0;
                
                for(boolean temp : decision) {
                    
                    if(temp == true) {
                        
                        Master_Framework_Lot_Contact__c tempContact = frameworkLotContactList.get(count);
                        
                        frameworkLotContactsDelete.add(tempContact);
                        
                    }
                    
                    count++;
                    
                    
                }
                
                try {
                    
                    delete(frameworkLotContactsDelete);
                    
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Framework Lot Supplier Contacts have been deleted Succesfully');
                    ApexPages.addMessage(myMsg);
                    
                    this.check = true;
                    this.find();
                    
                    return null;
                    
                } catch(DmlException e) {
                    
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + e);
                    ApexPages.addMessage(myMsg);
                    
                    return null;
                }
                
                
            } else {
                
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Framework Lot to Delete a supplier contact from');
                ApexPages.addMessage(myMsg);
                
                return null;
                
            }
            
        } else {
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Supplier Contact');
            ApexPages.addMessage(myMsg);
            
            return null;
            
            
        }
        
        return null;
        
    }
    
    public pageReference close () {
        return null;
        
    }
    
    public bg_ContactSearchResultCarrier getSearchResult()
    {
        return searchRes;
    }
    
    public String getFrameworkId()
    {
        return ApexPages.currentPage().getParameters().get('FrameworkID');
    }
    
}