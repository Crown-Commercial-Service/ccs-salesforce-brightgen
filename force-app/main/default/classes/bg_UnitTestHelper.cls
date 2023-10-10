/**************************************************
* bg_UnitTestHelper
*
* Helper classes for unit tests
* 
* Author: Josh Adams
* Created: 07/11/2017
* Changes: 
*          16/02/2018 - Adding method to create Contract/contact/supplier/Account
*          29/04/2021 - DW	BrightGen - added organisationName param to getAccount to accommodate new validation
**************************************************/

@IsTest
public class bg_UnitTestHelper {

    public static Account createSupplierAccount(String name)
    {
        RecordType recType = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Account','Supplier');
        Account a = new Account(
          name = name,                  // Name
          RecordTypeId = recType.Id    // Record Type
        );
        return a; 
    }

    public static Account createOrganisationAccount(String name)
    {
        RecordType recType = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Account','Organisation');
        Account a = new Account(
          name = name,                              // Name
          RecordTypeId = recType.Id,                // Record Type
          Status__c = 'Active',                     // Status
          Sector__c = 'Private'                     // Sector
        );
        return a; 
    }

    public static Case createProcurementCase(String subject, Id account, Id casCategory, Id framework, Id frameworkLot)
    {
        RecordType recType = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Procurement');
        Case c = new Case(
          RecordTypeId = recType.Id,                                         // Record Type
          AccountId = account,                                               // Organisation
          Status = 'In Progress',                                            // Status
          Value__c = 'Below £100k',                                          // Value
          Strategic_Importance_to_Customer__c = 'Needed but not essential',  // Strategic Importance to Customer
          Sourcing_Complexity__c = 'Basic',                                  // Sourcing Complexity
          CCS_Team__c = 'Buildings',                                         // CCS Team
          Framework__c = framework,                                          // Framework Name
          CAS_P_Category__c = casCategory,                                   // CAS Category
          Origin = 'Email',                                                  // Case Origin
          Framework_Lot__c = frameworkLot,                                   // Framework Lot
          Subject = subject,                                                 // Subject
          Description = 'Description',                                       // Description
          Outcome_Letters_Contract_Approval_Reqd__c = 'No',                  // OL&C Approval Required?
          Cabinet_Office_ERG_approval_required__c = 'No',                    // CO ERG Approval Required?
          MOD_RCA_Approval_Required__c = 'No',                               // MOD RCA Approval Required?
          DWP_CCLAB_Approval_Required__c = 'No',                             // DWP CCLAB Approval Required?
          DWP_MCAT_Approval_Required__c = 'No',                              // DWP MCAT Approval Required?
          Priority = 'Green'                                                 // Priority
        );
        return c;
    }

    public static Category__c createCategory(String name, String categoryType)
    {
        return createCategory(name, categoryType, 'CS');
    }

    public static Category__c createCategory(String name, String categoryType, String categoryCode)
    {
        Category__c c = new Category__c(
          Name = name,                                // Category Name
          Category_Code__c = categoryCode,            // Category Code
          CategoryType__c = categoryType              // Category Type
        );
        return c;
    }

    public static Master_Framework__c createFramework(String name, Id subCategory)
    {
        Master_Framework__c f = new Master_Framework__c(
          Name = name,                                // Name
          Long_Name__c = name,                        // Name (long)
          Is_Active__c = true,                        // Is Active?
          CCS_Sub_Category__c = subCategory,          // CCS Sub Category
          RM_Number__c = '123',                       // RM Number
          Status__c = 'Live',                         // Status
          Owning_Organisation__c = 'CCS',             // Owning Organisation
          Start_Date__c = Date.today(),               // Start Date
          Expiry_Date__c = Date.today().addDays(1)    // Original End Date
        );
        return f;
    }

    public static Master_Framework_Lot__c createFrameworkLot(String name, Id framework)
    {
        Master_Framework_Lot__c fl = new Master_Framework_Lot__c(
          Name = name,                                // Name
          Award_Date__c = Date.today(),               // Award Date
          Expiry_Date__c = Date.today().addDays(1),   // Expiry Date
          Master_Framework__c = framework,            // Framework
          Master_Framework_Lot_Number__c = '1',       // Number
          Invoicing__c = 'Monthly',                   // Invoicing Frequency
          Status__c = 'Live'                          // Status
        );
        return fl;
    }

