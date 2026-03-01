import { LightningElement, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import SUBSCRIPTION_CHANNEL 
    from '@salesforce/messageChannel/SubscriptionMessageChannel__c';

import getInvoices 
    from '@salesforce/apex/InvoiceController.getInvoices';
import getTotalPaid 
    from '@salesforce/apex/InvoiceController.getTotalPaid';

export default class InvoiceViewer extends LightningElement {

    invoices;
    totalPaid;
    error;
    subscriptionId;
    subscription;
    loading = false;

    columns = [
        { label: 'Date', fieldName: 'Invoice_Date__c', type: 'date' },
        { label: 'Amount', fieldName: 'Amount__c', type: 'currency' },
        { label: 'Status', fieldName: 'Status__c' }
    ];

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToChannel();
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                SUBSCRIPTION_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    handleMessage(message) {
        const subId = message?.subscriptionId;
        if (!subId) return;

        this.subscriptionId = subId;
        this.loadInvoices();
    }

    async loadInvoices() {
        if (!this.subscriptionId) return;

        this.loading = true;
        this.error = undefined;

        try {
            this.invoices = await getInvoices({ subscriptionId: this.subscriptionId });
            this.totalPaid = (await getTotalPaid({ subscriptionId: this.subscriptionId })) || 0;     
           } catch (err) {
            this.error = err?.body?.message || 'Unknown error';
            this.invoices = [];
            this.totalPaid = 0;
        } finally {
            this.loading = false;
        }
    }

    get hasInvoices() {
        return this.invoices && this.invoices.length > 0;
    }

    disconnectedCallback() {
        this.subscription = null;
    }
}