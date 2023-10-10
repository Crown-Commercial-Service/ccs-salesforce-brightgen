({
	// Navigation to the homepage via the logo icon
    navigate : function(component, event, helper) {
        event.preventDefault();
        
        // For accessibility - reset focus
        document.getElementById("beta-banner-link").focus();
        document.getElementById("beta-banner-link").blur();
        var address = component.get("v.linkURL");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": address,
          "isredirect" : false
        });
        urlEvent.fire();
    },
})