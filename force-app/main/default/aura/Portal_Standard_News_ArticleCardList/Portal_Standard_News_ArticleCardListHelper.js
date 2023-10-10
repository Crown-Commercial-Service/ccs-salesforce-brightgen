({
   getNewsArticles: function(component, page) {
 
      // create a server side action. 
      var action = component.get("c.fetchNewsArticles");
      // set the parameters to method 
      action.setParams({
         "pageNumber": page
      });
      // set a call back   
      action.setCallback(this, function(a) {
         // store the response return value (wrapper class insatance)  
         var result = a.getReturnValue();

         // set the component attributes value with wrapper class properties.   
 
         component.set("v.newsArticles", result.newsArticles);
         component.set("v.page", result.page);
         component.set("v.total", result.total);
         // added a + 1 here to account for offsetting top result
         component.set("v.pages", Math.ceil(result.total / (6 + 1)));
 
      });
      // enqueue the action 
      $A.enqueueAction(action);
   }
})