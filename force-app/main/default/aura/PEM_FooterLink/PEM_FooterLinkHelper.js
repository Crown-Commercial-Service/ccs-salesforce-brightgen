({
	createRelativeLink: function (link, location){
		var pathElements = location.pathname.split('/').filter(function(value){
			return value !== "" && value !== undefined && value !== null;
		});
		return location.origin + '/' + pathElements[0] + link
	},
	isExternalLink: function(link, location){
		return link.startsWith(location.origin) || link.startsWith(location.host) || !link.startsWith('/');
	}
})