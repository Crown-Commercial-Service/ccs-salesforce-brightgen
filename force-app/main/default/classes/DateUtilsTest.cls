@isTest
private class DateUtilsTest {
	
	static Boolean hasXmas()
	{
		// test with Christmass 2015 which was a Friday, if recurrance defined for it
		Date xmas2015 = Date.newInstance(2015,12,25);
		
		return 0 < [select count() from Holiday where isRecurrence = true and RecurrenceStartDate <= :xmas2015
					and Name like '%Christmas%'
					and (RecurrenceEndDateOnly = null or RecurrenceEndDateOnly > :xmas2015)];
	}
	
	private static testMethod void testAddWorkingDaysInclusive()
	{
		if(hasXmas())	// Christmas is defined
		{
			system.assertNotEquals(null,DateUtils.bh.id,'Default business hours should be defined and active.');
			
			Date testDate = Date.newInstance(2015,12,21);	// MONDAY
			system.assertEquals(testDate,DateUtils.addWorkingDays(testDate,1),'2015-12-21 + 1WD = 2015-12-21');
			system.assertEquals(testDate.addDays(1),DateUtils.addWorkingDays(testDate.addDays(-1),2),'2015-12-20 + 2WD = 2015-12-22');
			system.assertEquals(testDate.addDays(2),DateUtils.addWorkingDays(testDate,3),'2015-12-21 + 3WD = 2015-12-23');
			system.assertEquals(testDate,DateUtils.addWorkingDays(testDate.addDays(-7),6),'2015-12-14 + 6WD = 2015-12-21');
		}
		else system.debug('WARNING: Christmas not defined or not active. Aborting test.');
	}
	
	private static testMethod void testAddWorkingDaysExclusive()
	{
		if(hasXmas())	// Christmas is defined
		{
			system.assertNotEquals(null,DateUtils.bh.id,'Default business hours should be defined and active.');
			
			Date testDate = Date.newInstance(2015,12,21);	// MONDAY
			system.assertEquals(testDate.addDays(1),DateUtils.addWorkingDays(testDate,1,true),'2015-12-21 + 1WD = 2015-12-22');
			system.assertEquals(testDate.addDays(2),DateUtils.addWorkingDays(testDate.addDays(-1),2,true),'2015-12-20 + 2WD = 2015-12-23');
			system.assertEquals(testDate.addDays(3),DateUtils.addWorkingDays(testDate,3,true),'2015-12-21 + 3WD = 2015-12-24');
			system.assertEquals(testDate.addDays(1),DateUtils.addWorkingDays(testDate.addDays(-7),6,true),'2015-12-14 + 6WD = 2015-12-22');
		}
		else system.debug('WARNING: Christmas not defined or not active. Aborting test.');
	}
	
	private static testMethod void testCalculateDurationInclusive()
	{
		if(hasXmas())	// Christmas is defined
		{
			system.assertNotEquals(null,DateUtils.bh.id,'Default business hours should be defined and active.');
			
			Date testDate = Date.newInstance(2015,12,21);	// MONDAY
			system.assertEquals(1,DateUtils.calculateDuration(testDate,testDate),'2015-12-21 - 2015-12-21 = 1WD');
			system.assertEquals(2,DateUtils.calculateDuration(testDate.addDays(-1),testDate),'2015-12-20 - 2015-12-21 = 2WD');
			system.assertEquals(3,DateUtils.calculateDuration(testDate,testDate.addDays(2)),'2015-12-21 - 2015-12-23 = 3WD');
			system.assertEquals(4,DateUtils.calculateDuration(testDate,testDate.addDays(4)),'2015-12-21 - 2015-12-25 = 4WD');
			system.assertEquals(6,DateUtils.calculateDuration(testDate.addDays(-7),testDate),'2015-12-14 - 2015-12-21 = 6WD');
		}
		else system.debug('WARNING: Christmas not defined or not active. Aborting test.');
	}
	
	private static testMethod void testCalculateDurationExclusive()
	{
		if(hasXmas())	// Christmas is defined
		{
			system.assertNotEquals(null,DateUtils.bh.id,'Default business hours should be defined and active.');
			
			Date testDate = Date.newInstance(2015,12,21);	// MONDAY
			system.assertEquals(0,DateUtils.calculateDuration(testDate,testDate,true),'2015-12-21 - 2015-12-21 = 0WD');
			system.assertEquals(1,DateUtils.calculateDuration(testDate.addDays(-1),testDate,true),'2015-12-20 - 2015-12-21 = 1WD');
			system.assertEquals(2,DateUtils.calculateDuration(testDate,testDate.addDays(2),true),'2015-12-21 - 2015-12-23 = 2WD');
			system.assertEquals(3,DateUtils.calculateDuration(testDate,testDate.addDays(4),true),'2015-12-21 - 2015-12-25 = 3WD');
			system.assertEquals(5,DateUtils.calculateDuration(testDate.addDays(-7),testDate,true),'2015-12-14 - 2015-12-21 = 5WD');
		}
		else system.debug('WARNING: Christmas not defined or not active. Aborting test.');
	}
	
	// add a whole lot of days to test if we get an limit exception
	private static testMethod void stressTest()
	{
		Date startDate = Date.newInstance(2010,1,3);
		
		Test.startTest();
		DateUtils.addWorkingDays(startDate,1000);
		Test.stopTest();
	}
    
}