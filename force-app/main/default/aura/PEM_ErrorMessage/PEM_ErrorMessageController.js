({
	update : function(component) {
        var params = {
            'bold_large':'',
            'heading_text':'',
            'heading_medium':'',
            'next':'',
            'confirmation_message':'',
            'message_line1':'',
            'message_line2':''
        };
        var token = decodeURIComponent(window.location.search.substring(1));
        var tokens = token.split('&') || [];
        for(var i=0; i<tokens.length; i+=1) {
            var t = tokens[i].split('=') || [];
            params[t[0]] = t[1].replace(/\+/g, ' ') || '';
        }
        component.set('v.bold_large', params.bold_large);
        component.set('v.heading_text', params.heading_text);
        component.set('v.heading_medium', params.heading_medium);
        component.set('v.next', params.next);
        component.set('v.confirmation_message', params.confirmation_message);
        component.set('v.message_line1', params.message_line1);
        component.set('v.message_line2', params.message_line2);
    }
})