({
    // fires navigation event on standard nav
    onClick: function (component, event, helper) {

        var id = event.target.dataset.menuItemId;

        if (id) {
            document.getElementById("beta-banner-link").focus();
        	document.getElementById("beta-banner-link").blur();
            component.getSuper().navigate(id);
        }

    },

    // fires navigation event on mobile nav
    onClickMobile: function (component, event, helper) {
        var id = event.target.dataset.menuItemId;
        if (id) {
            component.getSuper().navigate(id);
        };

        // Also want to toggle the mobile menu visibility so the mobile nav disappears
        var toggleText = component.find("mobileNavMenu");
        $A.util.toggleClass(toggleText, "hide-mobile-nav");

        // Also toggle component attribute for chevron direction
        if (component.get("v.showMobileNav") === true) {
            component.set("v.showMobileNav", false);
        } else {
            component.set("v.showMobileNav", true);
        }
    },

    // Navigation to the homepage via the logo icon
    goHome: function (component, event, helper) {
        event.preventDefault();
        document.getElementById("logo").focus();
        document.getElementById("logo").blur();
        var address = "/";
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect": false
        });
        urlEvent.fire();
    },

    // Used to toggle the mobile nav menu and the chevron direction
    toggleMobileNav: function (component, event, helper) {
        var toggleText = component.find("mobileNavMenu");
        $A.util.toggleClass(toggleText, "hide-mobile-nav");
        
        if(event.target.getAttribute('aria-pressed') == 'false'){
            event.target.setAttribute('aria-pressed', 'true')
        } else {
            event.target.setAttribute('aria-pressed', 'false')
        }

        // Chevron direction:
        if (component.get("v.showMobileNav") === true) {
            component.set("v.showMobileNav", false);
        } else {
            component.set("v.showMobileNav", true);
        }
    },

})