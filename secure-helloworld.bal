import ballerina.net.http;
import ballerina.auth.authz;
import ballerina.auth.basic;

endpoint<http:Service> backendEp {
    port:9096,
    ssl:{
        keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
        keyStorePassword:"ballerina",
        certPassword:"ballerina"
    }
}
@http:serviceConfig {
    basePath:"/helloWorld",
    endpoints:[backendEp]
}
service<http:Service> helloWorld {
    @http:resourceConfig {
        methods:["GET"],
        path:"/sayHello"
    }
    resource sayHello (http:ServerConnector conn, http:Request request) {
        http:Response res = {};
        AuthStatus authStatus = checkAuth(request, "scope2", "/sayHello");
        if(authStatus.success) {
            res.setJsonPayload("Hello, World!!");
        } else {
            res = {statusCode:authStatus.statusCode, reasonPhrase:authStatus.message};
        }
        _ = conn -> respond(res);
    }
}

function checkAuth (http:Request request, string scopeName, string resourceName) (AuthStatus) {
    basic:HttpBasicAuthnHandler authnHandler = {};
    authz:HttpAuthzHandler authzHandler = {};
    if (!authnHandler.handle(request)) {
        AuthStatus authnStatus = {success:false, statusCode:401, message:"Unauthenticated"};
        return authnStatus;
    } else if (!authzHandler.handle(request, scopeName, resourceName)) {
        AuthStatus authzStatus = {success:false, statusCode:403, message:"Unauthorized"};
        return authzStatus;
    } else {
        AuthStatus authStatus = {success:true, statusCode:200, message:"Successful"};
        return authStatus;
    }
}

public struct AuthStatus {
    boolean success;
    int statusCode;
    string message;
}