({
	afterRender: function(cmp, helper) {
        this.superAfterRender();
        helper.addContent(cmp);
        var modalClass  = cmp.get('v.modalClass');
        var modal       = cmp.find('modal');
        if (modalClass) {
        	$A.util.addClass(modal, modalClass);
        }
        if ($A.get('$Browser.isIOS')) {
            $A.util.addClass(modal, 'ios-browser');
        }
    },
    unrender : function(cmp) {
        // unblock overflow on mobile devices and return to recently locked position
        var offset = parseInt(window.document.body.style.top, 10) * -1;
        window.document.body.style.top = "";
        $A.util.removeClass(window.document.body, 'modal-open');
        window.document.body.scrollTop = offset;
        cmp.set("v.body", []);
        return this.superUnrender();
	}
})