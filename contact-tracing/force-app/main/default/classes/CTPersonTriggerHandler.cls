public with sharing class CTPersonTriggerHandler {
    public static void beforeInsert(List<Person__c> newRecs){
        for (Person__c person : newRecs) {
            person.Health_Status__c = 'Green';
            person.Token__c = CTPersonController.getToken(person.Mobile__c);
        } 
    }

    public static void beforeUpdate(List<Person__c> newRecs, Map<Id, Person__c> oldRecsMap){
        for (Person__c person : newRecs) {
            if(person.Health_Status__c != oldRecsMap.get(person.Id).Health_Status__c){
                person.Status_Update_Date__c = Date.today();
            }
        }
    }

    public static void afterUpdate(List<Person__c> newRecs, Map<Id, Person__c> oldRecsMap){
        Set<Id> statusChange = new Set<Id>();
        Set<Id> redStatus = new Set<Id>();

        for(Person__c person : newRecs){
            if(person.Health_Status__c != oldRecsMap.get(person.Id).Health_Status__c){
                statusChange.add(person.Id);
            }

            if(person.Health_Status__c == 'Red' && oldRecsMap.get(person.Id).Health_Status__c != 'Red'){
                redStatus.add(person.Id);
            }
        }

        Set<Id> alreadyProcessed = new Set<Id>();
        alreadyProcessed.addAll(redStatus);
        Set<Id> orangeStatus = new Set<Id>();
        Set<Id> yellowStatus = new Set<Id>();

        List<Person__c> personToUpdate = new List<Person__c>();

        orangeStatus.addAll(CTPersonController.getCohabitants(redStatus, alreadyProcessed));
        Set<Id> primaryContacts = CTPersonController.getPrimaryContacts(redStatus, alreadyProcessed);
        orangeStatus.addAll(primaryContacts);
        yellowStatus.addAll(CTPersonController.getNeightbour(redStatus, alreadyProcessed));
        yellowStatus.addAll(CTPersonController.getSecondaryContacts(primaryContacts, alreadyProcessed));

        for(Id pId : orangeStatus){
            personToUpdate.add(new Person__c(Id = pId, Health_Status__c = 'Orange'));
        }

        for(Id pId : yellowStatus){
            personToUpdate.add(new Person__c(Id = pId, Health_Status__c = 'Yellow'));
        }

        if(personToUpdate.size() > 0){
            update personToUpdate;
        }

        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationByPersonIds(statusChange);

        if(locationTraces != null && locationTraces.size() > 0){
            Set<Id> locationIds = new Set<Id>();
            for(Location_Tracing__c trace : locationTraces){
                locationIds.add(trace.Location__c);
            }
            CTLocationController.updateRedScore(locationIds);
        }
    }
}
