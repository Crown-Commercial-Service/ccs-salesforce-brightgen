/** **************************************************************************************************************************
 * bg_DeleteSupplierContactsControllerTest.cls
 * @author Ibraaheem Fazal - BrightGen Ltd 
 * Date 13/10/17
 *****************************************************************************************************************************/

@isTest
private class bg_DeleteSupplierContactsControllerTest {

	 @testSetup static void setup() {

	 	Account acc1 = new Account();
	 	acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
	 	acc1.name = 'test';
	 	insert acc1;

	 	Contact con1 = new Contact();
	 	con1.FirstName = 'Test';
	 	con1.LastName = 'Test';	
	 	con1.Accountid = acc1.id;
	 	con1.Email = 'Test@Test.com';
	 	insert con1;

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
	 	fl2.name = 'test';
	 	fl2.Master_Framework__c = framework.id;
	 	fl2.Master_Framework_Lot_Number__c = '00000000';
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

	 	Master_Framework_Lot_Contact__c flc1 = new Master_Framework_Lot_Contact__c();
	 	flc1.Master_Framework_Lot__c = fl1.id;
	 	flc1.Supplier_Contact__c = con1.id;
	 	insert flc1;

	 	Master_Framework_Lot_Contact__c flc2 = new Master_Framework_Lot_Contact__c();
	 	flc2.Master_Framework_Lot__c = fl2.id;
	 	flc2.Supplier_Contact__c = con1.id;
	 	insert flc2;

	 }
	
	@isTest static void removeContacts() {

		PageReference pageRef = Page.bg_DeleteFrameworkLotSupplierContacts;
        Test.setCurrentPage(pageRef);

        Master_Framework__c acc = [Select id from Master_Framework__c where name = 'test' limit 1];

        ApexPages.currentPage().getParameters().put('FrameworkID', acc.id);
      
        bg_DeleteSupplierContactsController controller = new bg_DeleteSupplierContactsController();
       
        controller.remove();

        for(ApexPages.Message msg :  ApexPages.getMessages()) {
        system.assertEquals('Please select a Supplier Contact', msg.getSummary());

    	}

    	Contact cont1 = [select id, name from Contact where FirstName = 'test'];

        controller.frameworkContact.Supplier_Contact__c = cont1.id;

        controller.find();

        controller.remove();

        controller.getdecision().set(0, true);

        controller.remove();

        system.assertEquals(controller.frameworkLotContactList.Size(), 1);



	}
	
	public static testMethod void findContacts () {

		PageReference pageRef = Page.bg_DeleteFrameworkLotSupplierContacts;
        Test.setCurrentPage(pageRef);

        Master_Framework__c acc = [Select id from Master_Framework__c where name = 'test' limit 1];

        ApexPages.currentPage().getParameters().put('FrameworkID', acc.id);
      
        bg_DeleteSupplierContactsController controller = new bg_DeleteSupplierContactsController();

        controller.find();

        List<ApexPages.Message> msgList = ApexPages.getMessages();

        for(ApexPages.Message msg :  ApexPages.getMessages()) {
        system.assertEquals('Please select a Supplier Contact', msg.getSummary());

    	}

        Contact cont1 = [select id, name from Contact where FirstName = 'test'];

        controller.frameworkContact.Supplier_Contact__c = cont1.id;

        controller.find();

        system.assertEquals(2, controller.frameworkLotContactList.Size());


		}
    
    @isTest
    public static void testGetters()
    {
        PageReference pageRef = Page.bg_DeleteFrameworkLotSupplierContacts;
        Test.setCurrentPage(pageRef);
        
        Master_Framework__c framework = [Select id from Master_Framework__c where name = 'test' limit 1];

        ApexPages.currentPage().getParameters().put('FrameworkID', framework.id);
      
        bg_DeleteSupplierContactsController controller = new bg_DeleteSupplierContactsController();
        
        System.assertEquals(framework.Id, controller.getFrameworkId());
        
        System.assertEquals(controller.searchRes, controller.getSearchResult());

        System.assertEquals(controller.frameworkLotContactList, controller.getframeworkLotContactList());

        System.assertEquals(controller.frameworkContact, controller.getframeworkContact());            
    }
	
}