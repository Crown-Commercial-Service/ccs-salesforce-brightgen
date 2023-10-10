/*********************************************************************
 Name:  CaseUtil
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Contains util methods related to Case object
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-20     Initial version
		1.1  Cezary Zeleznicki	2016-11-03		 Procurement RT change
		1.2  Cazary Zeleznicki 	2016-12-06		Enquiry Entitlement Id
		1.3  Cezary Zeleznicki 	2016-12-14		Sla status change
 *********************************************************************/
public class CaseUtil {
	public final static String RECORD_TYPE_ENQUIRY = 'Enquiry';
	public final static String CASE_STATUS_CLOSED = 'Closed';
	public final static String CASE_STATUS_ABANDONED = ' Abandoned';
	public final static String RESOLUTION_SPAM = 'Spam';
	public final static String RECORD_TYPE_PROCUREMENT = 'Procurement';
	public static final Set<String> PROCUREMENT_RT_DEV_NAMES = new Set<String>{
		'Procurement_Call_Off_Competition', 'Procurement_Call_Off_Direct_Award', 
		'Procurement_Low_Value', 'Procurement_Open_Market', 'Procurement_Single_Tender_Action'};
	public final static String SLA_STATUS_IN_PROGRESS = 'In Progress';
	public final static String SLA_STATUS_WARNING = 'Warning';
	private static List<Tier_Level__c> tiers;
	
	/*******************************************************************

	Purpose: Used to bluk close cases considered as SPAM

	Parameters: caseIds -	Id of cases to close
	Returns: 		String error message to be displayed on page.

	********************************************************************/
	public static List<Case> bulkMarkSpam(Set<Id> caseIds) {
		List<Case> casesForUpdate = new List<Case>();

		for(Case c : fetchCases(caseIds)) {
			if(c.IsClosed) {
				continue;
			}
			String status = CASE_STATUS_CLOSED;
			if(PROCUREMENT_RT_DEV_NAMES.contains(c.RecordType.DeveloperName)) {
				status = CASE_STATUS_ABANDONED;
			}
			c.Status = status;
			c.Resolution_1__c = RESOLUTION_SPAM;
			casesForUpdate.add(c);
		}
		return casesForUpdate;
	}

	@testVisible
	private static List<Case> fetchCases(Set<Id> caseIds) {
		return [
			SELECT Id, Status, Resolution_1__c, RecordType.DeveloperName, IsClosed
			FROM Case
			WHERE Id IN :caseIds AND (RecordType.DeveloperName IN :PROCUREMENT_RT_DEV_NAMES OR 
    			RecordType.DeveloperName = :RECORD_TYPE_ENQUIRY)
		];
	}

	/*******************************************************************

	Purpose: Used to fetch default Tier Level record

	Returns: Id of tier level record if only one default record exists, 
			else returns null.

	********************************************************************/
	public static Id fetchDefaultTierLevel() {
		if(tiers == null) {
			tiers = [
				SELECT Id
				FROM Tier_Level__c
				WHERE Is_Default__c = true
			];
		}

		if(tiers.size() == 1) {
			return tiers[0].Id;
		}
		return null;
	}
}