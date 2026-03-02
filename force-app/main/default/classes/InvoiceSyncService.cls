public with sharing class InvoiceSyncService {


    @AuraEnabled
    public static void syncInvoices(Id subscriptionId) {
        System.debug('syncInvoices called for subscriptionId: ' + subscriptionId);
        Subscription__c sub = [SELECT Id, External_Id__c FROM Subscription__c WHERE Id = :subscriptionId LIMIT 1];

        if(String.isBlank(sub.External_Id__c)) {
            System.debug('Subscription has no External_Id__c.');
            return;
        }
        
        System.debug('Subscription External_Id__c: ' + sub.External_Id__c);

        
       Invoice_Config__mdt config = Invoice_Config__mdt.getInstance('Default');

        String endpoint = config.Base_Url__c 
            + '?subscriptionExternalId=' 
            + sub.External_Id__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);

            System.debug('API Response Status Code: ' + res.getStatusCode());

            if(res.getStatusCode() != 200){
                System.debug('API returned an error status : ' + res.getStatusCode());
                System.debug('API Response Body: ' + res.getBody()); 
                return;
            }

            List<Object> invoices = (List<Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Invoices received from API: ' + invoices.size());

            List<Invoice__c> toUpsert = new List<Invoice__c>();

            for(Object o : invoices){
                Map<String,Object> inv = (Map<String,Object>) o;

                System.debug('Invoice Data: ' + inv);

                Decimal amount;
                if(inv.get('amount') != null){
                    amount = Decimal.valueOf(String.valueOf(inv.get('amount')));
                }

                Date invoiceDate;
                if(inv.get('date') != null){
                    invoiceDate = Date.valueOf(String.valueOf(inv.get('date')));
                }

                toUpsert.add(new Invoice__c(
                    External_Id__c = (String) inv.get('id'),
                    Subscription__c = sub.Id,
                    Amount__c = amount,
                    Status__c = ((String)inv.get('status')).capitalize(),
                    Invoice_Date__c = invoiceDate
                ));
            }

            if(!toUpsert.isEmpty()){
                System.debug('Upserting invoices: ' + toUpsert.size());
                upsert toUpsert External_Id__c;
            } else {
                System.debug('No invoices to upsert.');
            }

        } catch(Exception e) {
            System.debug('Error during Invoice upsert: ' + e.getMessage());
        }
    }
}