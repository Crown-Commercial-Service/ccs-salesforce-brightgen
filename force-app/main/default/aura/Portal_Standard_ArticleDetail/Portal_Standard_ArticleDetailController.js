({
    // Try to get help article, if no luck, return news article.
    doInit: function (component, event, helper) {

        // Get help article
        var getArticle = component.get("c.getHelpArticle");

        getArticle.setParams({
            recordId: component.get("v.recordId")
        });

        // Add callback behavior for when response is received
        getArticle.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.helpArticle", response.getReturnValue());
                
                // Set title
                var newTitle = response.getReturnValue().Title;
                
                if (document.title != newTitle) {
                    document.title = newTitle;
                }
                
            } else {

            }
        });

        // Send action off to be executed
        $A.enqueueAction(getArticle);

        // If no result - then get news article
        var newsArticle = component.get("c.getNewsArticle");

        newsArticle.setParams({
            recordId: component.get("v.recordId")
        });

        // Add callback behavior for when response is received
        newsArticle.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.newsArticle", response.getReturnValue());
                
                // Set title
                var newTitle = response.getReturnValue().Title;
                
                if (document.title != newTitle) {
                    document.title = newTitle;
                }
                
                // NOW GET NEXT AND PREV
                
                // Next
                var nextNewsArticle = component.get("c.getNextNewsArticle");
                
                nextNewsArticle.setParams({
                    lastPublished: component.get("v.newsArticle.Publish_Date_For_Website__c")
                });
                   
                nextNewsArticle.setCallback(this, function (response) {

                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS") {                    
                        
                        component.set("v.nextNewsArticle", response.getReturnValue());
                    } else {
                        
                    }
                });
                
                $A.enqueueAction(nextNewsArticle);
                
                // Prev
                var previousNewsArticle = component.get("c.getPreviousNewsArticle");

                previousNewsArticle.setParams({
                    lastPublished: component.get("v.newsArticle.Publish_Date_For_Website__c")
                });
                   
                previousNewsArticle.setCallback(this, function (response) {

                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS") {
                        
                        component.set("v.previousNewsArticle", response.getReturnValue());
                    } else {
                        
                    }
                });
                
                $A.enqueueAction(previousNewsArticle);
                
            } else {

            }
        });

        // Send action off to be executed
        $A.enqueueAction(newsArticle);

    }
})