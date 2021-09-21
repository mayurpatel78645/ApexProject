public with sharing class CTLocationTriggerHandler {
    public static void beforeInsert(List<Location__c> newRecs){
        for(Location__c location : newRecs){
            location.Status__c = 'Green';
        }
    }

    public static void beforeUpdate(List<Location__c> newRecs, Map<Id, Location__c> oldRecsMap){
        for(Location__c location : newRecs){
            if(location.Status__c != oldRecsMap.get(location.Id).Status__c){
                location.Status_Update_Date__c = Date.today();
            }
        }
    }

    public static void afterUpdate(List<Location__c> newRecs, Map<Id, Location__c> oldRecsMap){
        Set<Id> statusChange = new Set<Id>();

        for(Location__c location : newRecs){
            if(oldRecsMap.get(location.Id).Status__c != 'Red' && location.Status__c == 'Red'){
                statusChange.add(location.Id);
            }
        }

        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationByLocationIds(statusChange);
        Set<Id> personIds = new Set<Id>();

        for(Location_Tracing__c trace : locationTraces){
            personIds.add(trace.Person__c);
        }

        List<Person__c> peopleToUpdate = new List<Person__c>();

        for(Id pId : personIds){
            peopleToUpdate.add(new Person__c(Id = pId, Health_Status__c = 'Yellow'));
        }

        if(peopleToUpdate.size() > 0){
            update peopleToUpdate;
        }
    }
}
