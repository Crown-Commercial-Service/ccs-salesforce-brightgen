/*
 * bg_ContactSearchResultCarrier
 * Author: Conor Spark - Feb 2019
 * 
 * This is a class to hold the contact record that is being used in the 
 * bg_AddFrameworkLotSupplierContacts and bg_DeleteFrameworkLotSupplierContacts
 * pages. It allows the contact to be edited by either the parent VF page or
 * the bg_FrameworkLotSupplierContactSearch VF component and this carrier will
 * keep the contact updated in both places
 * 
 * */
public class bg_ContactSearchResultCarrier {
    
    public Contact contactRecord{get; set;}

}