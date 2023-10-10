({
	// Navigation to the homepage via the logo icon
    goHome : function(component, event, helper) {
        event.preventDefault();
        document.getElementById("beta-banner-link").focus();
        document.getElementById("beta-banner-link").blur();
        var address = "/";
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": address,
          "isredirect" :false
        });
        urlEvent.fire();
    },
})