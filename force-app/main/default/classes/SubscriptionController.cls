public with sharing class SubscriptionController {

    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getSubscriptions(Id accountId) {

    
        // if (!Schema.sObjectType.Subscription__c.isAccessible()) {
        //     throw new AuraHandledException('Access denied to Subscription');
        // }

        return [
            SELECT Id, Name, Status__c, Monthly_Amount__c
            FROM Subscription__c
            WHERE Account__c = :accountId
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
    }

   @AuraEnabled(cacheable=true)
    public static Decimal getTotalMRR(Id accountId) {
        if (!Schema.sObjectType.Subscription__c.isAccessible()) {
            throw new AuraHandledException('Access denied to Subscription');
        }

        AggregateResult result = [
            SELECT SUM(Monthly_Amount__c) total
            FROM Subscription__c
            WHERE Account__c = :accountId
            AND Status__c = 'Active'
            WITH SECURITY_ENFORCED
        ];

        Decimal total = (Decimal) result.get('total');
        return total != null ? total : 0;
    }
    
    
}