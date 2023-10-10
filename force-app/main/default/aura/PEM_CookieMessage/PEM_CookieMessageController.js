({
	doInit : function(component) {
        window.setTimeout(
            $A.getCallback(
            	function() {
					if (component.isValid()) {
        				component.set('v.seen_cookie_message', 'true');
                 	}
                }
                ), 500);
	}
})