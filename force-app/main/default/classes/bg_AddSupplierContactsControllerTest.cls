/** **************************************************************************************************************************
 * bg_AddSupplierContactsControllerTest.cls
 * @author Ibraaheem Fazal - BrightGen Ltd 
 * Date 13/10/17
 *****************************************************************************************************************************/

@isTest
private class bg_AddSupplierContactsControllerTest {
    
     @testSetup static void setup() {
        List<SObject> requiredRecords = new List<SObject>();

        Account acc1 = new Account();
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
        acc1.name = 'test';
        insert acc1;
         
        Account acc2 = new Account();
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
        acc2.name = 'test2';
        insert acc2;

        Contact con1 = new Contact();
        con1.FirstName = 'Test';
        con1.LastName = 'Test'; 
        con1.Accountid = acc1.id;
        con1.Email = 'Test@Test.com';
        insert con1;
        
        Contact con2 = new Contact();
        con2.FirstName = 'Tester';
        con2.LastName = 'Tester';
        con2.AccountId = acc2.Id;
        con2.Email = 'Tester@tester.com';
        insert con2;

        Category__c cat = new Category__c();
        cat.name = 'Test';
        cat.CategoryType__c = 'CCS Sub Category';
        insert cat;

        Master_Framework__c framework = new Master_Framework__c();
        framework.name = 'test';
        framework.Long_Name__c = 'test test';
        framework.CCS_Sub_Category__c = cat.id;
        framework.RM_Number__c = '00000000';
        framework.Status__c = 'live';
        framework.Start_Date__c = Date.Today();
        framework.Expiry_Date__c = Date.Today().addDays(100);
        insert framework;

        Master_Framework_Lot__c fl1 = new Master_Framework_Lot__c();
        fl1.name = 'test';
        fl1.Master_Framework__c = framework.id;
        fl1.Master_Framework_Lot_Number__c = '00000000';
        fl1.Invoicing__c = 'Monthly';
        fl1.Status__c = 'Live';
        fl1.Award_Date__c = Date.Today();
        fl1.Expiry_Date__c = Date.Today().addDays(100);
        insert fl1;
        
        Master_Framework_Lot__c fl2 = new Master_Framework_Lot__c();
        fl2.name = 'test2';
        fl2.Master_Framework__c = framework.id;
        fl2.Master_Framework_Lot_Number__c = '0000001';
        fl2.Invoicing__c = 'Monthly';
        fl2.Status__c = 'Live';
        fl2.Award_Date__c = Date.Today();
        fl2.Expiry_Date__c = Date.Today().addDays(100);
        insert fl2;

        Supplier_Framework_Lot__c supplier = new Supplier_Framework_Lot__c();
        supplier.name = 'Test';
        supplier.Master_Framework_Lot__c = fl1.id;
        supplier.Supplier__c = acc1.id;
        supplier.Supplier_Code__c = 'test';
        insert supplier;
         
        Supplier_Framework_Lot__c supplier2 = new Supplier_Framework_Lot__c();
        supplier2.name = 'Test';
        supplier2.Master_Framework_Lot__c = fl2.id;
        supplier2.Supplier__c = acc1.id;
        supplier2.Supplier_Code__c = 'test';
        insert supplier2;
         
        Supplier_Framework_Lot__c supplier3 = new Supplier_Framework_Lot__c();
        supplier3.name = 'Test';
        supplier3.Master_Framework_Lot__c = fl1.id;
        supplier3.Supplier__c = acc2.id;
        supplier3.Supplier_Code__c = 'test';
        insert supplier3;
         
        Supplier_Framework_Lot__c supplier4 = new Supplier_Framework_Lot__c();
        supplier4.name = 'Test';
        supplier4.Master_Framework_Lot__c = fl2.id;
        supplier4.Supplier__c = acc2.id;
        supplier4.Supplier_Code__c = 'test';
        insert supplier4;
        
        Master_Framework_Lot_Contact__c testWebContact = new Master_Framework_Lot_Contact__c();
        testWebContact.Master_Framework_Lot__c = fl1.Id;
        testWebContact.Supplier_Contact__c = con2.Id;
        testWebContact.Website_Contact__c = true;
        insert testWebContact;
     }

    public static testMethod void addContacts () {
        
        Master_Framework_Lot_Contact__c frameworkLotWithWebContact = [SELECT Master_Framework_Lot__c, Supplier_Contact__c FROM Master_Framework_Lot_Contact__c WHERE Website_Contact__c = true LIMIT 1];
        
        PageReference pageRef = Page.bg_AddFrameworkLotSupplierContacts;
        Test.setCurrentPage(pageRef);

        Master_Framework__c acc = [Select id from Master_Framework__c where name = 'test' limit 1];
        
        ApexPages.currentPage().getParameters().put('FrameworkID', acc.id);
      
        bg_AddSupplierContactsController controller = new bg_AddSupplierContactsController();
       
        controller.save();

        for(ApexPages.Message msg :  ApexPages.getMessages()) {
                    system.assertEquals('Please select a Supplier Contact', msg.getSummary());
    
            }   

            Contact cont1 = [select id, name, AccountId from Contact where FirstName = 'test'];

		controller.searchRes.contactRecord = cont1;
        controller.find();

        for(bg_AddSupplierContactsController.bg_FrameworkLotDecision frameworkLotDecision : controller.frameworkLotDecisions)
        {
            if (frameworkLotDecision.frameworkLot.Id == frameworkLotWithWebContact.Master_Framework_Lot__c)
            {
                frameworkLotDecision.addContact = true;
                frameworkLotDecision.addWebContact = true;
            }
        }

        controller.save();
        
        Master_Framework_Lot_Contact__c lotContact2 = [SELECT Id, Website_Contact__c FROM Master_Framework_Lot_Contact__c 
                                                            WHERE Supplier_Contact__c = :frameworkLotWithWebContact.Supplier_Contact__c
                                                            LIMIT 1
                                                        ];
        // should return true as the 2 contacts are web contacts for the same lot, but from different accounts
        system.assertEquals(true, lotContact2.Website_Contact__c);

    }

    public static testMethod void findContacts () {

        PageReference pageRef = Page.bg_AddFrameworkLotSupplierContacts;
        Test.setCurrentPage(pageRef);

        Master_Framework__c acc = [Select id from Master_Framework__c where name = 'test' limit 1];

        ApexPages.currentPage().getParameters().put('FrameworkID', acc.id);

        bg_AddSupplierContactsController controller = new bg_AddSupplierContactsController();
		
        controller.find();

        List<ApexPages.Message> msgList = ApexPages.getMessages();

        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            system.assertEquals('Please select a Supplier Contact', msg.getSummary());
    
            }

        Contact cont1 = [select id, name, AccountId from Contact where FirstName = 'test'];
		
        controller.searchRes.contactRecord = cont1;
		
        controller.find();       
		
        //Should get 2 lots to add to (not including Nil Return)
        system.assertEquals(2, controller.frameworkLotDecisions.size());


    }

}