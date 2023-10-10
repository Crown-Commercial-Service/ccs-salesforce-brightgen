/*********************************************************************
 Name:  FrameworkLotSupplierRelatedList_CX
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: Controller extension for FrameworkLotSupplierRelatedList
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL             Description
		1.0  Cezary Zeleznicki  2016-12-01     Initial version
 *********************************************************************/
public with sharing class FrameworkLotSupplierRelatedList_CX {

	public final static String SHOW_FULL_PAGE_PARAM = 'showFullPage';
	private final Master_Framework__c framework;
	public Boolean showFullPage {get; private set;}
	private ApexPages.StandardSetController setCon;
	private List<SupplierWrapper> suppliers;
	@testVisible
	private Integer pageSize;

	public FrameworkLotSupplierRelatedList_CX(ApexPages.StandardController stdController) {
		this.framework = (Master_Framework__c)stdController.getRecord();
		this.showFullPage = ApexPages.currentPage().getParameters().get(SHOW_FULL_PAGE_PARAM) != null;
		this.pageSize = showFullPage ? 50 : 5;
		this.setCon = fetchStandardSetController();
	}

	private ApexPages.StandardSetController fetchStandardSetController() {
		ApexPages.StandardSetController standardSetController;
		if(framework.Id == null) {
			return null;
		}
		List<Master_Framework_Lot__c> frameworkLots = fetchFrameworkLots(framework.Id);

		List<Supplier_Framework_Lot__c> suppFrameworkLots = [
			SELECT Id, Name, Master_Framework_Lot__c, Master_Framework_Lot__r.Name, Supplier_Code__c,
				Status__c, Supplier__c, Supplier__r.Name
			FROM Supplier_Framework_Lot__c 
			WHERE Master_Framework_Lot__c IN :frameworkLots
				AND Status__c = 'Live'
			ORDER BY Supplier__r.Name ASC
		];
		Map<Id, Supplier_Framework_Lot__c> suppId2SupplierFrameworkLot = new Map<Id, Supplier_Framework_Lot__c>();
		List<Account> suppliers = new List<Account>();
		List<Supplier_Framework_Lot__c> sortedSupplierFrameworkLots = new List<Supplier_Framework_Lot__c>();
		for(Supplier_Framework_Lot__c sfl : suppFrameworkLots) {
			if(suppId2SupplierFrameworkLot.containsKey(sfl.Supplier__c)) {
				continue;
			}
			suppId2SupplierFrameworkLot.put(sfl.Supplier__c, sfl);
			suppliers.add(sfl.Supplier__r);
		}

		suppliers.sort();
		for(Account a : suppliers) {
			sortedSupplierFrameworkLots.add(suppId2SupplierFrameworkLot.get(a.Id));
		}

		standardSetController = new ApexPages.StandardSetController(sortedSupplierFrameworkLots);
		return standardSetController;
	}

	private List<Master_Framework_Lot__c> fetchFrameworkLots(Id frameworkId) {
		return [
			SELECT Id
			FROM Master_Framework_Lot__c
			WHERE Master_Framework__c = :frameworkId
		];
	}

	public List<SupplierWrapper> getSuppliers() {
		if(setCon == null) {
			return null;
		}
		suppliers = new List<SupplierWrapper>();

		setCon.setPageSize(pageSize);

		for(Supplier_Framework_Lot__c sfl : (List<Supplier_Framework_Lot__c>)setCon.getRecords()) {
			suppliers.add(new SupplierWrapper(sfl.Supplier__r.Name, sfl.Supplier__c, sfl));
		}
		
		return suppliers;
	}

	public PageReference goBackToFramework() {
		PageReference pr = new ApexPages.StandardController(framework).view();
		pr.getParameters().put('inline', '0');
		pr.setRedirect(true);
		return pr;
	}

	public PageReference goToList() {
		PageReference pr = Page.FrameworkLotSupplierRelatedList;
		pr.getParameters().put(SHOW_FULL_PAGE_PARAM, '1');
		showFullPage = true;
		pageSize = 50;
		return pr;
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
		setCon.first();
	}

	public void last() {
		setCon.last();
	}

	public void previous() {
		setCon.previous();
	}

	public void next() {
		setCon.next();
	}

	public class SupplierWrapper {
		public String name {get; private set;}
		public Id id {get; private set;}
		public Supplier_Framework_Lot__c suppFrameworkLot {get; private set;}

		public SupplierWrapper(String name, Id id, Supplier_Framework_Lot__c suppFrameworkLot) {
			this.name = name;
			this.id = id;
			this.suppFrameworkLot = suppFrameworkLot;
		}
	}
}