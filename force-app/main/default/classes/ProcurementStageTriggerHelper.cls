/*********************************************************************
 Name:  ProcurementStageTriggerHelper()
 Copyright © 2016  Salesforce
 ======================================================
 ======================================================
 Purpose: handler class for procurement stage trigger                                                            
 -------                                                            
 ======================================================
 ======================================================
 History                                                            
 -------                                                            
 VERSION  AUTHOR            DATE             DETAIL				Description
   1.0   Klea Kolaric		2016-03-04		Initial version 	
   2.0	Cezary Zeleznicki	2016-11-02		Procurement RT change
 *********************************************************************/

public class ProcurementStageTriggerHelper {
	
	public static void onBeforeInsert(List<Procurement_Stage__c> triggerNew)
	{
		setStageDuration(triggerNew,null);
	}
	
	public static void onBeforeUpdate(List<Procurement_Stage__c> triggerNew, Map<Id,Procurement_Stage__c> oldMap)
	{
		setStageDuration(triggerNew,oldMap);
	}
	
	public static Map<String, Map<String, Ops_Workflow_Templates__c>> templatesWF
	{
		get
		{
			if(templatesWF == null)
			{
				templatesWF = new Map<String, Map<String, Ops_Workflow_Templates__c>>();
				List<Ops_Workflow_Templates__c> wftemps = Ops_Workflow_Templates__c.getAll().values();
				for(Ops_Workflow_Templates__c wftemp : wftemps)
				{
					if(!templatesWF.containsKey(wftemp.Record_Type_Name__c)) 
					{
						templatesWF.put(wftemp.Record_Type_Name__c, new Map<String, Ops_Workflow_Templates__c>());
					}
					templatesWF.get(wftemp.Record_Type_Name__c).put(wftemp.Stage_Id__c, wftemp);
				}
			}
			return templatesWF;
		}
	}
	
	// US710 (calculate the actual time (in working days) that it took to deliver a stage)
	// this method will calculate the duration of a stage
	// we need to take into account business days and holidays so can only do this using BusinessHours.isWithin
	// this is why stage is calculated by icrementing start date day by day
	public static void setStageDuration(List<Procurement_Stage__c> stages, Map<Id,Procurement_Stage__c> oldMap)
	{
		for(Procurement_Stage__c st : stages)
		{
			// if both actual start and end date populated and record is new or has changed
			if(st.Actual_Start_Date__c != null && st.Actual_End_Date__c != null
				&& (oldMap == null || st.Actual_End_Date__c != oldMap.get(st.Id).Actual_End_Date__c))
			{
				st.Delivery_Duration__c = DateUtils.calculateDuration(st.Actual_Start_Date__c,st.Actual_End_Date__c);
			}
		}
	}
	
}