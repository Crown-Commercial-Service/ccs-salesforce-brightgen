/*****************************************************************
 * bg_ProcurementSuppliers_Test
 *
 * Test Classs for bg_ProcurementSuppliers
 * 
 * Author: Josh Adams
 * Created: 06/11/2017
 * Changes: 
 *
******************************************************************/

@IsTest
public class bg_ProcurementSuppliers_Test {

    public static testMethod void testRecreateCaseSuppliers()
    {
        final Integer NUM_OF_FRAMEWORK_LOT_SUPPLIERS = 200; // Framework Lot Suppliers to create

        // Set up data
        insert new Contract_Reference__c(NAME = 'CS' + Date.today().year().format().right(2), Next_Number__c = 1);
        Account acc = bg_UnitTestHelper.createSupplierAccount('Test Supplier');
        insert acc;
        List<Category__c> cats = new List<Category__c>();
        Category__c cat = bg_UnitTestHelper.createCategory('Test Category','CAS Category','CS');
        Category__c subcat = bg_UnitTestHelper.createCategory('Test Sub Category','CCS Sub Category');
        cats.add(cat);
        cats.add(subcat);
        insert cats;
        System.debug(logginglevel.ERROR, '**JA**: Sub Cat ' + subcat);
        Master_Framework__c framework = bg_UnitTestHelper.createFramework('Test Framework', subcat.id);
        insert framework;
        Master_Framework_Lot__c frameworkLot = bg_UnitTestHelper.createFrameworkLot('Test Framwork Lot', framework.Id);
        insert frameworkLot;
        List<Supplier_Framework_Lot__c> frameworkLotSuppliers = new List<Supplier_Framework_Lot__c>();
        for (Integer i = 0; i < NUM_OF_FRAMEWORK_LOT_SUPPLIERS; i++) {
            Supplier_Framework_Lot__c newFLS = bg_UnitTestHelper.createFrameworkLotSupplier(frameworkLot.Id, acc.Id);
            frameworkLotSuppliers.add(newFLS);
        }
        insert frameworkLotSuppliers;

        // Insert case
        bg_ProcurementSuppliers.testContextSuppress = true; // This prevents the batch from running on both insert and test invokation, which casuses timing issues
        Case testCase = bg_UnitTestHelper.createProcurementCase('Test Case', acc.Id, cat.Id, framework.Id, frameworkLot.Id);
        insert testCase;
        bg_ProcurementSuppliers.testContextSuppress = false;

        // Execute recreateCaseSuppliers()
        Test.startTest();
            bg_ProcurementSuppliers.recreateCaseSuppliers(new List<Id>{testcase.Id});
        Test.stopTest();

        // Verify Case Suppliers have been generated
        List<Case_Supplier__c> csResult = [SELECT Id FROM Case_Supplier__c WHERE Procurement__c = :testcase.ID];
        System.assertEquals(NUM_OF_FRAMEWORK_LOT_SUPPLIERS, csResult.size(), 'Number of generated case suppliers does not match number of framework lot suppliers');
    }
}