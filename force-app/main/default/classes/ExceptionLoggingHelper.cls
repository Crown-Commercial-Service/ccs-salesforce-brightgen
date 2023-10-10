/*****************************************************************************************************************************
Name: ExceptionLoggingHelper

Purpose: Utilty class for logging errors

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      07/03/2016      INITIAL DEVELOPMENT
*******************************************************************************************************************************/

global without sharing class ExceptionLoggingHelper {
	
	public static final String EXCEPTION_LOGGER_DEFAULT_APP_NAME = 'CCS';

	private static List<Exception_Log__c> exceptionlogList {get;set;}

	public static void createErrorLog(String runninguserId, String className,String methodName,String exMsg, Exception exceptionOccured, 
                                            String debugLevel, String integrationPayload, String referenceInfo, Integer timer, String applicationName){
        
        processExceptionLog(runninguserId,className,methodName,exMsg,exceptionOccured,debugLevel,integrationPayload,referenceInfo,timer,applicationName);       
    }
    
    private static void processExceptionLog(String runninguserId, String className,String methodName,String exMsg, Exception exceptionOccured, 
                                            String debugLevel, String integrationPayload,String referenceInfo, Integer timer, String applicationName)
    {
        String referenceId = null;
        String logCode = null;
        
        if(applicationName == null){
            applicationName = EXCEPTION_LOGGER_DEFAULT_APP_NAME;
        }
        
        if(exceptionlogList == null){
            exceptionlogList = new List<Exception_Log__c>();
        }                
        
        if(exceptionOccured != null && exceptionOccured.getTypeName() == 'System.DmlException'){
            referenceId = exceptionOccured.getDmlId(0);
            logCode = string.valueOf(exceptionOccured.getDmlType(0));
        }
        
        //skip log insertion if exception occured in constructor, as @future and DML operations are not allowed in constructor. 
        if(exceptionOccured != null && className != methodName){
            exceptionlogList.add(createObjectData(runninguserId,className,methodName,exMsg,exceptionOccured.getTypeName(),exceptionOccured.getStackTraceString(),logCode,debugLevel,integrationPayload,referenceId,referenceInfo,timer,applicationName));
        }
                
        if(Limits.getLimitDMLStatements() < 1){
            System.debug('*********No Of DML Statement Limit Reached.********');        
        }      
        else{  
            try{ 
                if(!Trigger.isExecuting){
                    // In case it is not invoked from trigger, make asyncronous call and create Exception Record.
                    if(!System.isFuture() && !System.isBatch() && Limits.getFutureCalls() < 1){
                        //skip log insertion if exception occured in constructor, as @future and DML operations are not allowed in constructor. 
                        if(className != methodName){
                            insertExceptionInFuture(runninguserId,className,methodName,exMsg,exceptionOccured.getTypeName(),exceptionOccured.getStackTraceString(),logCode,debugLevel,integrationPayload,referenceId,referenceInfo,timer,applicationName);
                        }
                    }
                    else{
                        //skip log insertion if exception occured in constructor, as DML operations are not allowed in constructor. 
                        if(className != methodName){
                            List<Exception_Log__c> exceptionList = new List<Exception_Log__c>{ createObjectData(runninguserId,className,methodName,exMsg,exceptionOccured.getTypeName(),exceptionOccured.getStackTraceString(),logCode,debugLevel,integrationPayload,referenceId,referenceInfo,timer,applicationName)};
                            insert exceptionList;
                        }                   
                    }
                }
            }
            catch(exception ex){
                System.debug('*********Exception in Logger Class ********'+ex.getMessage());
                insert exceptionlogList;
            }              
        }
    }
    
    @future
    public static void insertExceptionInFuture(String runninguserId, String className,String methodName,String exMsg, String execptionType, String stackTrace, String logCode,  
                                            String debugLevel, String integrationPayload, String referenceId, String referenceInfo, Integer timer, String applicationName)
    {
        List<Exception_Log__c> exceptionList = new List<Exception_Log__c>{ createObjectData(runninguserId,className,methodName,exMsg,execptionType,stackTrace,logCode,debugLevel,integrationPayload,referenceId,referenceInfo,timer,applicationName)};
        insert exceptionList;
    }
    
    private static Exception_Log__c createObjectData(String runninguserId, String className,String methodName,String exMsg, String exceptionType, String stackTrace, String logCode, 
                                            String debugLevel, String integrationPayload, String referenceId, String referenceInfo, Integer timer, String applicationName)
    {
        Exception_Log__c exceptionLog = new Exception_Log__c();
        exceptionLog.Running_User__c = runninguserId;
        exceptionLog.Class_Name__c = className;
        exceptionLog.Method_Name__c = methodName;
        exceptionLog.Exception_Message__c = exMsg;            
        exceptionLog.Exception_Type__c= exceptionType;
        exceptionLog.StackTrace_Message__c = stackTrace;
        exceptionLog.LogCode__c = logCode;
        exceptionLog.DebugLevel__c = debugLevel;
        exceptionLog.IntegrationPayload__c = integrationPayload;
        exceptionLog.ReferenceId__c = referenceId;
        exceptionLog.ReferenceInfo__c = referenceInfo;
        exceptionLog.Timer__c = timer;
        exceptionLog.Application_Name__c = applicationName;
        return exceptionLog;
    }
}