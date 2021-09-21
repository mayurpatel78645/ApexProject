public with sharing class CTPeopleTracing_TriggerHandler {
    public static void beforeInsert(List<People_Tracing__c> newRecs){
        List<People_Tracing__c> duplicates = CTPeopleTracingController.checkDuplicates(newRecs);

        for(People_Tracing__c trace : duplicates){
            trace.addError('Duplicate Record found. Person 1:'+ trace.Person_1__c+ 'Person 2:'+ trace.Person_2__c);
        }
    }
}
