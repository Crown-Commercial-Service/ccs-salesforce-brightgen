({
    doInit : function(component, event, helper) {
        var action = component.get('c.getCurrentData');
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.customText', result);
            }
        });
        $A.enqueueAction(action);
    },
    
    saveChanges : function (cmp, evt, hlp) {
        console.log('saveChanges...');
        
        var action = cmp.get("c.updateData"); 
        
        var textData = cmp.get("v.customText");  
        var tempDivElement = document.createElement("div");  
        tempDivElement.innerHTML = textData;  

		console.log(textData);
        action.setParams({
            "newText" : textData
        });
        console.log('set param');
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log("state - "+state);
            if(state === 'SUCCESS') {
                console.log("Home Page Message Updated");
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title" : "Success",
                    "message" : "Home Page Message Updated",
                    "type" : "success"
                });
                resultsToast.fire();
            }
            else {
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error Message: " + errors[0].message);
                    }else{
                        console.log("Unknown error");
                    }
                }
            }
        });       
        $A.enqueueAction(action);
    }, 
    
    
})