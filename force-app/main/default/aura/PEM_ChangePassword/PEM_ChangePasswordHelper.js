({
    onPasswordSubmit: function(component) {
        var action = component.get("c.updateUserPassword");
        action.setParams({
            oldPassword: component.get('v.oldPasswordValue'),
            newPassword: component.get('v.newPasswordValue'),
            confirmPassword: component.get('v.confirmPasswordValue'),
            user: component.get('v.currentUser')
        });
        action.setCallback( this, function(response) {
           	var state = response.getState();
            if( component.isValid() && state === 'SUCCESS' ) {
                var respVal = response.getReturnValue();
                if (respVal.isSuccess) {
                    var values = respVal.values;
                    component.set("v.currentUser", values.user);
                    component.set("v.showPasswordError", false);
                    component.set("v.errorMsg", '');
                    component.set("v.showPasswordSuccess", true);
                    var successEvent = $A.get("e.c:PEM_UpdateParent");
                    successEvent.fire();
                } else {
                    component.set("v.showPasswordError", true);
                    component.set("v.errorMsg", respVal.message);
                    component.set("v.showPasswordSuccess", false);
                }
            } else {
                component.set("v.showPasswordError", true);
                component.set("v.errorMsg", response.getError());
                component.set("v.showPasswordSuccess", false);
            }
        });
        $A.enqueueAction( action );
    },
    checkConfirmPassword: function( component, newPassword, confirmPassword ) {
        if(newPassword === confirmPassword) {
            component.set("v.validConfirmPassword", true);
            component.set("v.confirmPasswordStatus", 'Match');
        } else if (confirmPassword === '') {
            component.set("v.confirmPasswordStatus", '');
            component.set("v.validConfirmPassword", false);
        } else {
            component.set("v.validConfirmPassword", false);
            component.set("v.confirmPasswordStatus", 'Passwords don\'t match');
        }
    }
})