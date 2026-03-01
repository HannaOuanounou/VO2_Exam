trigger SubscriptionTrigger on Subscription__c (
    before insert,
    before update,
    after insert,
    after update
) {
    SubscriptionTriggerHandler handler = new SubscriptionTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) handler.onBeforeInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) handler.onAfterInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}