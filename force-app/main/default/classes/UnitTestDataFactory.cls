/*****************************************************************************************************************************
Name: UnitTestDataFactory 

Purpose: Data factory for unit tests

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      11/03/2016      INITIAL DEVELOPMENT
1.1 -   Cezary Zeleznicki               23/11/2016      Test contract finder custom setting
1.2 -   Cezary Zeleznicki               03/01/2017      Added Procurement_Cat_Code__c
1.3 -   Nic Flook                       31/01/2017      Added support for Framework_Forecast__c & CCC Framework User profile
1.4 -   Nic Flook                       09/02/2017      Amended createOrgContactPortalUser() to avoid dupes
1.5 -   Danny Evans                     03/10/2018      Added Customer__r.Parent_Group__c to Contract SOQL
1.6 -   Emeric Gabor                    09/10/2020      Added Opportunity and Opportunity Team
*******************************************************************************************************************************/
@isTest
public class UnitTestDataFactory {

    public static Id ACCOUNT_ORG_RT_ID =  mRecordTypes.get('Account' ).get('Organisation'); //Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();
    public static Id ACCOUNT_SUP_RT_ID = mRecordTypes.get('Account' ).get('Supplier'); //Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();
    public static Id CASE_PROC_RT_ID =  mRecordTypes.get('Case' ).get('Procurement'); //Schema.SObjectType.Case.getRecordTypeInfosByName().get('Procurement').getRecordTypeId();
    public static final String PROFILE_CCS_PROCURMENT_CONTRACT = 'CCS Procurement and Contract User';
    public static final String PROFILE_CCS_FRAMEWORK_USER = 'CCS Framework User';
    public static final String PROFILE_CCS_SYSTEM_ADMIN = 'CCS System Administrator';
    public static final String USER_LOCAL = 'en_US';


    public static Map <String, Map <String, Id>> mRecordTypes {
        get {
            if (mRecordTypes == null){
                mRecordTypes = new Map <String, Map <String, Id>>();
                List <String> liObjests = new List <String> {'Account', 'Case'};
                for (RecordType rt : [select Id, SobjectType, DeveloperName from RecordType where SobjectType in :liObjests]){
                    if (!mRecordTypes.containsKey(rt.SobjectType)){
                        mRecordTypes.put(rt.SobjectType, new Map <String, Id> ());
                    }
                    mRecordTypes.get(rt.SobjectType).put(rt.DeveloperName, rt.Id);
                }
            }
            return mRecordTypes;
        }
        set;
    }
    public static Account createOrganisationAccount(String accountName){
        Account org = new Account(RecordTypeId = ACCOUNT_ORG_RT_ID);
        org.Name = String.isNotBlank(accountName) ? accountName : 'Customer-' + getRandomString(8);
        org.Status__c = 'Active';
        org.Sector__c = 'Health';
        return org;
    }

    public static Account createSupplierAccount(String accountName){
        Account org = new Account(RecordTypeId = ACCOUNT_SUP_RT_ID);
        org.Name = String.isNotBlank(accountName) ? accountName : 'Supplier-' + getRandomString(8);
        org.Status__c = 'Active';
        org.Sector__c = 'Health';
        org.DUNS_Number__c = Integer.valueOf(Math.random() * 1000000000);
        org.BillingStreet = 'Kingsway';
        org.BillingPostalCode = 'WC1V 7RN';
        org.BillingCity = 'London';
        org.BillingCountry = 'England';

        return org;
    }

    public static Case createProcurementCase(Id accountId){
        Case c = new Case(RecordTypeId = mRecordTypes.get('Case').get('Procurement_Call_Off_Competition'));
        c.AccountId = accountId;
        c.Origin = 'Phone';
        c.Status = 'In Progress';
        c.Priority = 'Green';
        c.Subject = 'Test Case';
        c.Description = 'test case description';
        c.Procurement_Route1__c = '';
        return c;
    }

