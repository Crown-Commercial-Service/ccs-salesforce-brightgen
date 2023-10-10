({
	toggleProfileMenu : function(component, value) {
		component.set('v.isProfileRendered', value === null || value === undefined ? true : value);
	},
	getUserData : function(component) {
        var _this = this;
        try {
            _this.callServer(component, "c.getUserWrapper", function(response) {
                component.set("v.currentUser", response.user);
                component.set("v.SSOOnly", response.SSOOnly);
            });
        } catch(e) {
            _this.displayError(component);
        }
    },
    displayError: function(component, message){
      var errorMessage = message || $A.get('$Label.c.PEM_GeneralErrorMessage');
      this.addErrorMessage(component, errorMessage);
    },
    addErrorMessage: function(component, message){
      var messages = component.get('v.errorMessages');
      messages.push(message);
      component.set('v.errorMessages', messages);
  	}
})