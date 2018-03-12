import ballerina.net.http;
import ballerina.auth.authz;
import ballerina.auth.basic;

@http:configuration {
    basePath:"/helloWorld",
    httpsPort:9096,
    keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
    keyStorePassword:"ballerina",
    certPassword:"ballerina"
}
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