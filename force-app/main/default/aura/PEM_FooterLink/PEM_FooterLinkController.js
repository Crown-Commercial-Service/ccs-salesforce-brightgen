({
	navigate : function(component, event, helper) {
		var link = component.get('v.link');
		if (helper.isExternalLink(link, window.location)){
			window.open(link);
		} else {
			window.location.href = helper.createRelativeLink(link, window.location);
		}
	}
})