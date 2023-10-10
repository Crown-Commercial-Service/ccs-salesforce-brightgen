({
    doInit: function(component, event, helper) {
        
        var actionArticle = component.get("c.getCardArticle");
        
        actionArticle.setParams({
            articleNumber : component.get("v.articleId")
    	});
        
        // Add callback behavior for when response is received
    	actionArticle.setCallback(this, function(response) {
        	var state = response.getState();
        	if (component.isValid() && state === "SUCCESS") {
       component.set("v.helpArticle", response.getReturnValue());
        	}
        	else {
            	console.log("Failed with state: " + state);
        	}
    	});
        
        // Send action off to be executed
    	$A.enqueueAction(actionArticle);
        
    }
})