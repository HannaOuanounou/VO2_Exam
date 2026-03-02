import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import SUBSCRIPTION_CHANNEL 
    from '@salesforce/messageChannel/SubscriptionMessageChannel__c';

import getSubscriptions 
    from '@salesforce/apex/SubscriptionController.getSubscriptions';
import getTotalMRR 
    from '@salesforce/apex/SubscriptionController.getTotalMRR';

export default class SubscriptionDashboard extends LightningElement {

    @api recordId;

    subscriptions;
    totalMRR;
    error;
    isLoading = true;

    @wire(MessageContext)
    messageContext;

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'MRR', fieldName: 'Monthly_Amount__c', type: 'currency' },
        {
            type: 'button',
            typeAttributes: {
                label: 'View Invoices',
                name: 'view',
                variant: 'brand'
            }
        }
    ];

    @wire(getSubscriptions, { accountId: '$recordId' })
    wiredSubscriptions({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.subscriptions = data;
            this.error = undefined;
        } else if (error) {
            this.error = error?.body?.message || 'An error occurred while fetching subscriptions';
            this.subscriptions = undefined;
        }
    }

    @wire(getTotalMRR, { accountId: '$recordId' })
    wiredTotalMRR({ data, error }) {
        if (data) {
            this.totalMRR = data; 
        } else if (error) {
            this.error = error?.body?.message || 'An error occurred while fetching total MRR';
            this.totalMRR = 0;
        }
    }

    get displayMRR() {
    return this.totalMRR != null ? this.totalMRR : 0;
}

    handleRowClick(event) {
        const rowId = event.detail?.row?.Id;
        if (!rowId) return;

        publish(this.messageContext, SUBSCRIPTION_CHANNEL, {
            subscriptionId: rowId
        });
        console.log('Subscription ID sent: ' + rowId);
    }

    get hasSubscriptions() {
        return this.subscriptions && this.subscriptions.length > 0;
    }
}