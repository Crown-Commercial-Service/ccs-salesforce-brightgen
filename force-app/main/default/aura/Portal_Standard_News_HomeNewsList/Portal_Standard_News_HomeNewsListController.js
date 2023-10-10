({
   doInit: function (component, event, helper) {
              
       var newsArticleAction = component.get("c.getHomeNewsArticles");

        // Add callback behavior for when response is received
        newsArticleAction.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.newsArticles", response.getReturnValue());
            } else {
                console.log("Failed with state: " + state);
            }
        });

        // Send actions off to be executed
       	$A.enqueueAction(newsArticleAction);
       
    }
})