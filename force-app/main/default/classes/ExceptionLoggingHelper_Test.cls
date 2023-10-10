/*****************************************************************************************************************************
Name: ExceptionLoggingHelper

Purpose: Unit test for ExceptionLoggingHelper class

History
-------
VERSION AUTHOR                          DATE            DETAIL  FEATURES/CSR/TTP
1.0 -   pczechumski@salesforce.com      07/03/2016      INITIAL DEVELOPMENT
*******************************************************************************************************************************/

@isTest (seeAllData=false)
private class ExceptionLoggingHelper_Test {
	
	private static final String ERROR_MSG = 'Only Unit Test for Error Logging';
	private static final String CLASS_NAME = 'ExceptionLoggingHelper_Test';

	@isTest static void shouldGetAdditionalErrorLog() {
		// given
		Integer iErrorCount = [select count() from Exception_log__c where Class_Name__c = :CLASS_NAME];

		// when
		Test.startTest();
			try{
				insert new Account();
			}
			catch(DmlException ex){
				ExceptionLoggingHelper.createErrorLog(UserInfo.getUserId(), CLASS_NAME, 'shouldGetAdditionalErrorLog' ,
					ERROR_MSG, ex, 'Error', null, null, null, null);
			}
		Test.stopTest();

		// then
		System.assertEquals(iErrorCount + 1, [select count() from Exception_log__c where Class_Name__c = :CLASS_NAME], 'New message should be added');
	}
	
	@isTest static void shouldGetAdditionalErrorLogInFutureCall() {
		// given
		Integer iErrorCount = [select count() from Exception_log__c where Class_Name__c = :CLASS_NAME];

		// when
		Test.startTest();
			dontDivideBy0();
		Test.stopTest();

		// then
		System.assertEquals(iErrorCount + 1, [select count() from Exception_log__c where Class_Name__c = :CLASS_NAME], 'New message should be added');
	}

	@future
	public static void dontDivideBy0(){
		try{
				Integer iDivideBy0 = 1/0;
			}
			catch(MathException ex){
				ExceptionLoggingHelper.createErrorLog(UserInfo.getUserId(), CLASS_NAME, 'shouldGetAdditionalErrorLogInFutureCall' ,
					ERROR_MSG, ex, 'Error', null, null, null, null);
			}
	}
	
}