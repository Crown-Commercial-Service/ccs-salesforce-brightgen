/*********************************************************************
 Name:  COW_RealignLaterStagesController
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: controller for the realing later stages button/page                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-04-28		Initial version 	
   1.1	 Cezary Zeleznicki	2016-11-09		Simplified Stage dates US1645
 *********************************************************************/
public with sharing class COW_RealignLaterStagesController {
	
	public static final String RECORDID_PARAM = 'recordId';
	
	private Procurement_Stage__c thisStage;
	
	// MESSAGES
	public static final String MSG_NORECORDID = Label.COW_Realign_NoRecordId;
	public static final String MSG_NOSEQUENCE = Label.COW_Realign_NoSeq;
	public static final String MSG_NOSTARTDATE = Label.COW_Realign_NoStartSate;
	public static final String MSG_NOLATERSTAGES = Label.COW_Realign_NoLaterStages;
	public static final String MSG_CONFIRM = Label.COW_Realign_Confirm;
	public static final String MSG_ISCOMPLETED = Label.COW_Realign_IsCompleted;
	
	public COW_RealignLaterStagesController()
	{
		init();
	}
	
	// find details of current stage and do validation
	private void init()
	{
		Id recordId = (Id) ApexPages.currentPage().getParameters().get(RECORDID_PARAM);
		if(recordId == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(MSG_NORECORDID, new List<String>{RECORDID_PARAM})));
			return;
		}
		
		thisStage = findStages(recordId, null).get(0);
		
		if(thisStage.Seq__c == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MSG_NOSEQUENCE));
			return;
		}
		
		Date startDate = thisStage.Planned_Start_Date__c;
		
		if(startDate == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
				String.format(MSG_NOSTARTDATE, new List<String>{'Planned'})));
			return;
		}
		
		if(thisStage.Completed__c)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MSG_ISCOMPLETED));
			return;
		}
		
		// warn user of what they're about to do
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
			String.format(MSG_CONFIRM, new List<String>{'planned'})));
	}
	
	
	// find later stages and recalculate their dates
	// if this stage doesn't have an end date, include it in calcualtion
	// if stage has end date, but workign days between start and end date is different from default duration/override duration, 
	// then change override duration
	// if you're on the last stage and no updates needed at all, show error message that no action was taken 
	public Pagereference realignLaterStages()
	{
		Date startDate = thisStage.Planned_Start_Date__c;
		Date endDate = thisStage.Planned_End_Date__c;
		
		// find all needed stages for processing
		List<Procurement_Stage__c> stages = findStages(null, thisStage.Procurement__c);
		
		// remove previous and this stages
		while(!stages.isEmpty() && stages.get(0).Seq__c <= thisStage.Seq__c)
		{
			stages.remove(0);
		}
		
		if(endDate == null)	// if we don't have end date on thisStage, we should preocess thisStage too
		{
			if(stages.isEmpty())
			{
				stages.add(thisStage);
			}
			else
			{
				stages.add(0,thisStage);
			}
		}
		else
		{
			// if new duration based on dates is different from default or override, update override
			Decimal currentDuration = (Decimal) DateUtils.calculateDuration(startDate,endDate);
			if(thisStage.Duration_Override__c != currentDuration 
				&& (thisStage.Duration_Override__c != null || thisStage.Default_Duration__c != currentDuration))
			{
				// DE100 if currentDuration and default duration are the same, just remove duration override instead of duplicating
				thisStage.Duration_Override__c = thisStage.Default_Duration__c != currentDuration ? currentDuration : null;
				if(stages.isEmpty())
				{
					stages.add(thisStage);
				}
				else
				{
					stages.add(0,thisStage);
				}
			}
			else	// if no need to update existing stage
			{
				if(stages.isEmpty())	// obviously no stages need processing so we're on last stage
				{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MSG_NOLATERSTAGES));
					return null;
				}
				else	// if processing from next stage, make sure it starts a day after thisStage ends
				{
					stages.get(0).Planned_Start_Date__c = DateUtils.addWorkingDays(endDate,2);
				}
			}
		}
		
		DateUtils.calculateStageDates(stages);
		
		try
		{
			update stages;
		}
		catch(exception e)
		{
			ApexPages.addMessages(e);
			return null;
		}
		
		return returnToRecord();
	}
	
	// find stage records with all needed fields
	private List<Procurement_Stage__c> findStages(Id stageId, Id caseId)
	{
		return [
			SELECT Id, Procurement__c, Seq__c, Default_Duration__c, Duration_Override__c, 
				Completed__c, Planned_Start_Date__c, Planned_End_Date__c 
			FROM Procurement_Stage__c 
			WHERE Id = :stageId or Procurement__c = :caseId
			ORDER BY Seq__c ASC
		];	// MUST BE ORDERED
	}
	
	// return to original Procurement Stage record
	public Pagereference returnToRecord()
	{
		return new pagereference('/' + thisStage.Id);
	}
	
	// should the "realign" button render
	public Boolean getAllowRealign()
	{
		for(Apexpages.Message msg : ApexPages.getMessages())
		{
			if(msg.getSeverity() == ApexPages.Severity.ERROR)
			{
				return false;
			}
		}
		return true;
	}
    
}