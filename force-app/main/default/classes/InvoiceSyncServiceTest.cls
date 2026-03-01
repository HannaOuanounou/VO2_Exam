@IsTest
private class InvoiceSyncServiceTest {




    @IsTest static void testSyncInvoices() {

        Account acc = new Account(Name='Test Account');
        insert acc;

        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today(),
            External_Id__c = 'sub-001'
        );
        insert sub;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new InvoiceCalloutMock());
        InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        Integer countInv = [SELECT COUNT() FROM Invoice__c WHERE Subscription__c = :sub.Id];
        System.assertEquals(1, countInv, 'One invoice should be created');

        Invoice__c inv = [SELECT External_Id__c, Amount__c, Status__c, Invoice_Date__c 
                          FROM Invoice__c WHERE Subscription__c = :sub.Id LIMIT 1];
        System.assertEquals('inv-001', inv.External_Id__c);
        System.assertEquals(49, inv.Amount__c);
        System.assertEquals('Paid', inv.Status__c);
        System.assertEquals(Date.newInstance(2026,1,10), inv.Invoice_Date__c);
    }
public class InvoiceCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('[{"id":"inv-001","amount":49,"status":"paid","date":"2026-01-10"}]');
        return res;
    }
}

}