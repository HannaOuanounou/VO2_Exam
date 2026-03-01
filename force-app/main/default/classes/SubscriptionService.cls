public with sharing class SubscriptionService {
    
    private static Boolean isUpdating = false;
    public static void onlyOneActiveSubscriptionPerAccount(
        List<Subscription__c> newList,
    Map<Id, Subscription__c> oldMap
    ) {
        Set<Id> accountIds = new Set<Id>();
        for (Subscription__c sub : newList) {
            if (sub.Status__c == 'Active' && sub.Account__c != null) {
                accountIds.add(sub.Account__c);
            }
        }
        if (accountIds.isEmpty()) return;
        
        Map<Id, Subscription__c> activeByAccount = new Map<Id, Subscription__c>();
        for (Subscription__c sub : [
            SELECT Id, Account__c
            FROM Subscription__c
            WHERE Account__c IN :accountIds
            AND Status__c = 'Active'
            WITH SECURITY_ENFORCED
        ]) {
            activeByAccount.put(sub.Account__c, sub);
        }
        
        for (Subscription__c sub : newList) {
            if (sub.Status__c != 'Active') continue;
            if (!activeByAccount.containsKey(sub.Account__c)) continue;
            Subscription__c conflict = activeByAccount.get(sub.Account__c);
            if (oldMap != null && conflict.Id == sub.Id) continue;
            sub.addError('This Account already has an active subscription.');
        }
    }
    
    
    public static void updateStatuses(List<Subscription__c> subs) {
        if (isUpdating) return;
        isUpdating = true;
        try {
            List<Subscription__c> toUpdate = new List<Subscription__c>();
            Date today = Date.today();
            
            Set<Id> accountIds = new Set<Id>();
            for (Subscription__c sub : subs) {
                if (sub.Status__c == 'Draft' && sub.Start_Date__c == today) {
                    accountIds.add(sub.Account__c);
                }
            }
            
            Set<Id> accountsWithActive = new Set<Id>();
            if (!accountIds.isEmpty()) {
                for (Subscription__c sub : [
                    SELECT Account__c
                    FROM Subscription__c
                    WHERE Account__c IN :accountIds
                    AND Status__c = 'Active'
                    WITH SECURITY_ENFORCED
                ]) {
                    accountsWithActive.add(sub.Account__c);
                }
            }
            
            for (Subscription__c sub : subs) {
                String newStatus = null;
                
                if (sub.Status__c == 'Draft'
                    && sub.Start_Date__c == today
                && !accountsWithActive.contains(sub.Account__c)) {
                    newStatus = 'Active';
                } else if (sub.Status__c == 'Active' && sub.End_Date__c < today) {
                    newStatus = 'Expired';
                }
                
                if (newStatus != null) {
                    toUpdate.add(new Subscription__c(
                        Id = sub.Id,
                    Status__c = newStatus
                        ));
                }
            }
            
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } finally {
            isUpdating = false;
        }
    }
}