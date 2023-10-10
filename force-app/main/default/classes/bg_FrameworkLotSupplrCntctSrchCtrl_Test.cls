/*
 * bg_FrameworkLotSupplrCntctSrchCtrl_Test
 * Author: Conor Spark - Feb 2019
 * 
 * This is the test class for the bg_FrameworkLotSupplierContactSearchCtrl controller
 * 
 * */

@isTest
public class bg_FrameworkLotSupplrCntctSrchCtrl_Test 
{
    
    public static bg_FrameworkLotSupplierContactSearchCtrl setupController()
    {
		Master_Framework__c fw = UnitTestDataFactory.createMasterFramework();
        insert fw;

        Master_Framework_Lot__c mfl1 = UnitTestDataFactory.createMasterFrameworkLot(fw.id);
        insert mfl1;
        
        Master_Framework_Lot__c mfl2 = UnitTestDataFactory.createMasterFrameworkLot(fw.id);
        insert mfl2;
        
        Account supplierAcc1 = UnitTestDataFactory.createSupplierAccount('Test Account 1');
        insert supplierAcc1; 
        Account supplierAcc2 = UnitTestDataFactory.createSupplierAccount('Test Account 2');
        insert supplierAcc2; 
        
        
        Contact c1 = UnitTestDataFactory.createContact(supplierAcc1.Id);
        insert c1; 
        Contact c2 = UnitTestDataFactory.createContact(supplierAcc2.Id);
        insert c2;
        
        Supplier_Framework_Lot__c sfl1 = UnitTestDataFactory.createSupplierFrameworkLot(mfl1.Id, supplierAcc1.Id);
        insert sfl1;
        
        Supplier_Framework_Lot__c sfl2 = UnitTestDataFactory.createSupplierFrameworkLot(mfl2.Id, supplierAcc2.Id);
        insert sfl2;
        
        bg_FrameworkLotSupplierContactSearchCtrl controller = new bg_FrameworkLotSupplierContactSearchCtrl();
        controller.frameworkId = fw.Id;
        return controller;
    
    }
    
    @isTest
    public static void testGetValidAccountIDs()
    {
        bg_FrameworkLotSupplierContactSearchCtrl ctrl = setupController();
        ctrl.getValidAccountIDs();
        
        System.assertEquals(2, ctrl.validAccountIDs.size());
    }
    
    @isTest
    public static void testSearchContacts()
    {
        bg_FrameworkLotSupplierContactSearchCtrl ctrl = setupController();
        
		ctrl.searchName = 'Test Account';        
        ctrl.searchCon();
        System.assertEquals(2, ctrl.contactWrapperList.size());
        
        ctrl.searchName = 'Test Account 1';        
        ctrl.searchCon();
        System.assertEquals(1, ctrl.contactWrapperList.size());
        
    
    }
    
    @isTest
    public static void testChooseContact()
    {
        bg_FrameworkLotSupplierContactSearchCtrl ctrl = setupController();
        ctrl.searchName = 'Test Account'; 
        ctrl.searchCon();
        
        ctrl.con.Id = ctrl.contactWrapperList.get(0).contactRecord.Id;                
        
		ctrl.chooseContact();
        
        System.assertEquals(true, ctrl.contactWrapperList.get(0).checked);
        
    
    }
    
    @isTest
    public static void testNavigation()
    {
        bg_FrameworkLotSupplierContactSearchCtrl ctrl = setupController();
        ctrl.searchName = 'Test Account'; 
        
        ctrl.FirstPage();
        System.assertEquals(0, ctrl.OffsetSize);
        
        ctrl.OffsetSize = 11;
        Integer offsetBefore = ctrl.OffsetSize;
        ctrl.previous();
        System.assertEquals(offsetBefore - ctrl.LimitSize, ctrl.OffsetSize);
        
        offsetBefore = ctrl.OffsetSize;
        ctrl.next();
        System.assertEquals(offsetBefore + ctrl.LimitSize, ctrl.OffsetSize);
        
        offsetBefore = ctrl.totalrecs - math.mod(ctrl.totalRecs,ctrl.LimitSize);
        ctrl.LastPage();
        System.assertEquals(offsetBefore, ctrl.OffsetSize);
        
        ctrl.OffsetSize = 0; 
        System.assertEquals(true, ctrl.getprev());
        
        ctrl.OffsetSize = 1; 
        System.assertEquals(false, ctrl.getprev());
        
        ctrl.searchCon();
        System.assertEquals(true, ctrl.getnxt());
        
        
        
    }

}