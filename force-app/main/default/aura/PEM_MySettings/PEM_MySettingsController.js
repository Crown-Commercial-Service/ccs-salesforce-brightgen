({
    doInit: function(component, event, helper) {
        helper.setUserData(component);
        helper.getUserLanguageValues(component);
        helper.getUserLocaleValues(component);
        helper.getUserTimezoneValues(component);
    },
	setViewMode : function(component) {
        component.set('v.currentUser', component.get('v.copyUser'));
        component.set('v.profileMode', 'view');
        component.set("v.hasError", false);
	},
	setEditMode : function(component) {
        component.set('v.copyUser', component.get('v.currentUser'));
        component.set('v.profileMode', 'edit');
	},
    cancel : function(component, event, helper) {
        helper.setUserData(component);
        component.set('v.profileMode', 'view');
        component.set("v.hasError", false);
    },
	updateUser : function(component, event, helper) {
        component.set('v.currentUser', component.get('v.copyUser'));
    	helper.updateUserData(component);
	},
	onDragOver: function(component, event) {
    	event.preventDefault();
    },
    onDragLeave: function(component, event) {
    	event.preventDefault();
    },
	onPasswordPress : function(component) {
        var params = component.get('v.params');
        params.currentUser = component.get('v.currentUser');
        component.set('v.params', params);
        component.set('v.showPassModal', true);
	},
    onModalCancel : function(component) {
        component.set('v.showPassModal', false);
	},
    onPasswordSuccess :  function(component) {
        component.set('v.passUpdated', true);
        component.set('v.showPassModal', false);
        setTimeout($A.getCallback(function() {
            component.set('v.passUpdated', false);
        }), 5000);
    }
})