public class SubscriptionTriggerHandler {

    public void onBeforeInsert(List<Subscription__c> newList) {
        SubscriptionService.onlyOneActiveSubscriptionPerAccount(newList, null);
    }

    public void onBeforeUpdate(List<Subscription__c> newList, Map<Id, Subscription__c> oldMap) {
        SubscriptionService.onlyOneActiveSubscriptionPerAccount(newList, oldMap);
    }

    public void onAfterInsert(List<Subscription__c> newList) {
        SubscriptionService.updateStatuses(newList);
    }

    public void onAfterUpdate(List<Subscription__c> newList, Map<Id, Subscription__c> oldMap) {
        SubscriptionService.updateStatuses(newList);
    }
}