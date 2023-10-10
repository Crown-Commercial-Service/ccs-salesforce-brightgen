({
	setUserData : function(component) {
        $A.util.removeClass(component.find("spinner"), "slds-hide");
		var action = component.get("c.getUser");
        action.setCallback( this, function(response) {
           	var state = response.getState();
            $A.util.addClass(component.find("spinner"), "slds-hide");
            if( component.isValid() && state === 'SUCCESS' ) {
                component.set("v.currentUser", response.getReturnValue());
            } else {
                component.set("v.hasError", true);
                component.set("v.errorMessage", response.getError());
            }
        });
        $A.enqueueAction( action );
	},
    getUserLanguageValues : function(component) {
        var action = component.get("c.getUserLanguageValues");
        var inputsel = component.find("languageLocaleKey");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0; i< a.getReturnValue().length; i += 1){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i].label, value: a.getReturnValue()[i].value});
            }
            inputsel.set("v.options", opts);
        });
        $A.enqueueAction(action);
	},
    getUserLocaleValues : function(component) {
        var action = component.get("c.getUserLocaleValues");
        var inputsel = component.find("localeSidKey");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0; i< a.getReturnValue().length; i += 1){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i].label, value: a.getReturnValue()[i].value});
            }
            inputsel.set("v.options", opts);
        });
        $A.enqueueAction(action);
	},
    getUserTimezoneValues : function(component) {
        var action = component.get("c.getUserTimezoneValues");
        var inputsel = component.find("timeZoneSidKey");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0; i< a.getReturnValue().length; i += 1){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i].label, value: a.getReturnValue()[i].value});
            }
            inputsel.set("v.options", opts);
        });
        $A.enqueueAction(action);
	},
    updateUserData : function(component) {
        $A.util.removeClass(component.find("spinner"), "slds-hide");
        var action = component.get("c.updateUserInfo");
	    action.setParams({
            user: component.get('v.copyUser')
        });
        component.set("v.hasError", false);
        action.setCallback( this, function(response) {
            $A.util.addClass(component.find("spinner"), "slds-hide");
            var state = response.getState();
            if( component.isValid() && state === 'SUCCESS' ) {
                component.set("v.currentUser", response.getReturnValue());
                component.set('v.profileMode', 'view');
            } else {
                component.set("v.hasError", true);
                component.set("v.errorMessage", response.getError());
            }
        });
        $A.enqueueAction( action );
    }
})