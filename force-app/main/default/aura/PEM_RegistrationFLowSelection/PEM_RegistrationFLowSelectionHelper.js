({
	createComponent : function(component, name, attributes) {
		$A.createComponent(name, attributes, function callback(newComponent, status, errorMessage){
			if(status === "SUCCESS") {
				var body = component.get('v.body');
				body = [];
				body.push(newComponent);
				component.set('v.body', body);
			}
		});
	},
	createPublicRegistration: function(component) {
		this.createComponent(component, 'c:PEM_SelfRegister', {
			accountId: component.get('v.public_accountId'),
			regConfirmUrl: component.get('v.public_regConfirmUrl'),
			firstnameLabel: component.get('v.public_firstnameLabel'),
			lastnameLabel: component.get('v.public_lastnameLabel'),
			emailLabel: component.get('v.public_emailLabel'),
			submitButtonLabel: component.get('v.public_submitButtonLabel'),
			contactNumberLabel: component.get('v.public_contactNumberLabel'),
			organizationNameLabel: component.get('v.public_organizationNameLabel'),
			organizationSelectLabel: component.get('v.public_organizationSelectLabel'),
			forgottenPasswordLink: component.get('v.public_forgottenPasswordLink'),
			forgottenPasswordLabel: component.get('v.public_forgottenPasswordLabel'),
			loginLink: component.get('v.public_loginLink'),
			loginLabel: component.get('v.public_loginLabel'),
			registrationDescription2: component.get('v.public_registrationDescription2'),
			registrationTitle2: component.get('v.public_registrationTitle2'),
			registrationDescription3: component.get('v.public_registrationDescription3'),
			selectOtherLabel: component.get('v.public_selectOtherLabel'),
			termsAndConditionsLink: component.get('v.public_termsAndConditionsLink'),
			termsAndConditionsLabel: component.get('v.public_termsAndConditionsLabel'),
			termsAndConditionsCheckboxLabel: component.get('v.public_termsAndConditionsCheckboxLabel')
		});
	},
	createPrivateRegistration: function(component){
		this.createComponent(component, 'c:PEM_PrivateRegistration', {
			description: component.get('v.private_description'),
			buttonLabel: component.get('v.private_buttonLabel'),
            buttonLink: component.get('v.private_link')
		});
	},
	select: function(component, event, dependentValue, renderComponent) {
		if (event.getParam('value')) {
			component.set(dependentValue, false);
			renderComponent.bind(this)(component);
		} else {
			component.set(dependentValue, true);
		}
	}
})