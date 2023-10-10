/*
 * bg_FrameworkLotSupplierContactSearchCtrl
 * Author: Conor Spark - Feb 2019
 * 
 * This is the controller for the bg_FrameworkLotSupplierContactSearch VF Component
 * 
 * */
public class bg_FrameworkLotSupplierContactSearchCtrl 
{
   
    
    public bg_ContactSearchResultCarrier searchResult {get; set;}
    
    public Contact con{get;set;}
    public String searchName {get;set;}
    public String frameworkId{get;set;}
    public List<Contact> contactList {get;set;}
    public List<ContactWrapper> contactWrapperList {get;set;}
    public List<String> validAccountIDs{get;set;}
    public integer totalRecs = 0;
    public integer OffsetSize = 0;
    public integer LimitSize= 10;
    
    public bg_FrameworkLotSupplierContactSearchCtrl()
    {        
        con = new Contact();
        contactList  = new List<Contact>();
        contactWrapperList = new List<ContactWrapper>();
        validAccountIDs = new List<String>();
        searchResult = new bg_ContactSearchResultCarrier();
        
    }
    
    // Get the Account ID filter that will be used for the search
    public void getValidAccountIDs()
    {
        
        List<Account> validAccounts = [SELECT ID from Account WHERE ID IN (SELECT Supplier__c  FROM Supplier_Framework_Lot__c WHERE Master_Framework_Lot__r.Master_Framework__r.Id =: frameworkId  )];
    	for (Account acc : validAccounts)
        {
            validAccountIDs.add(acc.Id);
        }
    }
    
    public void searchCon()
    {
        totalRecs = 0;
        OffsetSize = 0;
        searchContacts ();
    }
    
    // Query the database for the contacts that meet the requirements
    public void searchContacts()
    {        
		getValidAccountIDs();
        if(contactList != null && !contactList.isEmpty())
        {
            contactList.clear();
            contactWrapperList.clear();
        }
        
        
        if(searchName !=null && searchName !='')
        {
            String strQuery ='SELECT Name,Account.Name, AccountId ,Phone,Email From Contact';
            strQuery += ' WHERE (Name Like \'%' +searchName +'%\' ' + ' OR Account.Name Like \'%' +searchName +'%\') AND Account.Id IN :validAccountIDs ';
            strQuery += ' ORDER BY Name  ASC, CreatedDate DESC LIMIT :LimitSize OFFSET :OffsetSize';
            
            contactList  =Database.query(strQuery);
            totalRecs = contactList.size();
            
            if(contactList.size()> 0)
            {
                for (Contact c : contactList)
                {
					contactWrapperList.add(new ContactWrapper(c));
                }
            }
        }
        else
        {
            
		}
        
    }
    
    // Navigation section
    public void FirstPage()
    {
        OffsetSize = 0;
        searchContacts();
    }
    public void previous()
    {
        OffsetSize = (OffsetSize-LimitSize);
        searchContacts();
    }
    public void next()
    {
        OffsetSize = OffsetSize + LimitSize;
        searchContacts();
    }
    public void LastPage()
    {
        OffsetSize = totalrecs - math.mod(totalRecs,LimitSize);
        searchContacts();
    }
    public boolean getprev()
    {
        
        if(OffsetSize == 0)
        {
            
            return true;
        }
        else 
        {
            
            return false;
        }
    }
    public boolean getnxt()
    {
        if((OffsetSize + LimitSize) > totalRecs)
        {
            
            return true;
        }
        else 
        {
            
            return false;
        } 
    }
    
    // When a search result is clicked on the page, highlight it
    public void chooseContact()
    {
        searchResult.contactRecord = con;
        for (ContactWrapper cw : contactWrapperList)
        {
            if (cw.contactRecord.Id == con.Id)
            {
            	cw.checked = true; 
			}
            else
            {
				cw.checked = false;
            }
        }
    
        
    }
    
    public List<ContactWrapper> getContactWrapperList()
    {
        return contactWrapperList;
    }
    
    // Inner class to hold the contact record and its checked state
    public class ContactWrapper
    {
        public Contact contactRecord{get; set;}
        public Boolean checked{get; set;}
        
        public ContactWrapper(Contact contactRecord)
        {
			this.contactRecord = contactRecord;
            checked = false;
        }
    }
    
 
    

}