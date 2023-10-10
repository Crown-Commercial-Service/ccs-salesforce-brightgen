/*********************************************************************
 Name:  FrameworkInterestGenerator_Batch
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Batch job to generate framework interest junction records 
 		based on Framework Interests picklist values
		ATTENTION! ONE TIME DATA FIX, CAN BE DELETED AFTER USE
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-12-12     Initial version
 *********************************************************************/
global class FrameworkInterestGenerator_Batch implements Database.Batchable<sObject>, Schedulable {
		
	private final String query;
	private List<Database.SaveResult> dbr;
	@testVisible
	private List<Organisation_Framework__c> orgFrameworks;
	
	global FrameworkInterestGenerator_Batch() {
		this.dbr = new List<Database.SaveResult>();
		this.orgFrameworks = new List<Organisation_Framework__c>();
		this.query = 'SELECT Id, Framework_Interest__c, RecordTypeId, RecordType.DeveloperName, ' +
			'(SELECT Id, Organisation__c, Framework__c, Comments__c FROM Organisation_Frameworks__r) ' +
			'FROM Account ' +
			'WHERE RecordType.DeveloperName = \'Organisation\' ' +
			'AND Framework_Interest__c != null';
	}
		
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(SchedulableContext sc) {
		Database.executeBatch(this);
	}

	global void execute(Database.BatchableContext BC, List<Account> scope) {
		if(scope.isEmpty()) {
			return;
		}

		Set<String> frameworkNames = new Set<String>();
		Map<Id, Set<String>> accId2FrameworkNames = new Map<Id, Set<String>>();
		for(Account a : scope) {
			if(!a.Organisation_Frameworks__r.isEmpty()) {
				continue;
			}
			Set<String> frameworkInterests = new Set<String>();
			frameworkInterests.addAll(a.Framework_Interest__c.split(';'));
			frameworkNames.addAll(frameworkInterests);
			accId2FrameworkNames.put(a.Id, frameworkInterests);
		}

		Map<String, Id> name2FrameworkId = fetchFrameworkIdsByNames(frameworkNames);
		List<Note> notesToInsert = new List<Note>();
		for(Id accId : accId2FrameworkNames.keySet()) {
			Set<String> matchedNames = new Set<String>();
			Set<String> notMatchedNames = new Set<String>();

			for(String fName : accId2FrameworkNames.get(accId)) {
				Boolean isMatch = name2FrameworkId.containsKey(fName);
				
				if(isMatch) {
					Organisation_Framework__c orgFramework = new Organisation_Framework__c(
						Framework__c = name2FrameworkId.get(fName),
						Organisation__c = accId
					);
					orgFrameworks.add(orgFramework);
					matchedNames.add(fName);
				} else {
					notMatchedNames.add(fName);
				}
			}
			notesToInsert.addAll(createNotes(accId, true, matchedNames));
			notesToInsert.addAll(createNotes(accId, false, notMatchedNames));
		}

		insert notesToInsert;
		dbr = Database.insert(orgFrameworks, false);
		logErrors();
	}

	private Map<String, Id> fetchFrameworkIdsByNames(Set<String> frameworkNames) {
		List<Master_Framework__c> frameworks = [
			SELECT Id, Name
			FROM Master_Framework__c
			WHERE Name IN :frameworkNames
		];
		Map<String, Id> name2FrameworkId = new Map<String, Id>();

		for(Master_Framework__c mf : frameworks) {
			name2FrameworkId.put(mf.Name, mf.Id);
		}
		return name2FrameworkId;
	}

	private List<Note> createNotes(Id accountId, Boolean isSuccess, Set<String> fNames) {
		final Integer MAX_BODY_LENGTH = 32000;
		List<Note> notes = new List<Note>();
		if(fNames.isEmpty()) {
			return notes;
		}
		String title = '** SYSTEM Framework Interests Picklist to Related List Migration ' + 
			(isSuccess ? '' : 'NOT') + ' MATCHED';
		String body = '';
		for(String fName : fNames) {
			if(body.length() + fName.length() >= MAX_BODY_LENGTH) {
				notes.addAll(createNotes(accountId, isSuccess, fNames));
				break;
			}
			body += fName + '\n';
			fNames.remove(fName);
		}
		Note n = new Note();
		n.ParentId = accountId;
		n.Body = body;
		n.Title = title.abbreviate(80);
		n.IsPrivate = false;
		notes.add(n);
		return notes;
	}
		
	global void finish(Database.BatchableContext BC) {
	}

	private void logErrors() {
		Map<Organisation_Framework__c, String> failedOrgFramework2Error = new Map<Organisation_Framework__c, String>();

		for(Integer i = 0; i < orgFrameworks.size(); i++) {
			Database.SaveResult sr = dbr[i];
			Organisation_Framework__c origRecord = orgFrameworks[i];
			if(sr.isSuccess()) {
				continue;
			}
			String errMsg = '';
			for(Database.Error err : sr.getErrors()) {
				errMsg += err.getMessage() + '\n';
			}
			failedOrgFramework2Error.put(origRecord, errMsg);
		}

		for(Organisation_Framework__c failedOrgFramework : failedOrgFramework2Error.keySet()) {
			String accId = 'Account Id: ' + failedOrgFramework.Organisation__c;
			String errMsg = 'Framework Id: ' + failedOrgFramework.Framework__c + ': ' + accId + ' ' + failedOrgFramework2Error.get(failedOrgFramework);
			ExceptionLoggingHelper.createErrorLog(UserInfo.getUserId(), FrameworkInterestGenerator_Batch.class.toString(), '',
				errMsg, new OrganisationFrameworkInsertException(errMsg),'ERROR', null, null, 
				(Integer)DateTime.now().getTime(), null
			);
		}

	}
	
	public class OrganisationFrameworkInsertException extends Exception {
	}
}