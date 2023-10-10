/*********************************************************************
 Name:  CaseEmailsRelatedList_CX
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller extension for CaseEmailsRelatedList page and
					MoveCaseEMails page 
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-10-19     Initial version
 *********************************************************************/
public with sharing class CaseEmailsRelatedList_CX {

	public final static String SHOW_FULL_PAGE_PARAM = 'showFullPage';
	private final Case caseRecord;
	public Boolean showFullPage {get; private set;}
	private ApexPages.StandardSetController setCon;
	private Map<Id, EmailWrapper> emails;
	@testVisible
	private Integer pageSize;
	public Case targetCase {get;set;}
	private Map<Id, EmailWrapper> id2SelectedEmails;

	public CaseEmailsRelatedList_CX(ApexPages.StandardController stdController) {
		this.caseRecord = (Case)stdController.getRecord();
		this.showFullPage = ApexPages.currentPage().getParameters().get(SHOW_FULL_PAGE_PARAM) != null;
		this.pageSize = showFullPage ? 10 : 5;
		this.setCon = fetchStandardSetController(caseRecord.Id);
		this.targetCase = new Case();
		this.id2SelectedEmails = new Map<Id, EmailWrapper>();
	}

	private ApexPages.StandardSetController fetchStandardSetController(Id caseRecordId) {
		ApexPages.StandardSetController standardSetController;
		if(caseRecordId == null) {
			return null;
		}
		standardSetController = new ApexPages.StandardSetController(Database.getQueryLocator([
			SELECT Id, Source_Case__c, CreatedDate, Incoming, FromAddress, Subject, 
				Status, MessageDate, TextBody, Was_Moved__c, HasAttachment
			FROM EmailMessage 
			WHERE ParentId = :caseRecordId
			ORDER BY MessageDate DESC
		]));
		return standardSetController;
	}

	public List<EmailWrapper> getEmails() {
		if(setCon == null) {
			return null;
		}
		emails = new Map<Id, EmailWrapper>();
		
		setCon.setPageSize(pageSize);
		for(EmailMessage em : (List<EmailMessage>)setCon.getRecords()) {
			Boolean isSelected = id2SelectedEmails.keySet().contains(em.Id);
			emails.put(em.Id, new EmailWrapper(em, isSelected));
		}
		return emails.values();
	}

	public List<EmailWrapper> getSelectedEmails() {
		return id2SelectedEmails.values();
	}

	public PageReference openMoveEmailsPage() {
		collectSelectedEmails();

		if(id2SelectedEmails.isEmpty()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.No_emails_selected));
			return null;
		}
		PageReference pr = Page.MoveCaseEmails;
		pr.setRedirect(false);
		return pr;
	}

	public Boolean getIsAbleToSendEmail() {
		return fetchPermissions(caseRecord.Id).HasEditAccess;
	}

	private UserRecordAccess fetchPermissions(Id caseId) {
		return [
			SELECT RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess 
			FROM UserRecordAccess 
			WHERE UserId=:UserInfo.getUserId() 
				AND RecordId =: caseId];
	}

	public PageReference goBackToCase() {
		PageReference pr = new ApexPages.StandardController(caseRecord).view();
		pr.getParameters().put('inline', '0');
		pr.setRedirect(true);
		return pr;
	}

	public PageReference moveEmails() {
		if(targetCase.ParentId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.No_target_Case_selected));
			return null;
		}

		collectSelectedEmails();
		
		String status = EmailMessageUtil.transferEmailsToTargetCase(caseRecord.Id, targetCase.ParentId, id2SelectedEmails.keySet());
		if(status == Label.Success_msg) {
			clearEmailListOfSuccesses();
			PageReference pr = new PageReference('/' + targetCase.ParentId);
			pr.getParameters().put('inline', '0');
			return pr; 
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, status));
		}
		return null;
	}

	private void clearEmailListOfSuccesses() {
		for(Id emailId : id2SelectedEmails.keySet()) {
			emails.remove(emailId);
		}
	}

	public void showMore() {
		pageSize += 5;
		collectSelectedEmails();
		getEmails();
	}

	public PageReference goToList() {
		PageReference pr = Page.CaseEmailsRelatedList;
		collectSelectedEmails();
		pr.getParameters().put(SHOW_FULL_PAGE_PARAM, '1');
		showFullPage = true;
		pageSize = 10;
		return pr;
	}

	private void collectSelectedEmails() {
		for(EmailWrapper ew : emails.values()) {
			if(ew.isSelected) {
				id2SelectedEmails.put(ew.record.Id, ew);
			}
		}
	}

	public Integer getRecordsSize() {
		return setCon.getResultSize();
	}

	public Boolean getHasNext() {
		return setCon.getHasNext();
	}

	public Boolean getHasPrevious() {
		return setCon.getHasPrevious();
	}

	public Boolean getIsFirst() {
		return setCon.getPageNumber() == 1;
	}

	public void first() {
		collectSelectedEmails();
		setCon.first();
	}

	public void last() {
		collectSelectedEmails();
		setCon.last();
	}

	public void previous() {
		collectSelectedEmails();
		setCon.previous();
	}

	public void next() {
		collectSelectedEmails();
		setCon.next();
	}

	public class EmailWrapper {
		public EmailMessage record {get; private set;}
		public Boolean isSelected {get;set;}

		public EmailWrapper(EmailMessage record, Boolean isSelected) {
			this.record = record;
			this.isSelected = isSelected;
		}
	}
}