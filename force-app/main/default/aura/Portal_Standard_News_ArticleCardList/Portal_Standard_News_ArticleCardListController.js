({
    doInit: function (component, event, helper) {
        // this function call on the component load first time     
        // get the page Number if it's not define, take 1 as default
        var page = component.get("v.page") || 1;
        // call the helper function   
        helper.getNewsArticles(component, page);

    },

    navigatePrev: function (component, event, helper) {
        // prevent default
        event.preventDefault();
        // this function call on click on the previous page button  
        var page = component.get("v.page") || 1;
        // get the previous button label  
        page = page - 1;
        // call the helper function
        helper.getNewsArticles(component, page);

    },

    navigateNext: function (component, event, helper) {
        // prevent default
        event.preventDefault();
        // this function call on click on the previous page button  
        var page = component.get("v.page") || 1;
        // get the previous button label  
        page = page + 1;
        // call the helper function
        helper.getNewsArticles(component, page);

    },

    doNothing: function (component, event, helper) {
        event.preventDefault();
    }

})