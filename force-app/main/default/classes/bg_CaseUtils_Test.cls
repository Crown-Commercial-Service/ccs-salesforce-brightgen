/**************************************************
* bg_CaseUtils_Test
*
* Test Class for bg_CaseUtils
* 
* Author: Audo Veliz
* Created: 15/02/2018
* Changes: 
* 	2021-04-29	DW	BG 00051250 Adjusting naming convention of contract reference numbers
                                Adding validateEmptyContractReference test
**************************************************/
@isTest
public class bg_CaseUtils_Test 
{
    @testSetup static void setup()
    {
        CCS_Contract__c contract =  bg_UnitTestHelper.createCCSContract('REF');
        insert contract;
    }
    //Test different scenarios when the reference field is created.
    static testMethod void validateReference()
    {
        // Test the reference field when inserting the first case under the contract
        CCS_Contract__c contract = [Select id from CCS_Contract__c limit 1];
        Case caseItem = bg_UnitTestHelper.createCase();
        caseItem.Contract_Title__c = contract.id;
        Id caseRecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id;
        caseItem.RecordTypeId = caseRecordTypeId;
        insert caseItem;
        Case actualRecord = [select id, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals('REF-1',actualRecord.CCN_Unique_Reference__c);



        // Test the reference field when there are at least one case under the contract
        String expected = 'REF-2';
        caseItem = bg_UnitTestHelper.createCase();
        caseItem.Contract_Title__c = contract.id;
        caseItem.RecordTypeId = caseRecordTypeId;
        insert caseItem;
        actualRecord = [select id, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals(expected,actualRecord.CCN_Unique_Reference__c);



        // Test when the case point to a different contract. Also check if the case was successfully removed from the previous contract
        CCS_Contract__c secondContract =  bg_UnitTestHelper.createCCSContract('REFERENCE');
        expected = 'REFERENCE-1';
        insert secondContract;
        caseItem.Contract_Title__c = secondContract.id;
        update caseItem;
        List<Case> NumCaseContract = [Select id ,Contract_Title__c from Case where Contract_Title__c = :contract.id ];
        actualRecord = [select id, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals(expected,actualRecord.CCN_Unique_Reference__c);
        System.assertEquals(1, NumCaseContract.size());
        
    }

    @isTest
    static void validateReferenceBulk()
    {

        Case caseItem = bg_UnitTestHelper.createCase();
        Id caseRecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id;

        Test.startTest();
        List<Case> listOfCases = new List<Case>();
        CCS_Contract__c bulkContract =  bg_UnitTestHelper.createCCSContract('BULKREFERENCE');
        insert bulkContract;
        List<String> listExpected = new List<String>();

        for(Integer index = 1; index <= 10; index++)
        {
            caseItem = bg_UnitTestHelper.createCase();
            caseItem.Contract_Title__c = bulkContract.id;
            caseItem.RecordTypeId = caseRecordTypeId;
            listOfCases.add(caseItem);
            listExpected.add('BULKREFERENCE-' + index);
        }
        insert listOfCases;

        List<Case> actualList = [select id,CCN_Unique_Reference__c,Contract_Title__c  from Case where Contract_Title__c = :bulkContract.id];
        for(Case actualCase: actualList)
        {
            System.assert(listExpected.contains(actualCase.CCN_Unique_Reference__c));
        }
        Test.stopTest();

        // Test when there is more than one case on the contract
        // Test the reference field when there are at least one case under the contract
        String expected = 'BULKREFERENCE-11';
        caseItem = bg_UnitTestHelper.createCase();
        caseItem.Contract_Title__c = bulkContract.id;
        caseItem.RecordTypeId = caseRecordTypeId;
        insert caseItem;
        Case actualRecord = [select id, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals(expected,actualRecord.CCN_Unique_Reference__c);
    }

    @isTest
    static void validateEmptyContractReference()
    {
        // Create a Contract Ammendment case where the Contract_Title__r.Contract_Reference__c == null
        

        CCS_Contract__c contract1 =  bg_UnitTestHelper.createCCSContract(null);
        insert contract1;
        Id caseRecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id;
        Case caseItem = bg_UnitTestHelper.createCase();
        caseItem.RecordTypeId = caseRecordTypeId;
        caseItem.Contract_Title__c = contract1.id;
       
        Test.startTest();
        insert caseItem;
        Test.stopTest();
     
        List <Case> cases = [Select id, CCN_Unique_Reference__c, CaseNumber from case];
        bg_CaseUtils.ResetReferenceNumberWithCaseNumber(cases);
        
       
         // confirm reference is in format “ContractId-3”
        Case resultRecord = [select id, CaseNumber, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals(resultRecord.CaseNumber+'-1', resultRecord.CCN_Unique_Reference__c, 'Alternative reference format for null contract was not used.');
    }


    @isTest
    static void validateEmptyContractReferenceUpdate()
    {
        // Create a Contract where the Contract_Reference__c != null

        CCS_Contract__c contract1 =  bg_UnitTestHelper.createCCSContract('referenceTest');
        insert contract1;
        Id caseRecordTypeId = bg_RecordTypeUtils.GetRecordTypeByObjectandDeveloperName('Case','Contract_Amendment').Id;
        Case caseItem = bg_UnitTestHelper.createCase();
        caseItem.RecordTypeId = caseRecordTypeId;
        caseItem.Contract_Title__c = contract1.id;
        insert caseItem;
        contract1.Contract_Reference__c = null;

        // Create a Contract where the  Contract_Reference__c == null
        CCS_Contract__c contract2 =  bg_UnitTestHelper.createCCSContract(null);
        insert contract2;

        // Repoint Contract Amendment to contract2
        caseItem.Contract_Title__c = contract2.Id;
        Test.startTest();
        update caseItem;
        Test.stopTest();
        
        List <Case> cases = [Select id, CCN_Unique_Reference__c, CaseNumber from case];
        bg_CaseUtils.ResetReferenceNumberWithCaseNumber(cases);

        // confirm reference is in format “ContractId-3”
        Case resultRecord = [select id, CaseNumber, CCN_Unique_Reference__c from case where id = :caseItem.id ];
        System.assertEquals(resultRecord.CaseNumber+'-1', resultRecord.CCN_Unique_Reference__c, 'Alternative reference format for null contract was not used.');
    }
}