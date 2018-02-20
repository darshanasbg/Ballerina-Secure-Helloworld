import ballerina.net.http;
import ballerina.security.authentication.basic;
import ballerina.security.authorization;

service<http> helloWorld {

    resource sayHello (http:Connection conn, http:InRequest req) {

        http:OutResponse res = {};
        if(!basic:handle(req)) {
            res = {statusCode:401, reasonPhrase:"Unauthenticated"};
            // currently, need to pass the scope and the resource name to the method call for the authorization
        } else if (!authorization:handle(req, "scope2", "/sayHello")) {
            res = {statusCode:403, reasonPhrase:"Unauthorized"};
        } else {
            res.setStringPayload("Hello, World!!");
        }
        _ = conn.respond(res);
    }
}