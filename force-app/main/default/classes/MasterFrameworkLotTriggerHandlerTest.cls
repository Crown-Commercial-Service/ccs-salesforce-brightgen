@isTest (seeAllData=false)
private class MasterFrameworkLotTriggerHandlerTest
{
	private static final Integer NO_RECORDS = 303;
	private static final String MFL_Name = 'UnitTest MasterFrameworkLotTriggerHandler';
	
	@testSetup
	static void setupTest(){
		Account org = UnitTestDataFactory.createSupplierAccount('MasterFrameworkLotTriggerHandlerTest');
		insert org;

		Master_Framework__c mf = UnitTestDataFactory.createMasterFramework();
		insert mf;

		Master_Framework_Lot__c mfl = UnitTestDataFactory.createMasterFrameworkLot(mf.id);
		mfl.Name = MFL_Name;
		insert mfl;

		List<Supplier_Framework_Lot__c> liSFL = new List<Supplier_Framework_Lot__c> ();

		for (Integer i=0; i < NO_RECORDS; i++){
			liSFL.add(UnitTestDataFactory.createSupplierFrameworkLot(mfl.id, org.id));
		}

		insert liSFL;
		
	}

	@isTest
	static void itShouldUpdateStatusWhenChangedInMFL(){
		// Given
		Master_Framework_Lot__c mfl = [Select Id, Name, Status__c from Master_Framework_Lot__c 
			where Name = :MFL_Name limit 1];
		System.assertEquals(0, [Select id from Supplier_Framework_Lot__c 
				where Master_Framework_Lot__c = :mfl.id 
					and Status__C = :MasterFrameworkLotTriggerHandler.SFL_STATUS_EXPIRED].size(),
			'Initially no Suplier framework lots should have expire status'
		);

		// When
		Test.startTest();
			mfl.Status__c = MasterFrameworkLotTriggerHandler.MFL_STATUS_EXPIRED;
			update mfl;
		Test.stopTest();

		// Then
		System.assertEquals(NO_RECORDS, [Select id from Supplier_Framework_Lot__c 
				where Master_Framework_Lot__c = :mfl.id 
					and Status__C = :MasterFrameworkLotTriggerHandler.SFL_STATUS_EXPIRED].size(),
			'Initially no Suplier framework lots should have expire status'
		);
	}
}