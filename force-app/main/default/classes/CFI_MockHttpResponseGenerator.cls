@isTest
global class CFI_MockHttpResponseGenerator implements HttpCalloutMock {
	public static String FAIL_LOGIN_RESPONCE = 'LoginFailed';
	public static String FAIL_RESPONCE = 'CalloutFailed';
    public static String FAIL_SINGLE_RESPONCE = 'CalloutFailed-SingleMessage';
	public static String SUC_GET_TOKEN = 'Login';
	public static String SUC_CREATE_NOTICE = 'CreateNotice';
	public static String SUC_CREATE_AWARD = 'CreateAWARD';

	public static String NOTICE_ID = '0dfae812-e581-4a6c-b91a-1d8b96b0b18a';
	public static String TOKEN = 'nz8oJmoOtqwYNrIV0w--TTffFzJlaXVP2e-FOKomxlST2A0kAjb6ABJuttwU2UFEFo1zr0hYqsK_-pHL1N_rTUr9wswnPdDngPy9prBjcYKfJ';

	public String typeOfReponce = FAIL_LOGIN_RESPONCE;

	global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if (typeOfReponce == FAIL_LOGIN_RESPONCE){
        	res = getLoginFailResponce();
        }
        if (typeOfReponce == SUC_GET_TOKEN){
        	res = getLoginResponce();
        }
        if (typeOfReponce == SUC_CREATE_NOTICE){
        	res = getCreateNotice();
        }
        if (typeOfReponce == FAIL_RESPONCE){
        	res = getFailResponce();
        }
        if (typeOfReponce == SUC_CREATE_AWARD){
        	res = getCreateAward();
        }
        if (typeOfReponce == FAIL_SINGLE_RESPONCE){
            res = getFailResponceWithSingleMessage();
        }
        
        return res;
    }

    private HTTPResponse getLoginFailResponce(){
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        res.setBody('{"error": "invalid_client"}');
        res.setStatusCode(400);

        return res;
    }

    private HTTPResponse getLoginResponce(){
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        CFI_MessageFactory.TokenResp tr = new CFI_MessageFactory.TokenResp();
        tr.access_token = TOKEN;
        tr.expires_in = 44444;
        tr.token_type = 'TOKEN';
        res.setBody(JSON.serialize(tr));
        res.setStatusCode(200);

        return res;
    }

    private HTTPResponse getFailResponce(){
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        CFI_MessageFactory.ErrorMessage em = new CFI_MessageFactory.ErrorMessage();
        em.code='401';
        em.message = 'Fail for unit test';
        em.property = '';
        res.setBody(JSON.serialize(new List <CFI_MessageFactory.ErrorMessage> {em}));
        res.setStatusCode(400);

        return res;
    }

    private HTTPResponse getCreateNotice(){
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String strBody = '"' + NOTICE_ID +'"';
        res.setBody(strBody);
        res.setStatusCode(200);

        return res;
    }

    private HTTPResponse getCreateAward(){
    	HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        res.setBody('');
        res.setStatusCode(200);

        return res;
    }

    private HTTPResponse getFailResponceWithSingleMessage(){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json;charset=UTF-8');
        CFI_MessageFactory.ErrorMessage em = new CFI_MessageFactory.ErrorMessage();
        em.code='401';
        em.message = 'Fail for unit test';
        em.property = '';
        res.setBody(JSON.serialize(new List <CFI_MessageFactory.ErrorMessage> {em}));
        res.setStatusCode(400);

        return res;
    }
}