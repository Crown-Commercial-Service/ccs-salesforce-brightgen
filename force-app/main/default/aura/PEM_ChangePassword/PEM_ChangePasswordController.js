({
    onPasswordChange: function(component, event, helper) {
        var _newPassword = event.target.value;
        component.set('v.newPasswordValue', _newPassword);
        var newPassword = component.get('v.newPasswordValue');
        var matchAll = true;
        if (component.get("v.passwordSettings.Minimum_Length__c") > newPassword.length) {
            component.set("v.passed8Characters", false);
            matchAll = false;
        } else {
            component.set("v.passed8Characters", true);
        }
        if (component.get("v.passwordSettings.Contains_Special_Character__c") && new RegExp("[!@#$%^&*(){}[\]<>?/|.:;_-]").test(newPassword) === false) {
            component.set("v.passed1SpecialCharacter", false);
            matchAll = false;
        } else {
            component.set("v.passed1SpecialCharacter", true);
        }
        if (component.get("v.passwordSettings.Contains_Uppercase_Letter__c") && new RegExp("[A-Z]").test(newPassword) === false) {
            component.set("v.passed1Capital", false);
            matchAll = false;
        } else {
            component.set("v.passed1Capital", true);
        }
        if (component.get("v.passwordSettings.Contains_Number__c") && new RegExp("\d").test(newPassword) === false) {
            component.set("v.passed1Number", false);
            matchAll = false;
        } else {
            component.set("v.passed1Number", true);
        }
        if (component.get("v.passwordSettings.Contains_Letter__c") && new RegExp("[a-z]").test(newPassword) === false) {
            component.set("v.passed1Letter", false);
            matchAll = false;
        } else {
            component.set("v.passed1Letter", true);
        }
		component.set('v.validNewPassword', matchAll);
        if (newPassword === ''){
            component.set("v.newPasswordStatus", '');
        } else if ( matchAll ) {
            component.set("v.newPasswordStatus", 'Good');
        } else {
            component.set("v.newPasswordStatus", 'Too weak');
        }
        helper.checkConfirmPassword( component, newPassword, component.get("v.confirmPasswordValue") );
    },
    onConfirmPasswordChange: function(component, event, helper) {
		var _confirmPassword = event.target.value;
        component.set('v.confirmPasswordValue', _confirmPassword);
        var newPassword = component.get('v.newPasswordValue');
        helper.checkConfirmPassword( component, newPassword, _confirmPassword );
    },
    onPasswordSubmit: function(component, event, helper) {
        helper.onPasswordSubmit(component);
    },
    onPassModalCancel: function() {
        var closeEvent = $A.get("e.c:PEM_ModalClose");
        closeEvent.fire();
    }
})