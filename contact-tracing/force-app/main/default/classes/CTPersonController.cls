public with sharing class CTPersonController {
    
    public static String getToken(String phoneNumber){
        Blob targetPhone = Blob.valueOf(phoneNumber);
        Blob hash = Crypto.generateDigest('MD5', targetPhone);
        return EncodingUtil.base64Encode(hash);
    }

    public static List<Person__c> getRecentHealthChanges(){
        List<Person__c> persons = [SELECT Id, Token__c, OwnerId, Name, Mobile__c, Health_Status__c, Status_Update_Date__c FROM Person__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
        return persons;
    }

    public static List<Person__c> searchPeople(String searchTerm){
        searchTerm += '%';
        List<Person__c> persons = [SELECT Id, Token__c, OwnerId, Name, Mobile__c, Health_Status__c, Status_Update_Date__c FROM Person__c WHERE Name LIKE :searchTerm OR Mobile__c LIKE :searchTerm OR Token__c LIKE :searchTerm ORDER BY Status_Update_Date__c DESC];
        return persons;
    } 

    public static Person__c getPersonById(String personId){
        List<Person__c> person = [SELECT Id, Token__c, OwnerId, Name, Mobile__c, Health_Status__c, Status_Update_Date__c FROM Person__c WHERE Id=: personId];

        if(person != null && person.size() > 0){
            return person[0];
        }

        return null; 
    }

    public static Map<String, Integer> getHealthStatusCount(){
        Map<String, Integer> countByHealthStatus = new Map<String, Integer>();

        for(AggregateResult result : [SELECT Health_Status__c, COUNT(Id) total FROM Person__c GROUP BY Health_Status__c]){
            countByHealthStatus.put((String)result.get('Health_Status__c'), (Integer)result.get('total'));
        }
        return countByHealthStatus;
    }

    public static  Set<Id> getCohabitants(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Green', 'Orange'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
        FROM People_Tracing__c 
        WHERE (Person_1__c IN :personIds 
        OR Person_2__c IN :personIds) 
        AND Contact_Type__c = 'Cohabitant'
        AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)];

        Set<Id> cohabitants = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!personIds.contains(pt.Person_1__c)){
                cohabitants.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }

            if(!personIds.contains(pt.Person_2__c)){
                cohabitants.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }

        return cohabitants;
    }

    public static  Set<Id> getNeightbour(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
        FROM People_Tracing__c 
        WHERE (Person_1__c IN :personIds 
        OR Person_2__c IN :personIds) 
        AND Contact_Type__c = 'Neighbour'
        AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];

        Set<Id> neightbours = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                neightbours.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }

            if(!alreadyProcessed.contains(pt.Person_2__c)){
                neightbours.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }

        return neightbours;
    }

    public static  Set<Id> getPrimaryContacts(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
        FROM People_Tracing__c 
        WHERE (Person_1__c IN :personIds 
        OR Person_2__c IN :personIds) 
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10
        AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)];

        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                primaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }

            if(!alreadyProcessed.contains(pt.Person_2__c)){
                primaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }

        return primaryContacts;
    }

    public static  Set<Id> getSecondaryContacts(Set<Id> primaryContactIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
        FROM People_Tracing__c 
        WHERE (Person_1__c IN :primaryContactIds 
        OR Person_2__c IN :primaryContactIds) 
        AND Contact_Type__c = 'Other'
        AND Contact_Date__c = LAST_N_DAYS:10
        AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];

        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                secondaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }

            if(!alreadyProcessed.contains(pt.Person_2__c)){
                secondaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }

        return secondaryContacts;
    }
}
