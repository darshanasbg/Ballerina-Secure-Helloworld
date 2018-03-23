import ballerina/net.http;
import ballerina/io;
import ballerina/net.http.endpoints;
import ballerina/auth;

endpoint endpoints:ApiEndpoint ep {
    port:9090,
    secureSocket:
    {
        keyStore:{
            filePath:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password:"ballerina"
        },
        trustStore:{
             filePath:"${ballerina.home}/bre/security/ballerinaTruststore.p12",
             password:"ballerina"
        }
    }
};

@http:ServiceConfig {
    basePath:"/hello"
}
@auth:Config {
    authentication:{enabled:true},
    scope:"xxx"
}
service<http:Service> echo bind ep {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/sayHello"
    }
    @auth:Config {
        scope:"scope2"
    }
    echo (endpoint client, http:Request req) {
        http:Response res = {};
        res.setStringPayload("Hello, World!!!");
        _ = client -> respond(res);
    }
}
