({
   doInit: function (component, event, helper) {
              
       var frameworkAction = component.get("c.getFrameworkArticles");

        // Add callback behavior for when response is received
        frameworkAction.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.frameworkArticles", response.getReturnValue());
            } else {
                console.log("Failed with state: " + state);
            }
        });

        // Send actions off to be executed
       	$A.enqueueAction(frameworkAction);
       
    }
})