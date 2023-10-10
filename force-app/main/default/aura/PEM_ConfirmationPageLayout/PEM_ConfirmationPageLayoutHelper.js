({
	hideprofileMenu : function() {
		$A.get('e.c:PEM_ToggleProfileSection').setParams({
			isRendered: false
		}).fire();
	}
})