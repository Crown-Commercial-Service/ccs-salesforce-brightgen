({
    doInit: function(component, event, helper){
        helper.getUserData(component);
    },
    handleToggleProfileSection : function(component, event, helper) {
        helper.toggleProfileMenu(component, event.getParam('isRendered'));
    },
    showSpinner : function (component) {
        var m = component.find('modalspinner');
        $A.util.removeClass(m, "slds-hide");
    },
    hideSpinner : function (component) {
        var m = component.find('modalspinner');
        $A.util.addClass(m, "slds-hide");
    }
})