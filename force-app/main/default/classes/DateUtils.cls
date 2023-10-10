/*********************************************************************
 Name:  DateUtils
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: class to help handle date calculations lieka dding work days                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-03-03		Initial version 	
   1.1	 Cezary Zeleznicki	2016-11-09		Simplified Stage dates US1645
 *********************************************************************/

public without sharing class DateUtils {
	
	public static BusinessHours bh = [select Id, Name from BusinessHours where IsDefault = true and IsActive = true limit 1];
	
	// method adds a number of working days to a provided date
	// BusinessHours only works with datetime so we convert date to a noon datetime
	// ! make sure you've added the holidays to specific business hours
	// restrictions: tested to work with hours encompasing noon in GMT (London/UK) timezone
	// also adding 1 day will return the same day as end date is the LAST date of period
	public static Date addWorkingDays(Date startDate, Integer numOfWorkingDays)
	{
		return addWorkingDays(startDate, numOfWorkingDays, false);
	}
	
	// isExclusive = false - use when end date is part of period (e.g. Jan 4th + 3 = Jan 6th) (aka "inclusive")
	// isExclusive = true  - use when end date is not part of period (e.g. Jan 4th + 3 = Jan 7th)
	public static Date addWorkingDays(Date startDate, Integer numOfWorkingDays, Boolean isExclusive)
	{
		Datetime cursorDT = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 12, 0, 0);
		
		if(numOfWorkingDays <= 0) return startDate;	// not doing negative calculations
		
		// rewind any starting non-working days to a working day for calculation
		while(!BusinessHours.isWithin(bh.Id, cursorDT))
		{
			cursorDT = cursorDT.addDays(1);
		}
		
		// start adding business days
		Integer i = isExclusive ? 0 : 1;
		while(i < numOfWorkingDays)
		{
			cursorDT = cursorDT.addDays(1);
			if(BusinessHours.isWithin(bh.Id, cursorDT)) i++;
		}
		
		return cursorDT.date();
	}
	
	// method calculates period duration with end date as last day of period
	public static Integer calculateDuration(Date startDate, Date endDate)
	{
		return calculateDuration(startDate, endDate, false);
	}
	
	// isExclusive = false - use when end date is part of period (e.g. Jan 4th - Jan 7th = 4)
	// isExclusive = true  - use when end date is not part of period (e.g. Jan 4th + Jan 7th = 3)
	public static Integer calculateDuration(Date startDate, Date endDate, Boolean isExclusive)
	{
		if(startDate == null || endDate == null || endDate < startDate) 
		{
			return null;	// not valid calculations
		}
		
		// if end date is not a working day, do a "rewind" - find first workign day that came before
		{
			Datetime endDateTime = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 12, 0, 0);
			while(!BusinessHours.isWithin(bh.Id, endDateTime))
			{
				endDateTime = endDateTime.addDays(-1);
			}
			endDate = endDateTime.date();
		}
		
		Integer delta = isExclusive ? 0 : 1;
		
		while(startDate < endDate)
		{
			startDate = addWorkingDays(startDate,1,true);
			delta++;
		}
		
		return delta;
	}
	
	// this method will calculate start and end dates for a list of stages in sequential order (MAKE SURE LIST IS ORDERED!)
	// make sure stages all belong to same case
	// it will ONLY take into account stages that are either standard or have Duration Override set
	public static void calculateStageDates(List<Procurement_Stage__c> stages)
	{
		Date startDate = stages.get(0).Planned_Start_Date__c;
		if(startDate == null) {
			return;
		}
		
		for(Procurement_Stage__c stage : stages)
		{
			// if Duration override provided use that, if not use default duration
			Integer duration = stage.Duration_Override__c != null ? stage.Duration_Override__c.intValue() 
				: (stage.Default_Duration__c != null ? stage.Default_Duration__c.intValue() : null); 
			if(duration != null)	// if duration provided
			{
				stage.Planned_Start_Date__c = startDate;
				stage.Planned_End_Date__c = addWorkingDays(startDate,duration);
				// create start date for next stage
				startDate = addWorkingDays(stage.Planned_End_Date__c, 2);
			}
		}
	}
    
}