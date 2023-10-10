/** **************************************************************************************************************************
 * bg_AddSupplierContactsController.cls
 * @author Ibraaheem Fazal - BrightGen Ltd 
 * Date 13/10/17
 * Changes:
 * 04-12-2017 - Jack Kittridge <jackkittridge@brightgen.com> - Added website contact logic & updated save to unset other website contacts
 * for updated framework lots (if required)
 * 18-12-2017 - Jack Kittridge <jackkittridge@brightgen.com> - Rewrote whole class logic to work off an inner class containing the decisions for each
 * framework lot rather than trying to match up iterator values
 * 28-12-2018 - Conor Spark - Altered the way that we currently untick the other web contacts for the lot, now we only untick other web contacts of 
 * the SAME supplier instead of all of the web contacts for the whole lot
 *****************************************************************************************************************************/

public class bg_AddSupplierContactsController {
    
    public class bg_FrameworkLotDecision
    {
        public Master_Framework_Lot__c frameworkLot { get; private set; } 
        public Boolean addContact { get; set; }
        public Boolean addWebContact { get; set; }
    
        
        public bg_FrameworkLotDecision(Master_Framework_Lot__c frameworkLot, Boolean addCon, Boolean addWebCon) 
        {
            this.frameworkLot = frameworkLot;
            this.addContact = addCon;
            this.addWebContact = addWebCon;
        }
    }
    
    public List<bg_FrameworkLotDecision> frameworkLotDecisions { get; private set; }
    public Master_Framework_Lot_Contact__c frameworkContact;
    public boolean check = false;
    public bg_ContactSearchResultCarrier searchRes{get; set;}

    public bg_AddSupplierContactsController()
    {
        frameworkContact = new Master_Framework_Lot_Contact__c();
        frameworkLotDecisions = new List<bg_FrameworkLotDecision>();

        searchRes = new bg_ContactSearchResultCarrier();
    }

    public Master_Framework_Lot_Contact__c getframeworkContact ()
    {
        return frameworkContact;
    }

    // Method to add the contact to the selected framework lots
    public pageReference save()
    {
        if(frameworkContact.Supplier_Contact__c != null)
        {   
            Set<Master_Framework_Lot_Contact__c> frameworkLotContactsToUpsert = new Set<Master_Framework_Lot_Contact__c>();
            List<Id> frameworkLotWebsiteContactChanged = new List<Id>();
            
            // Start to build the list of Framework Lot Contacts that are to be added
            for (bg_FrameworkLotDecision frameworkLotDecision : frameworkLotDecisions)
            {
                if (frameworkLotDecision.addContact) 
                {
                    // Create a temporary lotContact and set all required fields based off info we already have
                    Master_Framework_Lot_Contact__c tempLotContact = new Master_Framework_Lot_Contact__c();
                    tempLotContact.Supplier_Contact__c = frameworkContact.Supplier_Contact__c;
                    tempLotContact.Master_Framework_Lot__c = frameworkLotDecision.frameworkLot.Id;
                    if (frameworkLotDecision.addWebContact)
                    {
                        tempLotContact.Website_Contact__c = true;
                    }
                    frameworkLotContactsToUpsert.add(tempLotContact);
                }
                
                // If we are adding them as a web contact, we need to make sure the other contacts for this supplier for this framework lot are unchecked as a result
                if (frameworkLotDecision.addWebContact)
                {
                    frameworkLotWebsiteContactChanged.add(frameworkLotDecision.frameworkLot.Id);
                }
            }
            
            if (frameworkLotWebsiteContactChanged.size() > 0)
            {
                // Get a list of all contacts from the same supplier that are related to framework lots that have had their Web Contact changed
                String contactAccId = String.valueOf([SELECT Id, AccountId from Contact where Id = :frameworkContact.Supplier_Contact__c].AccountId).substring(0, 15);
                List<Master_Framework_Lot_Contact__c> lotContactsToUpdate = [SELECT Id, Website_Contact__c, Organisation_ID__c FROM Master_Framework_Lot_Contact__c WHERE Master_Framework_Lot__c IN :frameworkLotWebsiteContactChanged AND Organisation_ID__c = :contactAccId];
                for (Master_Framework_Lot_Contact__c tempLotContact : lotContactsToUpdate)
                {
                    // Make sure they are no longer set as a website contact and add them to the list of contacts to update
                    tempLotContact.Website_Contact__c = false;
                    frameworkLotContactsToUpsert.add(tempLotContact);
                        
                }
            }
            
            if (frameworkLotContactsToUpsert.size() > 0)
            {
                try {
                    // Create a list full of the items in the set and upsert
                    List<Master_Framework_Lot_Contact__c> tempList = new List<Master_Framework_Lot_Contact__c>(frameworkLotContactsToUpsert);
                    upsert tempList;

                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Framework Lot Supplier Contacts have been added Successfully');
                    ApexPages.addMessage(myMsg);

                    this.check = true;
                    // re-run find to make sure the list only has the relevent items in it when the rerender fires
                    this.find();
                } catch(DmlException e) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + e);
                        ApexPages.addMessage(myMsg);
                }
            }
        }
        else
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a Supplier Contact');
            ApexPages.addMessage(myMsg);

            return null;
        }
        return null;

    }

    //Method to find the the framework lots that the contact can be added to i.e. lots for the selected framework and lots that the contact has not already been added too
    public pageReference find()
    {
        String contactAccId ;
        if(searchRes.contactRecord!=null)
        {
           frameworkContact.Supplier_Contact__c = searchRes.contactRecord.Id;
           contactAccId =  searchRes.contactRecord.AccountId;
        }
        if(frameworkContact.Supplier_Contact__c != null)
        {

            Id frameworkId = ApexPages.currentPage().getParameters().get('FrameworkID');
    
            // Find a list of framework lots that this Contact is NOT already a contact for
            List<Master_Framework_Lot__c> frameworkLots = [Select id, Name from Master_Framework_Lot__c where Master_Framework__c = :frameworkId AND Id NOT IN (SELECT Master_Framework_Lot__c FROM Master_Framework_Lot_Contact__c where Supplier_Contact__c = : frameworkContact.Supplier_Contact__c) AND ID IN (SELECT Master_Framework_Lot__c FROM Supplier_Framework_Lot__c WHERE Supplier__c =:contactAccId)];
    
            if(frameworkLots.size() == 0 && check == false)
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'There are no framework lots to add this contact to');
                ApexPages.addMessage(myMsg);
            }
            else
            {
                // Empty what we already know about the framework lots and rebuild so we don't duplicate records in the view
                frameworkLotDecisions.clear();
                for (Master_Framework_Lot__c frameworkLot : frameworkLots) 
                {
                    frameworkLotDecisions.add(new bg_FrameworkLotDecision(frameworkLot, false, false));
                }   
            }
        }
        else
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a Supplier Contact');
            ApexPages.addMessage(myMsg);
        }
        
        check = false;
        return null;
    }

    public pageReference close()
    {
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