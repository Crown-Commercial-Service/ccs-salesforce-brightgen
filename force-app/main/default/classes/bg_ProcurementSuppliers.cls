/*****************************************************************
 * bg_ProcurementSuppliers
 *
 * Recreates Case Suppliers whenever the Framework Lot on a case is updated
 * Invoked by the 'Add Suppliers to Procurement' process builder
 * 
 * Author: Josh Adams
 * Created: 02/11/2017
 * Changes: 
 *
******************************************************************/

global class bg_ProcurementSuppliers implements Database.Batchable<SObject> {

    public List<Case> caseList {get;set;}
    public Map<Id, Id> frameworkLotIdByCaseId {get;set;}
    @TestVisible private static Boolean testContextSuppress = false;

    @InvocableMethod(label='Recreate Case Suppliers' description='Recreates Case Suppliers from the Framework Lot Suppliers')
    global static void recreateCaseSuppliers(List<ID> cases)
    {
        if (testContextSuppress) // Set to true in tests to prevent execution
        {
            return;
        }

        bg_ProcurementSuppliers process = new bg_ProcurementSuppliers();
        process.caseList = [SELECT Id, Framework_Lot__c FROM Case WHERE Id IN :cases];
        // Fetch and delete original Case_Supplier__c records attached to the cases
        // These will be recreated using the Framework_Lot_Supplier__c records hanging off the cases' relatedFramework Lots
        List<Case_Supplier__c> originalCaseSuppliers = [SELECT Id FROM Case_Supplier__c WHERE Procurement__c IN :cases];
        try
        {
            if (originalCaseSuppliers.size() > 0)
            {
                delete originalCaseSuppliers;
            }
        }
        catch (DmlException e)
        {
            for (Case_Supplier__c cs : originalCaseSuppliers)
            {
                cs.addError(Label.Error_Delete_Case_Suppliers);
            }
            return;
        }

        // Get related Framework Lots from Cases
        process.frameworkLotIdByCaseId = new Map<Id, Id>();
        for (Case c : process.caseList)
        {
            process.frameworkLotIdByCaseId.put(c.Id, c.Framework_Lot__c);
        }

        // Flag cases as processing, to prevent user edits while the batch runs
        for (Case c : process.caseList)
        {
            c.Batch_Processing__c = true;
        }
        if (process.caseList.size() > 0)
        {
            update process.caseList;
        }

        // Run batch to create Case Suppliers
        Database.executeBatch(process, 2000);
    }
     
    global bg_ProcurementSuppliers() {
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        List<Id> frameworkLotIds = frameworkLotIdByCaseId.values();
        return Database.getQueryLocator('SELECT Id, Master_Framework_Lot__c, Supplier__c FROM Supplier_Framework_Lot__c WHERE Master_Framework_Lot__c IN :frameworkLotIds');
    }

    global void execute(Database.BatchableContext context, List<Supplier_Framework_Lot__c> scope) {
        List<Supplier_Framework_Lot__c> frameworkLotSuppliers = (List<Supplier_Framework_Lot__c>)scope;
        List<Case_Supplier__c> caseSuppliers = new List<Case_Supplier__c>(); // Case Supplier records to create
        /*
            For every Case, get FL Suppliers where Case.FL == FL Supplier.FL
            For each FL Supplier, create a Case supplier record on the associated case
            Multiple Case Supplier records may be made from a single FL Supplier ie. If more than one Case uses the same Framework Lot
        */

        // Build up map with a list of FLS for each Case
        Map<Id,List<Supplier_Framework_Lot__c>> frameworkLotSuppliersByCaseId = new Map<Id, List<Supplier_Framework_Lot__c>>();
        for (Case c : caseList)
        {
            List<Supplier_Framework_Lot__c> flSuppliersForCase = new List<Supplier_Framework_Lot__c>();
            for (Supplier_Framework_Lot__c flSup : frameworkLotSuppliers)
            {
                if (c.Framework_Lot__c == flSup.Master_Framework_Lot__c)
                {
                    flSuppliersForCase.add(flSup);
                }
            }
            frameworkLotSuppliersByCaseId.put(c.Id, flSuppliersForcase);
        }

        // Go through and create new Case Supplier records
        for (Id caseId : frameworkLotIdByCaseId.keySet())
        {
            for (Supplier_Framework_Lot__c flSupplier : frameworkLotSuppliersByCaseId.get(caseId))
            {
                Case_Supplier__c newCaseSupplier = new Case_Supplier__c();
                newCaseSupplier.Procurement__c = caseID;
                newCaseSupplier.Supplier__c = flSupplier.Supplier__c;
                caseSuppliers.add(newCaseSupplier);
            }
        }

        // Create the new Case Suppliers
        if (caseSuppliers.size() > 0)
        {
            insert caseSuppliers;
        }
    }
    
    global void finish(Database.BatchableContext context) {
        // Flag cases as no longer processing
        for (Case c : caseList)
        {
            c.Batch_Processing__c = false;
        }
        if (caseList.size() > 0)
        {
            update caseList;
        }
    }
}