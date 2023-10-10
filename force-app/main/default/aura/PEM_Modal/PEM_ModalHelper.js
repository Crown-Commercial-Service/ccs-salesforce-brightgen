({
	addContent : function(component) {
		var content = component.get('v.contentComponent');
        var params 	= {};
        var modalParams = component.get('v.params');
        for (var key in modalParams) {
            if (modalParams.hasOwnProperty(key)) {
            	params[key] = modalParams[key];
            }
        }
        $A.createComponent(
            content,
            params,
            function(childCmp){
                //Add component to modal body
                if (component.isValid()) {
                    var body = component.get("v.body");
                    body.push(childCmp);
                    component.set("v.body", body);
                }
                var modal = component.find('modal');
                setTimeout($A.getCallback(function() {
                    $A.util.addClass(modal, 'modal-in');
                    // Block overflow on mobile devices
                    var offset = parseInt(window.document.body.scrollTop, 10) * -1;
                    window.document.body.style.top = offset + 'px';
                    $A.util.addClass(window.document.body, 'modal-open');
                    component.set('v.showSpinner', false);
                }));
            }
        );
	}
})