package authentication;

import ballerina.net.http;
import ballerina.log;
import ballerina.util;
import authentication.basic;

string authHeader = "Authorization";
string authScheme = "Basic";

public function interceptRequest (http:Request req) (boolean, error) {
    // check authorization header
    var basicAuthHeader = req.getHeader(authHeader);
    if (basicAuthHeader == null) {
        return false, handleError("401: No Authentication header found in the request");
    }
    string authHeader = basicAuthHeader.value;
    log:printInfo("Authorization header: " + authHeader);
    if (authHeader.hasPrefix(authScheme)) {
        // basic authentication
        string authHeaderValue = authHeader.subString(5, authHeader.length()).trim();
        log:printInfo(authHeaderValue);
        string decodedBasicAuthHeader = util:base64Decode(authHeaderValue);
        log:printInfo("decoded Authorization header: " + decodedBasicAuthHeader);
        string[] decodedCredentials = decodedBasicAuthHeader.split(":");
        if (lengthof decodedCredentials != 2) {
            return false, handleError("401: Incorrect Basic Authentication header");
        } else {
            error basicAuthError = basic:createBasicAuthenticator();
            if (basicAuthError != null) {
                return false, handleError("Error in creating basic authenticator: " + basicAuthError.msg);
            }
            return basic:authenticate(decodedCredentials[0], decodedCredentials[1]);
        }
    } else {
        // TODO: other authentication schemes
        return false, handleError("Unsupported authentication scheme, only Basic auth is supported");
    }
}

function handleError (string message) (error) {
    error e = {msg:message};
    log:printError(message);
    return e;
}
