({
  doInit: function(component, event, helper){
    helper.getUserData(component);
  },
  navigateTo : function(component, event, helper) {
    helper.navigateTo(component, event);
  }
})