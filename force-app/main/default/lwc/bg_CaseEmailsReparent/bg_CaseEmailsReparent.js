import { api, LightningElement, wire } from "lwc";
import { refreshApex } from '@salesforce/apex';
import getEmails from "@salesforce/apex/bg_CaseEmailsReparent_Controller.getEmails";
import transferEmails from "@salesforce/apex/bg_CaseEmailsReparent_Controller.transferEmails";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Success_msg from '@salesforce/label/c.Success_msg';

const columns = [
    //{ label: "Id", fieldName: "Id"},
    { label: "Status", fieldName: "Status"},
    { label: "Moved?", fieldName: "Was_Reparented__c", type: "boolean"},
    { label: "Incoming?", fieldName: "Incoming", type: "boolean"},
    { label: "Subject", fieldName: "Subject"},
    { label: "From", fieldName: "FromAddress"},
    { label: "Date", fieldName: "MessageDate", type: "date"}
];

export default class Bg_CaseEmailsReparent extends LightningElement 
{
    error;
    columns = columns;
    targCaseId = '';
    hasEmails = false;
    emails;
    selectedRows;
    reparentSpinner = false;
    reparentResult;

    @api recordId;

    //Get records list.
    @wire(getEmails, {caseId: "$recordId"}) 
    setEmails(emailsResult)
    {
        this.emails = emailsResult;
        
        if(typeof this.emails.data !== 'undefined' && this.emails.data.length > 0)
        {
            this.hasEmails = true;
        }
        else
        {
            this.hasEmails = false;
        }
    }

    //Process email transfer in Apex and run resulting list refresh and actions.
    reparentEmails()
    {
        var emails = this.template.querySelector('lightning-datatable');
        var selected = emails.getSelectedRows();
        const successToast = new ShowToastEvent({title: 'Success', message: 'Emails transferred successfully', variant: 'success'});
        const errorToast = new ShowToastEvent({title: 'Error', message: 'An error occurred while trying to transfer Emails: ' + this.reparentResult, variant: 'error'});

        this.reparentSpinner = true;
        transferEmails({originCaseId: this.recordId, targetCaseId: this.targCaseId, emailMessages: selected})
        .then(result => 
            {
                this.reparentResult = result;
                console.log('JAG ' + this.reparentResult);
                console.log('JAG ' + Success_msg);
                this.reparentSpinner = false;
                if(this.reparentResult == Success_msg)
                {
                    this.dispatchEvent(successToast);
                    refreshApex(this.emails);
                    this.selectedRows = [];
                }
                else
                {
                    this.dispatchEvent(errorToast);
                }
            });
    }

    //Set target case.
    targetCaseSelected(event)
    {
        this.targCaseId = event.detail.value[0];
    }
}