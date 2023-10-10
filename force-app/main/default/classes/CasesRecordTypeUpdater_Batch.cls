/*********************************************************************
 Name:  CasesRecordTypeUpdater_Batch
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Batch job to update all cases with new record types
				ATTENTION! ONE TIME DATA FIX, CAN BE DELETED AFTER USE
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-11-08     Initial version
 *********************************************************************/
global class CasesRecordTypeUpdater_Batch implements Database.Batchable<sObject>, Schedulable {
		
	private final String query;
	private List<Database.SaveResult> dbr;
	private List<Case> casesInScope;
	
	global CasesRecordTypeUpdater_Batch() {
		this.dbr = new List<Database.SaveResult>();
		this.casesInScope = new List<Case>();
		this.query = 'SELECT Id, RecordTypeId, CaseNumber, Procurement_Route1__c, RecordType.DeveloperName ' +
			'FROM Case ' +
			'WHERE RecordType.DeveloperName = \'Procurement\' ' +
				'AND Procurement_Route1__c != null';
	}
		
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(SchedulableContext sc) {
		Database.executeBatch(this);
	}

	global void execute(Database.BatchableContext BC, List<Case> scope) {
		if(scope.isEmpty()) {
			return;
		}
		casesInScope.addAll(scope);
		String proc = 'Procurement_';

		for(Case c : casesInScope) {
			String procRoute = (String)c.get('Procurement_Route1__c');
			String recTypeName = proc + procRoute
				.replace('(', '')
				.replace(')', '')
				.replace(' ', '_');
			c.RecordTypeId = RecordTypeFetcher.fetchCaseRtId(recTypeName);
		}
		dbr = Database.update(casesInScope, false);
		logErrors();
	}
		
	global void finish(Database.BatchableContext BC) {
	}

	private void logErrors() {
		Map<Case, String> failedCaseToErrorMsg = new Map<Case, String>();

		for(Integer i = 0; i < casesInScope.size(); i++) {
			Database.SaveResult sr = dbr[i];
			Case origRecord = casesInScope[i];
			if(sr.isSuccess()) {
				continue;
			}
			String errMsg = '';
			for(Database.Error err : sr.getErrors()) {
				errMsg += err.getMessage() + '\n';
			}
			failedCaseToErrorMsg.put(origRecord, errMsg);
		}

		for(Case failedCase : failedCaseToErrorMsg.keySet()) {
			String caseNumber = 'Case Number: ' + failedCase.CaseNumber;
			String errMsg = failedCase.Id + ': ' + caseNumber + ' ' + failedCaseToErrorMsg.get(failedCase);
			ExceptionLoggingHelper.createErrorLog(UserInfo.getUserId(), CasesRecordTypeUpdater_Batch.class.toString(), '',
				errMsg, new CasesRecordTypeUpdateException(errMsg),'ERROR', null, null, 
				(Integer)DateTime.now().getTime(), null
			);
		}

	}
	
	public class CasesRecordTypeUpdateException extends Exception {
	}
}