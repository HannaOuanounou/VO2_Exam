import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import SUBSCRIPTION_CHANNEL from '@salesforce/messageChannel/SubscriptionMessageChannel__c';

import getInvoices from '@salesforce/apex/InvoiceController.getInvoices';
import getTotalPaid from '@salesforce/apex/InvoiceController.getTotalPaid';
import syncInvoices from '@salesforce/apex/InvoiceController.syncInvoices';

export default class InvoiceViewer extends LightningElement {

    invoices;
    totalPaid = 0;
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
        console.log('Message received:', message); 
        if (!subId) return;

        this.subscriptionId = subId;
        console.log('Subscription ID received: ' + this.subscriptionId);
        this.loadInvoices();
    }

    

   async loadInvoices() {
    if (!this.subscriptionId) return;

    console.log('Loading invoices for subscriptionId: ', this.subscriptionId); 

    this.loading = true;
    this.error = undefined;

    try {
        const [invoices, totalPaid] = await Promise.all([
            syncInvoices({ subscriptionId: this.subscriptionId }),
            getTotalPaid({ subscriptionId: this.subscriptionId })
        ]);
        this.invoices = invoices;
        this.totalPaid = totalPaid || 0;
        console.log('Invoices loaded:', this.invoices);  
    } catch (err) {
        this.error = this.getErrorMessage(err);
        this.invoices = [];
        this.totalPaid = 0;
        console.error('Error loading invoices:', err);  
    } finally {
        this.loading = false;
    }
}

    getErrorMessage(err) {
        if (err && err.body && err.body.message) {
            return err.body.message;
        }
        return 'An unknown error occurred';
    }

    get hasInvoices() {
        return this.invoices && this.invoices.length > 0;
    }

    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }
}