    public static Supplier_Framework_Lot__c createFrameworkLotSupplier(Id frameworkLot, Id supplier)
    {
        Supplier_Framework_Lot__c fls = new Supplier_Framework_Lot__c(
          Name = 'test',                              // Name, required but auto-populates
          Master_Framework_Lot__c = frameworkLot,     // Framework Lot
          Supplier__c = supplier,                     // Supplier
          Supplier_Code__c = '123',                   // Supplier Code
          Status__c = 'Live'                          // Status
        );
        return fls;
    }

    public static CCS_Contract__c createCCSContract(String reference)
    {

        date myDate = date.today();
        CCS_Contract__c contractItem = new CCS_Contract__c();
        contractItem.Contract_Reference__c = reference;
        contractItem.Name = 'Testing Contract';
        contractItem.Contract_Title_long__c = 'Testing Contract';
        contractItem.Customer__c = getAccount('Organisation', reference+'Organisation').id;
        //contractItem.Customer_Contact__c = getContact('Customercontact').id;
        contractItem.Supplier__c = getSupplier('SupplierTest').id;
        //contractItem.Supplier_Contact__C = getContact('ContactSupplier').id;
        contractItem.Procurement_Route__c = 'Low Value';
        contractItem.Status__c = 'Expired';
        contractItem.Contract_Value__c = 1000;
        contractItem.Extension_Details__c = '1000';
        contractItem.Maximum_Contract_Value__c = 1000;
        contractItem.Google_Drive_Folder_Link__c = 'www.bbc.co.uk';
        contractItem.Description__c = 'Description';
        contractItem.Contract_Management_Tier__c = '1';
        contractItem.Date_Recorded__c = myDate;
        contractItem.Start_Date__c = myDate.addMonths(2);
        contractItem.End_Date__c = myDate.addMonths(8);
        contractItem.Decision_By_Date__c = myDate.addMonths(4); //Contract Expiry Decision Date
        contractItem.Date_Contract_Awarded__c  = mydate.addmonths(1); // Contract Execution Date
        contractItem.Contract_Type__c = 'Goods';
        return contractItem;
    }

    public static Account getAccount(String recordTypeDeveloperName)
    {
      Account acc = getAccount(recordTypeDeveloperName, 'Organisation Name');
      return acc;
    }

    public static Account getAccount(String recordTypeDeveloperName, String organisationName)
    {
        Account acc = new Account ();
        acc.Name = organisationName;
        acc.status__c = 'Active';
        acc.Top_Level__c = 'Executive Agency'; // Organisation Type
        acc.Sector__c = 'Central Government';
        acc.RecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Account',recordTypeDeveloperName).id ;
        insert acc;
        return acc;
    }

    public static Account getSupplier(String name)
    {
        Account acc = new Account ();
        acc.Name = name;

        acc.RecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Account','Supplier').id ;
        insert acc;
        return acc;
    }
    public static Contact getContact(String lastName)
    {
        Contact contact = new Contact ();
        contact.LastName = lastName;
        contact.FirstName = 'First Name';
        contact.Email = 'bg@brightgen.com';
        contact.AccountId = getAccount('Organisation').id;
        insert contact;
        return contact;
    }

    public static Case createCase()
    {
        date myDate = date.Today();
        Case caseItem = new Case ();
        caseItem.Status = 'In Progress';
        caseItem.Origin = 'Origin';
        caseItem.Google_Folder__c = 'https://www.brightgen.com/';
        caseItem.Amendment_Type__c = 'Extension';
        caseItem.Subject = 'Subject';
        caseItem.Description = 'Description';
        caseItem.Extended_Date__c = myDate;
        caseItem.Amended_Date__c = myDate.addMonths(3);
        caseItem.CCN_Unique_Reference__c = '';
        caseItem.RecordTypeId = null;
        caseItem.Contract_Title__c = null;
        
        return caseItem;

    }
}