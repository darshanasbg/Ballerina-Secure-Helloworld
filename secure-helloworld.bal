import ballerina.net.http;
import ballerina.log;
import authentication;

service<http> helloWorld {

    resource sayHello (http:Request req, http:Response res) {

        boolean isAuthenticated;
        error authError;
        isAuthenticated, authError = authentication:interceptRequest(req);
        if (authError != null) {
            log:printErrorCause("Error while authenticating: ", authError);
            res.setStringPayload(authError.msg);
        } else {
            if (!isAuthenticated) {
                log:printError("user not authenticated");
                res.statusCode = 401;
                res.setStringPayload("401: Unauthenticated ");
            } else {
                res.setStringPayload("Hello, World! ");
            }
        }
        _ = res.send();
    }
}