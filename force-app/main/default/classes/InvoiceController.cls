public with sharing class InvoiceController {

    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices(Id subscriptionId) {


        if (!Schema.sObjectType.Invoice__c.isAccessible()) {
            throw new AuraHandledException('Access denied to Invoice');
        }

        return [
            SELECT Id, External_Id__c, Amount__c, Status__c, Invoice_Date__c
            FROM Invoice__c
            WHERE Subscription__c = :subscriptionId
            WITH SECURITY_ENFORCED
            ORDER BY Invoice_Date__c DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Decimal getTotalPaid(Id subscriptionId) {


        if (!Schema.sObjectType.Invoice__c.isAccessible()) {
            throw new AuraHandledException('Access denied to Invoice');
        }

        AggregateResult result = [
            SELECT SUM(Amount__c) total
            FROM Invoice__c
            WHERE Subscription__c = :subscriptionId
            AND Status__c = 'Paid'
            WITH SECURITY_ENFORCED
        ];

        Decimal total = (Decimal) result.get('total');
        return total != null ? total : 0;
    }
}