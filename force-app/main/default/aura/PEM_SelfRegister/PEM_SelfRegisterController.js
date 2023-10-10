({
  handleSelfRegister: function (component, event, helper) {
    helper.handleSelfRegister(component, event, helper);
  },
  onKeyUp: function(component, event, helper){
    //checks for "enter" key
    if (event.getParam('keyCode') === 13) {
      if(component.get('v.isContinuation')){
        helper.handleFinishRegistration(component);
      } else {
        helper.handleSelfRegister(component);
      }
    }
  },
  validateFirstName: function(component, event, helper){
    helper.validateFirstName(component);
  },
  validateLastName: function(component, event, helper){
    helper.validateLastName(component);
  },
  validateEmail: function(component, event, helper){
    helper.validateEmail(component);
  },
  handleFinishRegistration: function(component, event, helper){
    helper.handleFinishRegistration(component);
  },
  onSelectChange: function(component, event){
    component.set('v.selectedOrganization', event.getSource().get('v.value'));
  },
  onTermsAndConditionsAccept: function(component, event) {
    component.set('v.isTermsAndConditionsAccepted', event.getParam('isAccepted'));
  }
})