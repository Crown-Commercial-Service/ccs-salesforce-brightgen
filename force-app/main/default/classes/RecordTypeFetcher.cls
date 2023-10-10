/*********************************************************************
 Name:  RecordTypeFetcher
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Utility class to fetch record types														  
 -------															
 ======================================================
 ======================================================
 History															
 -------															
 VERSION  AUTHOR			DATE			DETAIL				Description
	 1.1	Cezary Zeleznicki 	2016-11-04		Initial version
 *********************************************************************/
public class RecordTypeFetcher {

	private static Set<Id> procurementRecordTypeIds;
	private static Map<String, RecordType> devName2RecordType;

	/************************************************************
		Purpose: Fetch Case record type Id by record typ developer 
							name
		Parameters: String recordType developer name
		Returns:  Id of record type
	*************************************************************/
	public static Id fetchCaseRtId(String developerName) {
		if(devName2RecordType != null) {
			return devName2RecordType.get(developerName).Id;
		}

		return fetchCaseRecordTypes().get(developerName).Id;
	}

	/************************************************************
		Purpose: Fetch procurement Case record type Ids
		Returns:  Set of record type Ids
	*************************************************************/
	public static Set<Id> fetchCaseProcurementRtIds() {
		return fetchCaseRecordTypeIdsByDeveloperNames(CaseUtil.PROCUREMENT_RT_DEV_NAMES);
	}

	public static Set<Id> fetchAllCaseProcurementRtIds() {
		Set<String> allProcurementDevNames = new Set<String>(CaseUtil.PROCUREMENT_RT_DEV_NAMES);
		allProcurementDevNames.add(CaseUtil.RECORD_TYPE_PROCUREMENT);
		return fetchCaseRecordTypeIdsByDeveloperNames(allProcurementDevNames);
	}

	public static Set<Id> fetchCaseRecordTypeIdsByDeveloperNames(Set<String> devNames) {
		Set<Id> cIds = new Set<Id>();

		for(RecordType rt : fetchCaseRecordTypes().values()) {
			if(!devNames.contains(rt.DeveloperName)) {
				continue;
			}
			cIds.add(rt.Id);
		}
		return cIds;
	}

	private static Map<String, RecordType> fetchCaseRecordTypes() {
		if(devName2RecordType != null) {
			return devName2RecordType;
		}

		devName2RecordType = new Map<String, RecordType>();
		for(RecordType rt : [
			SELECT Id, SobjectType, DeveloperName 
			FROM RecordType 
			WHERE SobjectType = 'Case'
		]) {
			devName2RecordType.put(rt.DeveloperName, rt);
		}
		return devName2RecordType;
	}
}