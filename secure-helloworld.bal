import ballerina.net.http;
import authentication.basic;
import context;
import authorization;

service<http> helloWorld {

    resource sayHello (http:Request req, http:Response res) {

        basic:BasicAuthenticator authenticator = basic:createAuthenticator();
        boolean isAuthenticated;
        context:SecurityContext secContext;
        isAuthenticated, secContext = authenticator.authenticate(req);
        authorization:AuthorizationChecker authzChecker = authorization:createChecker();
        if (!isAuthenticated) {
            res.setStatusCode(401);
        } else if (!authzChecker.check(secContext.username, "scope2", req.getRequestURL())) {
            res.setStatusCode(403);
        } else {
            res.setStringPayload("Hello World!! \n");
        }
        _ = res.send();
    }
}