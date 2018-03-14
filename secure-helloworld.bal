import ballerina.net.http;
import ballerina.auth.authz;
import ballerina.auth.basic;

//public struct ServiceEndpointConfiguration {
//    string host;
//    int port;
//    KeepAlive keepAlive;
//    TransferEncoding transferEncoding;
//    Chunking chunking;
//    SslConfiguration ssl;
//    string httpVersion;
//}

//http:SslConfiguration sslConfig = {
//                                      keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
//                                      keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
//                                      keyStorePassword:"ballerina",
//                                      certPassword:"ballerina"
//                                  };
//http:ServiceEndpointConfiguration serviceEpConfig = {port: 9096, ssl:sslConfig};

endpoint<http:Service> backendEp {
    port:9096
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
        var httpClient = backendEp.getConnector();
        http:Response res = {};
        res.setStringPayload("Hello, World!!");
        _ = httpClient -> respond(res);
    }
}

//service<http> helloWorld {
//
//    resource sayHello (http:Connection conn, http:Request req) {
//
//        http:Response res = {};
//        basic:HttpBasicAuthnHandler authnHandler = {};
//        authz:HttpAuthzHandler authzHandler = {};
//        if (!authnHandler.handle(req)) {
//            res = {statusCode:401, reasonPhrase:"Unauthenticated"};
//        } else if (!authzHandler.handle(req, "scope2", "/sayHello")) {
//            res = {statusCode:403, reasonPhrase:"Unauthorized"};
//        } else {
//            res.setStringPayload("Hello, World!!");
//        }
//        _ = conn.respond(res);
//    }
//}