/*  * Product name: showToastLight
    * Developed by Zahir Basith. Date: 31/11/2023
    * This component is used to show popup messages in lightning record/ home page
    * Properties of the popup window are configurable by the admin
*/

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
export default class MyComponent extends LightningElement {

    @api strTitle ='Attention!';
    @api strMessage ='Please add a supplier to the Supplier Awarded field.';
    @api strType = 'success';
    @api strDuration = '';
    @api strMode = '';
    
    connectedCallback(){
        this.showToast();
    }

        showToast() {
            const event = new ShowToastEvent({
                title: this.strTitle,
                duration: this.strDuration,
                message:
                    this.strMessage,
                key: 'info_alt',
                variant: this.strType,
                mode: this.strMode
            });
            this.dispatchEvent(event);

    }

  /*  This code is under development. This is for future enhancements
    userId = Id;
    isSystemAdministrator = false;

    @wire(getRecord, { recordId: Id, fields: [ProfileName] })
    userDetails({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            if (data.fields.Profile.value != null && data.fields.Profile.value.fields.Name.value=='System Administrator') {
                this.isSystemAdministrator = true;
            }
        }
    }*/

}