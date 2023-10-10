({
  handleSelfRegister: function(component){
    this.clearErrorMessages(component);
    var isFirstNameValid = this.validateFirstName(component);
    var isLastNameValid = this.validateLastName(component);
    var isEmailValid = this.validateEmail(component);
    if(isFirstNameValid && isLastNameValid && isEmailValid){
      this.selfRegister(component);
    }
  },
  selfRegister: function (component) {
    var action = component.get("c.selfRegister");
    var formData = {
      firstname: component.find("firstName").get('v.value'),
      lastname: component.find("lastName").get('v.value'),
      email: component.find("email").get('v.value'),
      accountId: component.get("v.accountId"),
      regConfirmUrl: component.get("v.regConfirmUrl"),
      startUrl: null,
      includePassword: false,
      extraFields: null,
      confirmPassword: null,
      preValidated: false,
      contactNumber: null,
      companyName: null
    };
    action.setParams(formData);
    var _this = this;
    $A.util.removeClass(component.find("spinner"), "hideEl");  
    component.find("submitButton").set("v.disabled",true);  
    action.setCallback(this, function(status){
      $A.util.addClass(component.find("spinner"), "hideEl");  
      component.find("submitButton").set("v.disabled",false);
      if(_this.isBackendActionSucceed(status.getState())){
        var result = status.getReturnValue();
        if (result !== null) {
          if(result.hasOwnProperty('ResponseCode') && result.ResponseCode === 0){
            _this.addErrorMessage(component, _this.addLinkToMessage(component, result.Message));
          } else if(result.hasOwnProperty('ResponseCode') && result.ResponseCode === 1){
            component.set('v.formData', formData);
            _this.fireContinuationEvent(component);
            _this.renderSelect(component, result.AccountList);
          } else if(result.hasOwnProperty('ResponseCode') && result.ResponseCode === 2){
            component.set('v.formData', formData);
            _this.fireContinuationEvent(component);
            _this.renderSelect(component, []);
          }
        }
      } else {
        _this.displayError(component);
      }
    });
    $A.enqueueAction(action);
  },
  fireContinuationEvent: function(component) {
    component.getEvent('PublicRegistrationContinuation').fire();
  },
  renderSelect: function(component, selectOptions){
    component.set('v.selectOptions', selectOptions);
	  this.renderAddiction(component);
  },
  renderAddiction: function(component){
    component.set('v.isContinuation', true);
  },
  getValidators: function(){
    return {
      name: "^([a-zA-Z]|\-|\'|\é|\,|\\s)*$",
      email: "^[a-z0-9A-Z\\.\\_\\%\\+\\-\\é\\']+@[a-z0-9A-Z\\.\\_\\-\\é\\']+\.[a-zA-Z]{2,}$"
    };
  },
  validate: function(value, validator){
    return (new RegExp(validator, 'i')).test(value);
  },
  isEmpty: function(value){
    return value === '' || value === undefined || value === null;
  },
  addLinkToMessage: function(component, message){
    return message.indexOf('%login%') === -1 ? message : message.replace('%login%', '<a href="' + component.get('v.loginLink') + '">login</a>');
  },
  validateFirstName: function(component){
    var value = component.find('firstName').get('v.value');
    if(this.isEmpty(value)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_FirstNameRequired'));
      return false;
    } else if(!this.validate(value, this.getValidators().name)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_FirstNameInvalidChars'));
      return false;
    } else {
      return true;
    }
  },
  validateLastName: function(component){
    var value = component.find('lastName').get('v.value');
    if(this.isEmpty(value)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_LastNameRequired'));
      return false;
    } else if(!this.validate(value, this.getValidators().name)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_LastNameInvalidChars'));
      return false;
    } else {
      return true;
    }
  },
  validateEmail: function(component){
    var value = component.find('email').get('v.value');
    if(this.isEmpty(value)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_EmailRequired'));
      return false;
    } else if(!this.validate(value, this.getValidators().email)){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_EmailAddressInvalid'));
      return false;
    } else {
      return true;
    }
  },
  validateOrganization: function(component){
    var el =  this.isOrganizationName(component) ? component.find('organizationName') : component.find('companySelect');
    var value = el.get('v.value');
    var isValid = !this.isEmpty(value);
    if(!isValid){
      this.addErrorMessage(component, $A.get('$Label.c.PEM_OrgRequired'));
    }
    return isValid;
  },
  isOther: function(component){
    return component.get('v.selectOtherLabel') === component.get('v.selectedOrganization');
  },
  isOrganizationName: function(component){
    var isSelectOption = component.get('v.selectOptions').length !== 0;
    return !isSelectOption || (isSelectOption && this.isOther(component));
  },
  finishRegistration: function(component){
    var action = component.get("c.selfRegister");
    var oldFormData = component.get('v.formData');
    var formData = this.getRegistrationFields(oldFormData);
    formData.accountId = !this.isOrganizationName(component) ? component.find('companySelect').get('v.value') : component.get('v.selectOtherLabel');
    formData.preValidated = true;
    formData.contactNumber = component.find('contactNumber').get('v.value');
    formData.companyName = this.isOrganizationName(component) ? component.find('organizationName').get('v.value') : null;

    action.setParams(formData);
    var _this = this;
    $A.util.removeClass(component.find("spinner"), "hideEl");  
    component.find("submitButtonFinish").set("v.disabled",true);  
    action.setCallback(this, function(status){
      $A.util.addClass(component.find("spinner"), "hideEl");  
      component.find("submitButtonFinish").set("v.disabled",false);   
      if(_this.isBackendActionSucceed(status.getState())){
        var result = status.getReturnValue();
        if (result !== null) {
          if(result.hasOwnProperty('ResponseCode') && result.ResponseCode === 0){
            var message = _this.addLinkToMessage(component, result.Message);
            _this.addErrorMessage(component, message);
          }
        }
      } else {
        _this.displayError(component);
      }
    });
    $A.enqueueAction(action);
  },
  handleFinishRegistration: function(component){
    this.clearErrorMessages(component);
    var isOrganizationValid = this.validateOrganization(component);
    if(isOrganizationValid){
      this.finishRegistration(component);
    }
  },
  getRegistrationFields: function(formData){
    if(formData !== undefined && formData !== null && typeof formData === 'object' && !Array.isArray(formData)){
      var fields = ['firstname', 'lastname', 'email', 'accountId',
                      'regConfirmUrl', 'startUrl', 'includePassword',
                      'extraFields', 'confirmPassword', 'preValidated',
                      'contactNumber', 'companyName'];
      var registrationFields = {};
      fields.forEach(function iterate(field){
        if(formData.hasOwnProperty(field)){
          registrationFields[field] = formData[field];
        }
      });
      return registrationFields;
    } else {
      return {};
    }
  },
  addErrorMessage: function(component, message){
    var messages = component.get('v.errorMessages');
    messages.push(message);
    component.set('v.errorMessages', messages);
  },
  clearErrorMessages: function(component){
    component.set('v.errorMessages', []);
  },
  displayError: function(component, message){
    var errorMessage = message || $A.get('$Label.c.PEM_GeneralErrorMessage');
    this.addErrorMessage(component, errorMessage);
  },
  isBackendActionSucceed: function(state){
    return state === 'SUCCESS';
  }
})