({
	onModalCancel : function(component) {
        var modal = component.find('modal');
		$A.util.removeClass(modal, 'modal-in');
		var closeEvent = component.getEvent("closeModal");
		setTimeout(function(){
			closeEvent.fire();
		}, 300);
	},
	doneRendering : function(component) {	
	}
})