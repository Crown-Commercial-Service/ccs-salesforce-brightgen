trigger ProcurmentStagePreventDeletion on Procurement_Stage__c (before delete){
for(Procurement_Stage__c ps : trigger.old){
if(ps.name == 'ITT Live'){
ps.addError('You can not delete ITT Live from a Procurement');
}
}}