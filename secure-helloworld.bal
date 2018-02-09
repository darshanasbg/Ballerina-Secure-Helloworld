import ballerina.net.http;
import authentication.basic;
import context;
import authorization;

service<http> helloWorld {

    resource sayHello (http:Request req, http:Response res) {

        basic:BasicAuthenticator authenticator = basic:createBasicAuthenticator();
        boolean isAuthenticated;
        context:SecurityContext secContext;
        isAuthenticated, secContext = authenticator.authenticate(req);
        authorization:AuthorizationChecker authzChecker = authorization:createAuthorizationCheker();
        if (!isAuthenticated) {
            res.setStatusCode(401);
        } else if (!authzChecker.checkAuthorization(secContext.username, "scope2", req.getRequestURL())) {
            res.setStatusCode(403);
        } else {
            res.setStringPayload("Hello World!! \n");
        }
        _ = res.send();
    }
}