public with sharing class InvoiceSyncService {

    public static void syncInvoices(Id subscriptionId) {
        Subscription__c sub = [SELECT Id, External_Id__c FROM Subscription__c WHERE Id = :subscriptionId LIMIT 1];

        if(String.isBlank(sub.External_Id__c)) {
            System.debug('Subscription has no External_Id__c.');
            return;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:InvoiceCallout/invoices?subscriptionExternalId=' 
                        + EncodingUtil.urlEncode(sub.External_Id__c,'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Content-Type','application/json');

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if(res.getStatusCode() != 200){
                System.debug('API returned an error status : ' + res.getStatusCode());
                return;
            }

            List<Object> invoices = (List<Object>) JSON.deserializeUntyped(res.getBody());
            List<Invoice__c> toUpsert = new List<Invoice__c>();

            for(Object o : invoices){
                Map<String,Object> inv = (Map<String,Object>) o;

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
                upsert toUpsert External_Id__c;
            }

        } catch(Exception e) {
            System.debug('Error during Invoice upsert: ' + e.getMessage());
        }
    }
}