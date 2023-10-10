({
	doInit : function(component, event, helper) {
        var action = component.get('c.getCurrentData');
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.customText', result);
            }
        });
        $A.enqueueAction(action);
    },
})