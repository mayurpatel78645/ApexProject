trigger CTPeopleTracing_Trigger on People_Tracing__c (before insert) {
  switch on Trigger.operationType {
    when BEFORE_INSERT {
      CTPeopleTracing_TriggerHandler.beforeInsert(Trigger.new);
    }
  }
}