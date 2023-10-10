/*********************************************************************
 Name:  COW_ContractReferenceUtil
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: class to help generate contract/procurement reference                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-01		 Initial version 	US596
   1.1	Cezary Zeleznicki	2016-10-13		Added Procurement reference 
   											generation			US1332
 *********************************************************************/
public without sharing class COW_ContractReferenceUtil {
	
	/*
	* Contract/Procurement reference format:
	* + 'CC'
	* + category code (Category__c.Category_Code__c) - 2 characters
	* + last two digits of current year
	* + sequential letter (A-Z)
	* + sequential number (01-00) -> 00 goes after 99
	* example: CCTE16F26
	* seq letter increments when seq number passes 00
	* fetch seq letter and seq number from custom settings
	*/
	
	/* EXCEPTION */
	public class GenerateReferenceException extends Exception {}
	
	/* CONSTANTS */
	public static final String CC_PREFIX = 'CC';	// required prefix of reference
	public static final String CAS_CATEGORY_CODE_FIELD = 'CAS_Category_Code__c';
	// map of object types to the names of the fields that hold the refernce
	public static final Map<Schema.SObjectType,String> referenceFields = 
		new Map<Schema.SObjectType,String>
		{
			Schema.Case.getSObjectType() => Case.Procurement_Reference__c.getDescribe().getName(),
			Schema.CCS_Contract__c.getSObjectType() => CCS_Contract__c.Contract_Reference__c.getDescribe().getName()
		};
	// map of object types to the messages to show when category code not provided
	public static final Map<Schema.SObjectType,String> catCodeMissingMsg = 
		new Map<Schema.SObjectType,String>
		{
			Schema.Case.getSObjectType() => Label.COW_NoCategoryCode_Case,
			Schema.CCS_Contract__c.getSObjectType() => Label.COW_NoCategoryCode_Contract
		};
		
	/* METHODS */
	
	// use this method if the field that holds the reference is defined in the "referenceFields" map
	public static String populateRefrence(Id sobjId, String categoryCode)
	{
		String referenceField = referenceFields.get(sobjId.getSObjectType());
		return populateRefrence(sobjId, categoryCode, referenceField);
	}
	
	// pass in a sobject id, category code and a field to populate with the result
	// this will generate a procurement/contract number
	// method also updates both the sobject AND the custom setting to set the next sequence
	public static String populateRefrence(Id sobjId, String categoryCode, String referenceField)
	{
		if(String.isBlank(categoryCode) || categoryCode.length() != 2 || !categoryCode.isAlpha())
		{
			throw new GenerateReferenceException
			(String.isBlank(categoryCode)
			
				? (catCodeMissingMsg.containsKey(sobjId.getSObjectType()) 
					? catCodeMissingMsg.get(sobjId.getSObjectType()) : Label.COW_NoCategoryCode_Generic)
					
				: String.format(Label.COW_CATEGORYCODEINCORRECT, new List<String>{categoryCode})
			);
		}
		categoryCode = categoryCode.toUpperCase();	// just in case
		
		// check if this objects already has reference
		String sobjTypeName = sobjId.getSObjectType().getDescribe().getName();
		Sobject sObj = Database.query('SELECT id, ' + referenceField + ' FROM ' + sobjTypeName + ' WHERE Id = \'' + sobjId + '\'').get(0);
		if(String.isNotBlank((String) sObj.get(referenceField)))
		{
			throw new GenerateReferenceException(String.format(Label.COW_REFERENCEEXISTS, new List<String>{(String) sObj.get(referenceField)}));
		}
		
		final String currentYear = Date.today().year().format().right(2);
		Contract_Reference__c cr;
		{
			List<Contract_Reference__c> crsTemp;
			crsTemp = [select Next_Number__c, Name from Contract_Reference__c where Name = :(categoryCode+currentYear) for update];
			if(crsTemp.isEmpty())
			{
				throw new GenerateReferenceException(String.format(Label.COW_NOSEQUENCECOUNTER, new List<String>{categoryCode}));
			}
			cr = crsTemp.get(0);
		}
		
		// generate ref code and update object
		String refCode = generateReference(categoryCode,currentYear,cr);
		//sObject sObj = sobjId.getSObjectType().newSObject(sobjId);	// create a new object with sobjId corresponding to the correct type
		sObj.put(referenceField,(object) refCode);
		update sObj;
		
		update cr;
		
		return refCode;
	}
	
	/*******************************************************************

	Purpose: Fetches reference field by first record from parameter.

	Parameters: sObject list of records

	********************************************************************/
	public static void populateReference(List<sObject> objects) {
		if(objects.isEmpty()) {
			return;
		}

		String referenceField = referenceFields.get(objects[0].getSObjectType());
		populateReference(objects, referenceField);
	}

	/*******************************************************************

	Purpose: Populates procurement reference number on multiple records 
			ASUMPTION!!!!! Works for single object type at a time - records 
			coming from Trigger.

	Parameters: sObject list of records, referenceField where reference 
				is kept

	********************************************************************/

	public static void populateReference(List<sObject> objects, String referenceField) {
		final String currentYear = Date.today().year().format().right(2);
		Map<String, String> casCategory2CategoryWithYear = new Map<String, String>();
		List<Contract_Reference__c> contractReferences;
		Map<String, Contract_Reference__c> casCategory2ContractReference = new Map<String, Contract_Reference__c>();
		Map<String, Contract_Reference__c> name2ContractReference = new Map<String, Contract_Reference__c>();
		
		for(sObject obj : objects) {
			String categoryCode = (String) obj.get(CAS_CATEGORY_CODE_FIELD);
			casCategory2CategoryWithYear.put(categoryCode, categoryCode + currentYear);
		}
	
		contractReferences = [
			SELECT Next_Number__c, Name 
			FROM Contract_Reference__c 
			WHERE Name IN :casCategory2CategoryWithYear.values()
			FOR UPDATE
		];

		if(contractReferences.isEmpty()) {
			throw new GenerateReferenceException(String.format(Label.COW_NOSEQUENCECOUNTER, 
				new List<String>{casCategory2CategoryWithYear.values()[0].left(2)}));
		}

		for(Contract_Reference__c cr : contractReferences) {
			name2ContractReference.put(cr.Name, cr);
		}

		for(String cc : casCategory2CategoryWithYear.keySet()) {
			casCategory2ContractReference.put(cc, name2ContractReference.get(
				casCategory2CategoryWithYear.get(cc)));
		}
		
		for(sObject obj : objects) {
			String categoryCode = (String) obj.get(CAS_CATEGORY_CODE_FIELD);
			Contract_Reference__c cr = casCategory2ContractReference.get(categoryCode);
			String refCode = generateReference(categoryCode, currentYear, cr);
			obj.put(referenceField, (Object) refCode);
		}
		
		update casCategory2ContractReference.values();
	}

	// pass in category code, last two digits of year, and relevant Contract_Reference__c record
	// return fully formed reference code
	// also increment Next Number and Next Letter on Contract_Reference__c record
	// Next Number is set to 0 when maximum sequence (Z00) is exceeded
	public static String generateReference(String categoryCode, String currentYearYY, Contract_Reference__c cr)
	{
		String ref = CC_PREFIX + categoryCode + currentYearYY;
		
		if(cr.Next_Number__c == 0)
		{
			throw new GenerateReferenceException(String.format(Label.COW_MAXSEQEXCEEDED, new List<String>{categoryCode}));
		}
		
		String numString = cr.Next_Number__c + '';
		Integer seqNum = cr.Next_Number__c < 100 ? cr.Next_Number__c.intValue() : Integer.valueOf(numString.right(2));
		
		// some old school magic <3
		String seqChar = 'A';
		Integer charOffset = cr.Next_Number__c < 100 ? 0 : Integer.valueOf(numString.left(numString.length()-2));
		if(seqNum == 0) charOffset--;	// 00 goes after 99 - i know, it's weird
		List<Integer> char2int = seqChar.getChars();
		char2int.set(0,char2int.get(0)+charOffset);
		seqChar = String.fromCharArray(char2int);
		
		ref += seqChar + (seqNum < 10 ? '0' : '') + seqNum;
		
		// increment counter - if you've reached Z00, put in 0 to flag that range exceeded
		cr.Next_Number__c = (seqNum == 0 && seqChar == 'Z') ? 0 : (cr.Next_Number__c+1);
		
		return ref;
	}
    
}