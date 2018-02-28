import ballerina.net.http;
import ballerina.auth.basic;
import ballerina.auth.authz;

service<http> helloWorld {

    resource sayHello (http:Connection conn, http:InRequest req) {

        http:OutResponse res = {};
        basic:HttpBasicAuthnHandler authnHandler = {};
        authz:HttpAuthzHandler authzHandler = {};
        if (!authnHandler.handle(req)) {
            res = {statusCode:401, reasonPhrase:"Unauthenticated"};
        } else if (!authzHandler.handle(req, "scope2", "/sayHello")) {
            res = {statusCode:403, reasonPhrase:"Unauthorized"};
        } else {
            res.setStringPayload("Hello, World!!");
        }
        _ = conn.respond(res);
    }
}