({
	redirect : function(component) {
        $A.get('e.force:navigateToURL').setParams({
            url: component.get('v.buttonLink')
        }).fire();
	}
})