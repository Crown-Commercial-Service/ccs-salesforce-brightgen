({
    processChangeEvent : function(component, eventParams) {
        console.log('entering processChangeEvent');
        console.log('Components >>> '+component);
        if(eventParams.changeType === "CHANGED" && (('StageName' in eventParams.changedFields))) {
            var StageName = eventParams.changedFields.StageName.value;
            console.log ('changeType is: ' + eventParams.changeType);
            if(component.get("v.launchMode") == 'Modal' && (StageName == 'Closed Won')) {
                component.set('v.openModal',true);

                //Set input variable
                var inputVariable = [
                    {
                        name : "recordId",
                        type : "String",
                        value: component.get("v.recordId")
                    }
                ];

                var flow = component.find("flow");
                flow.startFlow(component.get("v.targetFlowName"), inputVariable); //added input variable

            } 
        }   
    } 
})