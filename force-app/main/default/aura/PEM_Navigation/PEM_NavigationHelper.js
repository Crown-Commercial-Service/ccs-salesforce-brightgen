({
	navigateTo : function(component, event) {
        var componentId = event.getSource().getLocalId();
        var urlComp = component.find(componentId);
        // Get the alt attribute
        var urlValue = urlComp.get("v.alt");
        // Set the selected tab for tracking and active CSS class
       	component.set("v.selectedItem", componentId);
        // Navigate to the tab url
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": urlValue
        });
        urlEvent.fire();
	}
})