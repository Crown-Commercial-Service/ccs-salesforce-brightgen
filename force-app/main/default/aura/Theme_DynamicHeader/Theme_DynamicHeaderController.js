({
    doInit: function (component, event, helper) {

        

        var actionArticle = component.get("c.getTopNewsArticle");

        // Add callback behavior for when response is received
        actionArticle.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.newsArticle", response.getReturnValue());
                
                // Check to see if there is a header image and set attribute value
                if(response.getReturnValue().Image_URL_Header__c){
                    component.set("v.hasHeaderArticle", true);
                } else {
                    component.set("v.hasHeaderArticle", false);
                }
                
            } else {
                console.log("Failed with state: " + state);
            }
        });

        // Send action off to be executed
        $A.enqueueAction(actionArticle);

    }
})