({
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
	navigateTo : function(component, event) {
        var componentId = event.getSource().getLocalId();
        var urlValue = component.get('v.' + componentId + 'URL');
        var userId = component.get('v.currentUser').Id;
        var urlEvent = $A.get("e.force:navigateToURL");
        if(componentId==='logout') {
            window.location.replace(urlValue);
        } else {
            urlValue = urlValue.replace(':userId', userId);
            urlEvent.setParams({
              "url": urlValue
            });
            urlEvent.fire();
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