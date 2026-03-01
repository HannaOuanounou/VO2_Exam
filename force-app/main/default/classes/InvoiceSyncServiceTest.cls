@IsTest
private class InvoiceSyncServiceTest {


    @TestSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Subscription__c sub = new Subscription__c(
            Name__c = 'Sub Active 1',
            Account__c = acc.Id,
            Status__c = 'Active',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(1),
            Monthly_Amount__c = 100,
            External_Id__c = 'sub-001'
        );
        insert sub;
    }

    
    @IsTest
    static void testSyncInvoices_success() {

        Subscription__c sub = [
            SELECT Id , Name__c
            FROM Subscription__c 
            WHERE External_Id__c = 'sub-001' 
            LIMIT 1
        ];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new InvoiceCalloutMock());
        InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        List<Invoice__c> invoices = [
            SELECT External_Id__c, Amount__c, Status__c, Invoice_Date__c
            FROM Invoice__c
            WHERE Subscription__c = :sub.Id
        ];

        System.assertEquals(1, invoices.size());
        System.assertEquals('inv-001', invoices[0].External_Id__c);
        System.assertEquals(49, invoices[0].Amount__c);
        System.assertEquals('Paid', invoices[0].Status__c);
        System.assertEquals(Date.newInstance(2026,1,10), invoices[0].Invoice_Date__c);
    }

  
    private class InvoiceCalloutMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(
                '[{"id":"inv-001","amount":49,"status":"paid","date":"2026-01-10"}]'
            );
            return res;
        }
    }
}