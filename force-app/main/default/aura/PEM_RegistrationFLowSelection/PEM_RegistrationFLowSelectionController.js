({
	onSelectPublic : function(component, event, helper) {
		helper.select(component, event, 'v.isPrivate', helper.createPublicRegistration);
	},
	onSelectPrivate: function(component, event, helper){
		helper.select(component, event, 'v.isPublic', helper.createPrivateRegistration);
	},
	onRegistrationContinuation: function(component) {
		component.set('v.showSelects', false);
	}
})