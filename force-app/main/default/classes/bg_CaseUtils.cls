/**************************************************
* bg_CaseUtils
*
* Set the CCN Unique Reference number on cases with Contract Amendment record type, based on the 
* contract reference number on the contract + number of cases under contract.
* 
* Author: Audo Veliz
* Created: 15/02/2018
* Changes: 
* 	2021-04-29	DW	BG 00051250 Adjusting naming convention of contract reference numbers
**************************************************/

public class bg_CaseUtils 
{
	private static final string REPLACE_WITH_CASENUMBER_FLAG = 'REPLACE_WITH_CASENUMBER';

    /*
    Set the CCN Unique Reference number on cases with Contract Amendment record type
    */
    public static void SetReferenceNumber (List<Case> triggerNew)
    {
        Map<id,Integer> mapCountContract = new Map<id,Integer>();
		Map<id,CCS_Contract__c> mapContract = new Map<id,CCS_Contract__c>();
		Set<id> contractIds = new Set<id>();
		Integer count = 0;

		for(Case caseItem: triggerNew)
		{
			if(caseItem.Contract_Title__c != null)
			{
                System.debug('bg_CaseUtils: Contract_Title__c exists?: ' +caseItem.Contract_Title__c );
				contractIds.add(caseItem.Contract_Title__c);
			}
		}

		System.debug('bg_CaseUtils: triggerNew: ' + triggerNew);
		for(CCS_Contract__c contractItem: [Select id, Contract_Reference__c from CCS_Contract__c where id IN :contractIds ])
		{
			mapContract.put(contractItem.id,contractItem);
		}

		for(Case caseItem: [Select id, Contract_Title__c from Case where Contract_Title__c IN :contractIds])
		{
			if(!mapCountContract.containsKey(caseItem.Contract_Title__c))
				{
					mapCountContract.put(caseItem.Contract_Title__c,1);
				}
				else
				{
					count = mapCountContract.get(caseItem.Contract_Title__c) + 1;
					mapCountContract.put(caseItem.Contract_Title__c, count);
				}
		}

		Integer caseCount = 0;
		for(Case item: triggerNew)
		{
			caseCount++;
			System.debug('bg_CaseUtils: item: ' + item.Contract_Title__c);
			if(item.Contract_Title__c != null)
			{
				if(!mapCountContract.containsKey(item.Contract_Title__c))
				{
					count = 1;
                    mapCountContract.put(item.Contract_Title__c,count);
				}
				else
				{
					count = mapCountContract.get(item.Contract_Title__c) + 1;
					mapCountContract.put(item.Contract_Title__c,count);
				}
				System.debug('bg_CaseUtils: CCN_Unique_Reference__c '+ item.CCN_Unique_Reference__c);

				if(item.Contract_Title__c != null && mapContract.get(item.Contract_Title__c).Contract_Reference__c != null && mapContract.get(item.Contract_Title__c).Contract_Reference__c != '')
				{
					item.CCN_Unique_Reference__c = mapContract.get(item.Contract_Title__c).Contract_Reference__c + '-' + count;
				}
				else
				{
					// Set temporary (unique) value in before context to allow save
					// Will be replaced with CaseNumber when this is set in after context
					item.CCN_Unique_Reference__c = REPLACE_WITH_CASENUMBER_FLAG + caseCount + '-' + count;
				}
			}
		}
		
		if(!mapCountContract.isEmpty())
		{
			List<CCS_Contract__c> contractToUpdate = new List<CCS_Contract__c>();
			for(CCS_Contract__c contractItem: [	Select id, Count_Contract_Amendment_Case__c 
												From CCS_Contract__c 
												where id IN :mapCountContract.KeySet()])
			{
				contractItem.Count_Contract_Amendment_Case__c = mapCountContract.get(contractItem.id);
				contractToUpdate.add(contractItem);
			}
			update contractToUpdate;
		}

    }

	/*
     * For the Contract Amendments which did not have 
	 * reference numbers - replace the flag 
	 * (REPLACE_WITH_CASENUMBER_FLAG) with CaseNumber
     */
    public static void ResetReferenceNumberWithCaseNumber (List<Case> triggerNew)
    {
		List<Case> amendmentsToUpdate = new List<Case>();
		for(Case amendment : triggerNew)
		{
			if(amendment.CCN_Unique_Reference__c != null && amendment.CCN_Unique_Reference__c.startsWith(REPLACE_WITH_CASENUMBER_FLAG))
			{
				List<String> ccnUniqueReferenceParts = amendment.CCN_Unique_Reference__c.split('-');
				Case amendmentForUpdate = amendment.clone(true, true, true, true);
				amendmentForUpdate.CCN_Unique_Reference__c = amendment.CaseNumber + '-' + ccnUniqueReferenceParts[1];
				// Need to clone any which have been flagged to allow second DML in after trigger.
				amendmentsToUpdate.add(amendmentForUpdate);
			}
		}
		// Update these cases again to set this new CCN_Unique_Reference__c
		update amendmentsToUpdate;
	}

}