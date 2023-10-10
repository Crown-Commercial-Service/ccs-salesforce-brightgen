({
	accept : function(component) {
		component.getEvent('PEM_AcceptTermsAndConditions').setParams({
			isAccepted: component.find('checkbox').get('v.value')
		}).fire();
	}
})