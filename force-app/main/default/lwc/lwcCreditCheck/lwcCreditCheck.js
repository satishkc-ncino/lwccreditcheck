/**
 * @description       : 
 * @author            : Satish Chandrashekar
 * @group             : 
 * @last modified on  : 04-18-2021
 * @last modified by  : Satish Chandrashekar
 * Modifications Log 
 * Ver   Date         Author                 Modification
 * 1.0   04-18-2021   Satish Chandrashekar   Initial Version
**/
import { LightningElement, wire, api, track } from 'lwc';
import creditcontroller from '@salesforce/apex/CreditController.creditController';
import getcontacts from '@salesforce/apex/CreditController.getContacts';
import { getRecord } from 'lightning/uiRecordApi';

/*const actions = [
    {label: 'Check Credit', name:'check_credit'},
];*/

const columns = [
    {label: 'Entity Name', fieldName: 'linkName', type: 'url', iconName: 'standard:account',
    cellAttributes: 
        { class: 'slds-text-color_default slds-text-title'}, 
    typeAttributes:
        { label: { fieldName: 'Associated_Relationship__c' }, target: '_blank'}},
    {label: 'Entity Type', fieldName: 'LLC_BI__Borrower_Type__c', type: 'text', sortable: false, iconName: 'standard:canvas',
    cellAttributes: 
        { class: 'slds-text-color_weak slds-text-title'}
    },
    {label: 'Credit Status', fieldname: 'LLC_BI__Account__r.LLC_BI__Credit_Stats__c', type: 'text', sortable:false,
    cellAttributes: 
    { class: 'slds-text-color_weak slds-text-title'}
    }
    //{label: 'Action', type: 'button', initialWidth: 135, typeAttributes: { label: 'Check Credit', name: 'check_credit', title: 'Click to Initate Credit Report Request'}},
];

export default class LwcCreditCheck  extends LightningElement { 
    @api recordId;
    /*@track _entities;
    get entities() {
        return this._entities;
    }
    set entities(value) {
        this._entities = value;
    }*/
    @track columns = columns;
    @track srowt;
    @track rowt;
    @track datatrue;
    @track srows = [];
    @track entlist = [];
    error;
    
    /* Traditional wire method with no URL link
    @wire(getcontacts, {oanid: '$recordId'})
        wiredRecordMethod({error, data}){
            if(data){
                this.entlist = data;
                this.error = undefined;
                this.rowt = data.length;
            }
            else if(error){
                 this.error = error;
                 this.entlist = undefined;   
            }
        } */
    
    @wire(getcontacts, {loanid: '$recordId'})
    wiredRecords(results){
        const {data, error} = results;
        if(data){
            let linkName;
            this.entlist = data.map (row => {
                linkName = `/${row.Id}`;
                return {...row, linkName}
            })
            this.error = error;
            this.rowt = data.length;
            this.datatrue = TRUE;
        }
        else if(error){
            this.error = error;
            this.entlist = [];
            this.datatrue = FALSE;
        }
    }
        

    handleAction(event){
        const rows = this.srows;
        var lid = this.recordId;
        alert(lid); 
        if(rows.length >0){
            for(let i=0; i<rows.length; i++){
                alert("Account Id: " + rows[i].LLC_BI__Account__c);
                alert("Borrower Type: "+ rows[i].LLC_BI__Borrower_Type__c);
                alert("Loan Id: "+ lid);
                let accid = rows[i].LLC_BI__Account__c;
                let entype = rows[i].LLC_BI__Borrower_Type__c;
                let loanid = lid;
                var callcontroller = creditcontroller({
                    accid: accid,
                    entype: entype,
                    loanid: loanid
                });
                alert('Controller Invoked');    
            }
        }

    }

    handleRowSelect(event){
        const selectedRows = event.detail.selectedRows;
        this.srowt = selectedRows.length;
        this.srows = selectedRows;
    }
}