    public static List<Ops_Workflow_Stages__c> createOpsWorkflowStages(){
        List<Ops_Workflow_Stages__c> opwsList = new List<Ops_Workflow_Stages__c>();
        // stage duration comes from Ops_Workflow_Templates__c so i'm not setting it
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S01', Stage_Name__c = 'Early Engagement'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S02', Stage_Name__c = 'ITT - Development'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S03', Stage_Name__c = 'Pre-Tender Approval'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S04', Stage_Name__c = 'ITT - Live'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S05', Stage_Name__c = 'Evaluation'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S06', Stage_Name__c = 'Award Recommendation'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S07', Stage_Name__c = 'Evaluation 2'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S08', Stage_Name__c = 'Award Recommendation 2'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S09', Stage_Name__c = 'Contract Approval'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S10', Stage_Name__c = 'Contract Award'));
        opwsList.add(new Ops_Workflow_Stages__c(Name = 'S11', Stage_Name__c = 'Closing Actions'));
        return opwsList;
    }

    public static List<Ops_Workflow_Templates__c> createOpsWorkflowTemplates(){
        List<Ops_Workflow_Templates__c> opwtList = new List<Ops_Workflow_Templates__c>();
        // stage duration comes from Ops_Workflow_Templates__c so i'm not setting it
        String callOffRecTypeName = 'Procurement_Call_Off_Competition';
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S01', Name = 'T1', Seq__c = 1, Template_Name__c = 'Call Off', Stage_Duration__c = 2, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S02', Name = 'T2', Seq__c = 2, Template_Name__c = 'Call Off', Stage_Duration__c = 3, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S03', Name = 'T3', Seq__c = 3, Template_Name__c = 'Call Off', Stage_Duration__c = 2, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S04', Name = 'T4', Seq__c = 4, Template_Name__c = 'Call Off', Stage_Duration__c = 3, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S05', Name = 'T5', Seq__c = 5, Template_Name__c = 'Call Off', Stage_Duration__c = 4, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S06', Name = 'T6', Seq__c = 6, Template_Name__c = 'Call Off', Stage_Duration__c = 4, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S09', Name = 'T7', Seq__c = 7, Template_Name__c = 'Call Off', Stage_Duration__c = 4, Record_Type_Name__c = callOffRecTypeName));
        opwtList.add(new Ops_Workflow_Templates__c(Stage_Id__c = 'S10', Name = 'T8', Seq__c = 8, Template_Name__c = 'Call Off', Stage_Duration__c = 4, Record_Type_Name__c = callOffRecTypeName));
        return opwtList;
    }
    
    public static Contact createContact(Id accountId){
        Contact cnt = createContact();
        cnt.AccountId = accountId;

        return cnt;
    }

    public static Contact createContact(){
        Contact cnt = new Contact();
        cnt.firstname = 'Unit';
        cnt.lastname = 'Test-'+ getRandomString(8);
        cnt.Title = 'MR ';
        cnt.Email = cnt.lastname + '@unitest.com';
        cnt.MailingStreet = 'Kingsway';
        cnt.MailingPostalCode = 'WC1V 7RN';
        cnt.MailingCity = 'London';
        cnt.MailingCountry = 'England';
        cnt.Phone = '0' + getRandomString(9);

        return cnt;
    }

    public static CCS_Contract__c createContract(Id customerId, Id customerContactId, Id suppliertId, Id supplierContactId){
        CCS_Contract__c retVal = createContract();
        retVal.Customer__c = customerId;
        retVal.Customer_Contact__c = customerContactId;
        retVal.Supplier__c = suppliertId;
        retVal.Supplier_Contact__c = supplierContactId;

        return retVal;
    }

    public static CCS_Contract__c createContract(){
        CCS_Contract__c retVal = new CCS_Contract__c();
        String strRef = getRandomString(8);
        retVal.name = 'Contract-' + strRef;
        retVal.Contract_Reference__c = strRef;
        retVal.Start_Date__c = Date.today().addDays(24);
        retVal.End_Date__c = Date.today().addYears(1);
        retVal.Contract_Value__c = Integer.valueOf(Math.random() * 1000000);
        retVal.Status__c = 'Pending';
        retVal.Procurement_Reference__c = 'Unit Test of Code';

        return retVal;
    }

    public static Contract_Finder_Integration__c createCSContractFinder(){
        Contract_Finder_Integration__c cfi = Contract_Finder_Integration__c.getOrgDefaults();
        cfi.Credential__c = 'ThisIsUnitTest';
        cfi.URL__c = 'https://thewitcher.com';
        cfi.Test_Credentials__c = 'ThisIsUnitTest';
        cfi.Test_URL__c = 'https://thewitcher.com';

        return cfi;
    }

    public static Category__c createCategory(){
        return createCategory(getRandomString(8), 'Code', 'CPV');
    }
    public static Category__c createCategory(String catName, String catType, String codeType){
        Category__c retVal = new Category__c();
        retVal.name = catName;
        retVal.CategoryType__c = catType;
        retVal.Code_Type__c = codeType;

        return retVal;
    }
    public static Level_4_Categorisation_Code_for_Contract__c createCatContract (Id catId,
        Id contractId){
        Level_4_Categorisation_Code_for_Contract__c retVal =
            new Level_4_Categorisation_Code_for_Contract__c();
        retVal.Code__c = catId;
        retVal.CCS_Contract__c = contractId;

        return retVal;
    }

    public static Procurement_Cat_Code__c createProcurementCatCode(Id caseId, Id categoryId) {
        Procurement_Cat_Code__c pcc = new Procurement_Cat_Code__c();
        pcc.Code__c = categoryId;
        pcc.Procurement__c = caseId;
        return pcc;
    }

    public static EmailMessage createEmailMessage (Id parentId, Boolean incommingEmail){
        EmailMessage retVal = new EmailMessage();
        retVal.FromAddress = 'test@abc.org';
        retVal.Incoming = incommingEmail;
        retVal.ToAddress = 'test@def.test';
        retVal.Subject = 'unit test';
        retVal.TextBody = 'Some text of email for this unit test';
        retVal.ParentId = parentId;

        return retVal;
    }

    public static Attachment createAttachment(Id parentId){
        Attachment retVal = new Attachment();
        retVal.Name = 'Unit test attachment';
        retVal.ContentType = 'TXT';
        retVal.Description = 'Unit test';
        retVal.Body = Blob.valueOf('Some base 64 encodeded body');
        retVal.ParentId = parentId;

        return retVal;
    }

    /************************************************************
        Purpose: Method creates creates user
        Parameters: profile name
        Returns: BET_Follow_Request__c record
        Throws: -
    *************************************************************/
    public static User createUserSystemAdmin(String profileName){
        String randNo = getRandomString(8);
        User newUser = new User(alias = '' + randNo,
                                email = 'UnitTestUser@unittest.com',
                                emailencodingkey = 'UTF-8',
                                firstname = 'Test',
                                lastname = 'ChatterAnswersCreateAccountTest',
                                languagelocalekey = USER_LOCAL,
                                localesidkey = USER_LOCAL,
                                profileid = [SELECT Name FROM Profile WHERE Name = :profileName].id,
                                timezonesidkey = 'Europe/London',
                                username = 'UnitTestUser@unittest.com' + randNo);
        return newUser;
    }
    
    /************************************************************
        Purpose: Method creates creates user
        Parameters: profile name
        Returns: BET_Follow_Request__c record
        Throws: -
    *************************************************************/
    public static User createUserFrameworkManager(String profileName){
        String randNo = getRandomString(8);
        User newUser = new User(alias = '' + randNo,
                                email = 'UnitTestUser@unittest.com',
                                emailencodingkey = 'UTF-8',
                                firstname = 'Test',
                                lastname = 'framworkUser',
                                languagelocalekey = USER_LOCAL,
                                localesidkey = USER_LOCAL,
                                profileid = [SELECT Name FROM Profile WHERE Name = :profileName].id,
                                timezonesidkey = 'Europe/London',
                                username = 'UnitTestUser@unittest.com' + randNo);
        return newUser;
    }

        /************************************************************
            Purpose: Method creates creates user with same email and username
            Parameters: profile name
            Returns: BET_Follow_Request__c record
            Throws: -
        *************************************************************/
        public static User createUserMatchingEmailUsername(String profileName){
            String randNo = getRandomString(8);
            User newUser = new User(alias = '' + randNo,
                                    email = 'UnitTestUser@unittest.com',
                                    emailencodingkey = 'UTF-8',
                                    firstname = 'Test',
                                    lastname = 'ChatterAnswersCreateAccountTest',
                                    languagelocalekey = USER_LOCAL,
                                    localesidkey = USER_LOCAL,
                                    profileid = [SELECT Name FROM Profile WHERE Name = :profileName].id,
                                    timezonesidkey = 'Europe/London',
                                    username = 'UnitTestUser@unittest.com');
            return newUser;
        }

        /************************************************************
            Purpose: Method creates user
            Parameters: profile name & role
            Returns: System Admin User with assigned Profile
            Throws: -
        *************************************************************/
            public static User createUserSystemAdmin(String profileName, Id roleId){
            String randNo = getRandomString(8);
            User newUser = new User(alias = '' + randNo,
                                    email = 'UnitTestUser@unittest.com',
                                    emailencodingkey = 'UTF-8',
                                    firstname = 'Test',
                                    lastname = 'SystemAdmin Lastname',
                                    languagelocalekey = USER_LOCAL,
                                    localesidkey = USER_LOCAL,
                                    profileid = [SELECT Name FROM Profile WHERE Name = :profileName].id,
                                    userRoleId = roleId,
                                    timezonesidkey = 'Europe/London',
                                    username = 'UnitTestUser@unittest.com' + randNo);
                                   // isActive = true);

            return newUser;
            }

            /************************************************************
                Purpose: Method creates Portal user
                Parameters: profile name & role
                Returns: System Admin User with assigned Profile
                Throws: -
            *************************************************************/
                public static User createUserPortal(Id contactId, String profileName){
                String randNo = getRandomString(8);
                User newUser = new User(alias = '' + randNo,
                                        username = 'UnitTestUser@unittest.com' + randNo,
                                        firstname = 'Test',
                                        lastname = 'SystemAdmin Lastname',
                                        email = 'UnitTestUser@unittest.com',
                                        emailencodingkey = 'UTF-8',
                                        languagelocalekey = USER_LOCAL,
                                        localesidkey = USER_LOCAL,
                                        timezonesidkey = 'Europe/London',
                                        profileid = [SELECT Name FROM Profile WHERE Name = :profileName].id,
                                        communityNickname = 'mynewusr' + randNo,
                                        phone = '01322 323456',
                                        companyName = 'Salesforce',
                                        contactId = contactId);

                return newUser;
                }

                /************************************************************
                    Purpose: Method creates FULL Portal user, Contact & Account.
                    Parameters: Portal Type & Role, Insert, Company Sector, Org Type
                    Returns: System Admin User with assigned Profile
                    Throws: -
                *************************************************************/
                public static User getPortalUser(String portalType, User userWithRole, Boolean doInsert, String companySector) {

                String randNo = getRandomString(8);
                // Make sure the running user has a role otherwise an exception will be thrown.
                if(userWithRole == null) {
                    if(UserInfo.getUserRoleId() == null) {
                        UserRole r = new UserRole(name = 'TEST ROLE');
                        Database.insert(r);

                        // Create the User with Role
                        userWithRole = new User(
                            alias = '' + randNo, email='userwithrole@roletest1.com', userroleid = r.id,
                            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = UserInfo.getProfileId(),
                            timezonesidkey='America/Los_Angeles', username = 'UnitTestUser@unittest.com' + randNo, companyName = 'Salesforce');
                        } else {
                            userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
                        }
                    }

                    // Create Our Associated Data
                    Account a;
                    Contact c;

                    // Create Our Data with the UserwithRole
                    System.runAs(userWithRole) {
                        a = new Account(name = 'TEST ACCOUNT');
                        // If populated, Set the Company Sector
                        if(companySector != null) {
                            a.Sector__c = companySector;
                        }
                        Database.insert(a);

                        c = new Contact(AccountId = a.id, lastname = 'lastname', firstname = 'firstname', phone = '01322 323456', email = 'userwithrole@roletest1.com');
                        Database.insert(c);
                    }

                    /* Get any profile for the given type.*/
                    Profile p = [select id, usertype from profile where usertype = :portalType limit 1];

                    String testemail = 'puser000@amamama.com';
                    User pu = new User(
                        profileId = p.id, username = testemail, email = testemail,
                        emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                        languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                        alias='cspu', lastname='lastname', contactId = c.id, companyName = 'Salesforce'
                    );

                    if(doInsert) {
                        Database.insert(pu);
                    }

                    return pu;
                }

                /************************************************************
                    Purpose: Method creates FULL Portal user, Contact & Account.
                    Parameters: Portal Type & Role, Insert, Company Sector, Org Type
                    Returns: System Admin User with assigned Profile
                    Throws:
                *************************************************************/
                public static User createOrgContactPortalUser(String portalType, User userWithRole, Boolean doInsert, String companySector, Id companyRecordType) {

                String randNo = getRandomString(8);
                // Make sure the running user has a role otherwise an exception will be thrown.
                if(userWithRole == null) {
                    if(UserInfo.getUserRoleId() == null) {
                        UserRole r = new UserRole(name = 'TEST ROLE');
                        Database.insert(r);

                        // Create the User with Role
                        userWithRole = new User(
                            alias = '' + randNo, email='userwithrole@roletest1.com', userroleid = r.id,
                            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                            localesidkey='en_US', profileid = UserInfo.getProfileId(),
                            timezonesidkey='America/Los_Angeles', username = 'UnitTestUser@unittest.com' + randNo, companyName = 'Salesforce');
                        } else {
                            userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
                        }
                    }

                    // Create Our Associated Data
                    Account a;
                    Contact c;

                    // Create Our Data with the UserwithRole
                    System.runAs(userWithRole) {
                        a = new Account(name = 'TEST ACCOUNT '  + randNo);
                        // Set our Account Type if populated
                        if(companyRecordType != null) {
                            a.RecordTypeId = companyRecordType;
                        }
                        // If populated, Set the Company Sector
                        if(companySector != null) {
                            a.Sector__c = companySector;
                        }
                        Database.insert(a);

                        c = new Contact(AccountId = a.id, lastname = 'lastname', firstname = 'firstname', phone = '0132' + randNo, email = 'userwithrole@'  + randNo + 'roletest1.com');
                        Database.insert(c);
                    }

                    /* Get any profile for the given type.*/
                    Profile p = [select id, usertype from profile where usertype = :portalType limit 1];

                    String randNo1 = getRandomString(8);
                    String testemail = 'puser000@amamama.com'+randNo1;
                    User pu = new User(
                        profileId = p.id, username = testemail+randNo1, email = testemail,
                        emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                        languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                        alias='cspu', lastname='lastname', contactId = c.id, companyName = 'Salesforce'
                    );

                    if(doInsert) {
                        Database.insert(pu);
                    }

                    return pu;
                }

    /************************************************************
        Purpose: Method creates Master framework
        Parameters: profile name
        Returns: BET_Follow_Request__c record
        Throws: -
    *************************************************************/
    public static Master_Framework__c createMasterFramework(){
        Master_Framework__c retVal = new Master_Framework__c();
        retVal.Name = 'UnitTest Master Framework - ' + getRandomString(5);
        retVal.Status__c = 'Live';

        return retVal;
    }

    /************************************************************
        Purpose: Method creates Master framework lot
        Parameters: profile name
        Returns: BET_Follow_Request__c record
        Throws: -
    *************************************************************/
    public static Master_Framework_Lot__c createMasterFrameworkLot(Id masterFrameworkId){
        Master_Framework_Lot__c retVal = new Master_Framework_Lot__c();
        retVal.Name = 'UnitTest Master Framework Lot - ' + getRandomString(5);
        retVal.Status__c = 'Live';
        retVal.Master_Framework__c = masterFrameworkId;

        return retVal;
    }

    /************************************************************
        Purpose: Method creates Supplier Framework Lot
        Parameters: profile name
        Returns: BET_Follow_Request__c record
        Throws: -
    *************************************************************/
    public static Supplier_Framework_Lot__c createSupplierFrameworkLot(Id masterFrameworkLotId,
            Id accountId){
        Supplier_Framework_Lot__c retVal = new Supplier_Framework_Lot__c();
        retVal.Master_Framework_Lot__c = masterFrameworkLotId;
        retVal.Supplier__c = accountId;

        return retVal;
    }

    /************************************************************
        Purpose: get random string
        Parameters: string length
        Returns: random string
        Throws: -
    *************************************************************/
    public static String getRandomString (Integer maxLength){
        String retVal = '' + Integer.valueOf(Math.random() * Math.pow(10,maxLength));

        while (retVal.length() < maxLength){
            retVal = '0' + retVal;
        }

        return retVal;
    }

    /************************************************************
        Purpose: Create random email address
        Parameters: mailBoxName (the bit before the @ sign)
        Returns: random email address
        Throws: -
    *************************************************************/
    public static String getRandomEmailAddress (String mailBoxName){
        String retVal = mailBoxName + '@' + getRandomString(10) + '.' + 'com';

        return retVal;
    }

    /************************************************************
        Purpose: Create random email address (overloaded method)
        Parameters: firstName, lastName
        Returns: random email address
        Throws: -
    *************************************************************/
    public static String getRandomEmailAddress (String firstName, String lastName){
        String retVal = getRandomEmailAddress(firstName + '.' + lastName);

        return retVal;
    }
    
    /************************************************************
        Purpose: Method creates Framework Forecast
        Parameters: FrameworkId, BusinessPlanYear
        Returns: Framework Forecast record
        Throws: -
    *************************************************************/
    public static Framework_Forecast__c createFrameworkForecast(Id frameworkId, String BusinessPlanYear){
        Framework_Forecast__c retVal = new Framework_Forecast__c();
        retVal.Framework__c = frameworkId;
        retVal.Business_Plan_Year__c = businessPlanYear;

        return retVal;
    }


    ////////////////////////////////////// INSTANCE Variables ////////////////////////////////////////////////////////
    public List <Account> liCustomers = new List <Account> ();
    public List <Account> liSuppliers = new List <Account> ();
    public List <Contact> liCustContacts = new List <Contact> ();
    public List <Contact> liSupContacts = new List <Contact> ();
    public List <CCS_Contract__c> liContracts = new List <CCS_Contract__c> ();
    public List <Case> liCases = new List <Case> ();

    ////////////////////////////////////// INSTANCE metohds ////////////////////////////////////////////////////////
    public void initTestDataForContracts(){

        insert UnitTestDataFactory.createOpsWorkflowStages();
        insert UnitTestDataFactory.createOpsWorkflowTemplates();
        
        // set custom setting
        upsert UnitTestDataFactory.createCSContractFinder();

        // crete customer and supplier
        Account cust = UnitTestDataFactory.createOrganisationAccount(null);
        liCustomers.add(cust);
        Account sup = UnitTestDataFactory.createSupplierAccount(null);
        liSuppliers.add(sup);
        insert new List<Account> {cust, sup};

        // create contact fro customer and supplier
        Contact custCnt = UnitTestDataFactory.createContact(cust.id);
        liCustContacts.add(custCnt);
        Contact supCnt = UnitTestDataFactory.createContact(sup.id);
        liSupContacts.add(supCnt);
        insert new List<Contact> {custCnt, supCnt};

        // create contract
        liContracts.add(UnitTestDataFactory.createContract(cust.id, custCnt.id, sup.id, supCnt.id));
        insert liContracts;

        liContracts = [select id, Contract_Reference__c, name, Customer__r.name, Start_Date__c,
            End_Date__c, Contract_Value__c, Contract_Finder_Notice_Id__c,
            Synchronised_With_Contract_Finder__c, Customer_Contact__r.name ,Customer_Contact__r.Email,
            Customer_Contact__r.MailingStreet, Customer_Contact__r.MailingCity,
            Customer_Contact__r.MailingPostalCode, Customer_Contact__r.MailingCountry,
            Customer_Contact__r.Phone, Supplier__r.name, Supplier__r.DUNS_Number__c,
            Supplier__r.BillingStreet, Supplier__r.BillingPostalCode, Supplier__r.BillingCity,
            Supplier__r.BillingCountry,Supplier_Contact__r.name, Supplier__r.SME_Status__c,
            Supplier__r.Voluntary_Sector_Organisation__c, Deadline_Date__c, Is_Suitable_For_SME__c,
            Is_Suitable_for_VCSE__c, Regions__c, Description__c, Extension_Options__c,
            Date_Contract_Awarded__c, OJEU_Procedure_Type__c, Contract_Type__c, Customer__r.Parent_Group__c

                from CCS_Contract__c
                where id in :liContracts
            ];
         liCases.add(createProcurementCase(liSuppliers[0].id));
         insert liCases;
    }

	public static opportunity createOpportunity(id accountId){
        
        if(accountId==null){
            account acc = new account(Name='Test Account');
            insert acc;
            accountId=acc.id;
        }
        
        opportunity opp = new opportunity(	Name='Test Opportunity',
                                         	AccountId=accountId,
                                         	CloseDate=system.Today(),
                                         	StageName='Stage 0 = Need Identified'
                                         	);
        return opp;
		
	}
    
    public static OpportunityTeamMember createOpportunityTeamMbr(id oppId, id userId, string role){
        
        if(oppId==null){
            Opportunity opp = UnitTestDataFactory.createOpportunity(null);
            insert opp;
            oppId=opp.id;
        }
        if(userId==null){
            userId=UserInfo.getUserId();
        }
        if(role==null){
            role='Category Opportunity Owner';
        }
        
        OpportunityTeamMember mbr = new OpportunityTeamMember(	OpportunityId=oppId,
                                                                UserId=userId,
                                                                TeamMemberRole=role
                                                                );
        return mbr;
		
	}

    public static void createInternalCCSAccountToReferTo(){
        String INTERNAL_ACCOUNT_NAME                         = 'Crown Commercial Service';
        
        Account ccsInternalAccount  = new Account();
        ccsInternalAccount.Name     = INTERNAL_ACCOUNT_NAME;
        insert ccsInternalAccount;

        Org_Settings__c orgSettings = new Org_Settings__c();
        orgSettings.Internal_Account_Id__c = ccsInternalAccount.Id;
        insert orgSettings;
    

    
}
}