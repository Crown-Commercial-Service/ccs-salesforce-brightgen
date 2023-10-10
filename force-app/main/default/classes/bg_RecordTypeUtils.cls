/**************************************************
* bg_RecordTypeUtils
*
* Utility methods for Record Type
* 
* Author: Josh Adams
* Created: 07/11/2017
* Changes: 
*          
**************************************************/

public class bg_RecordTypeUtils {

	public static Map<String, RecordType> recordTypeMap = new Map<String, RecordType>();
	/*
		Method to return the RecordType for the supplied Object and Record Type Developer name
	*/	    
    public static RecordType GetRecordTypeByObjectandDeveloperName(String objectName, String recordTypeDeveloperName)
    {
        RecordType result;
        String recordTypeKey = objectName + recordTypeDeveloperName;
        if (recordTypeMap.containsKey(recordTypeKey))
        {
          result = recordTypeMap.get(recordTypeKey);
        }
        else
        {
          result = [SELECT SystemModstamp, SobjectType, NamespacePrefix, Name, LastModifiedDate, LastModifiedById, IsActive, Id, DeveloperName, Description, CreatedDate, CreatedById, BusinessProcessId 
                   FROM RecordType
                   WHERE SobjectType = :objectName
                   AND DeveloperName = :recordTypeDeveloperName];
          recordTypeMap.put(recordTypeKey, result);
      }

      return result;
    }
    
    /*
      * Method to return all RecordTypes for the supplied Object keyed by the RecordType developer name
      */
    public static map<String, RecordType> GetRecordTypeByObject(String objectName)
    {
        map<String, RecordType> results = new map<String, RecordType>();
        for (RecordType rt : [SELECT SystemModstamp, SobjectType, NamespacePrefix, Name, LastModifiedDate, LastModifiedById, IsActive, Id, DeveloperName, Description, CreatedDate, CreatedById, BusinessProcessId 
                              FROM RecordType
                              WHERE SobjectType = :objectName])
        {
            results.put(rt.DeveloperName, rt);
        }
        return results;
    }
    
}