package authentication.basic;

import ballerina.log;
import authentication.userstore;
import ballerina.net.http;
import ballerina.util;
import ballerina.caching;
import ballerina.security.crypto;
import context;
import utils;

const string AUTH_HEADER = "Authorization";
const string AUTH_SCHEME = "Basic";
const string AUTH_CACHE = "auth_cache";

public struct BasicAuthenticator {
    caching:Cache authCache ;
}

BasicAuthenticator authenticator;

public function createBasicAuthenticator () (BasicAuthenticator) {
    if (authenticator == null) {
        authenticator = {authCache:createAuthCache()};
    }
    return authenticator;
}

public function <BasicAuthenticator authenticator> authenticate (http:Request req) (boolean, context:SecurityContext) {
    // extract the header value
    string basicAuthHeaderValue;
    error err;
    basicAuthHeaderValue, err = extractBasicAuthHeaderValue(req);
    if (err != null) {
        return false, createSecurityContext(null, false);
    }
    context:SecurityContext secContext;
    // check in the cache
    any cachedAuthResult = getCachedAuthResult(basicAuthHeaderValue);
    if (cachedAuthResult != null) {
        log:printInfo("Auth cache hit for request URL: " + req.getRequestURL());
        TypeCastError typeCastErr;
        secContext, typeCastErr = (context:SecurityContext) cachedAuthResult;
        if (typeCastErr == null) {
            // no type cast error, return cached result.
            return secContext.isAuthenticated, secContext;
        }
        // if a casting error occurs, clear the cache entry
        clearCachedAuthResult(basicAuthHeaderValue);
    }
    log:printInfo("Auth cache miss for request URL: " + req.getRequestURL());

    // cache miss
    string username;
    string password;
    username, password, err = extractBasicAuthCredentials(basicAuthHeaderValue);
    if (err != null) {
        return false, null;
    }
    secContext = createSecurityContext(username, authenticateAgaistUserstore(username, password));
    // cache result
    cacheAuthResult(basicAuthHeaderValue, secContext, username);

    return secContext.isAuthenticated, secContext;
}

function authenticateAgaistUserstore (string username, string password) (boolean) {
    string passwordHashReadFromUserstore = userstore:readPasswordHash(username);
    if (passwordHashReadFromUserstore == null) {
        // TODO: make debug
        log:printInfo("No credentials found for user: " + username);
        return false;
    }

    // compare the hashed password with then entry read from the userstore
    if (crypto:getHash(password, crypto:Algorithm.SHA256) == passwordHashReadFromUserstore) {
        // make debug
        log:printInfo("Successfully authenticated user " + username + " against the userstore");
        return true;
    }
    return false;
}

function getCachedAuthResult (string basicAuthHeaderValue) (any) {
    if (authenticator.authCache != null){
         return authenticator.authCache.get(basicAuthHeaderValue);
    }
    return null;
}

function cacheAuthResult (string basicAuthHeaderValue, context:SecurityContext securityContext, string requestUrl) {
    if (authenticator.authCache != null) {
        log:printInfo("Caching auth result for request path: " + requestUrl + ", result: " +
                      securityContext.isAuthenticated);
        authenticator.authCache.put(basicAuthHeaderValue, securityContext);
    }
}

function clearCachedAuthResult (string basicAuthHeaderValue) {
    if (authenticator.authCache != null) {
        authenticator.authCache.remove(basicAuthHeaderValue);
    }
}

function extractBasicAuthHeaderValue (http:Request req) (string, error) {
    // extract authorization header
    var basicAuthHeader = req.getHeader(AUTH_HEADER);
    if (basicAuthHeader == null && !basicAuthHeader.value.hasPrefix(AUTH_SCHEME)) {
        return null, handleError("Basic authentication header not sent with the request");
    }
    return basicAuthHeader.value, null;
}

function extractBasicAuthCredentials (string authHeader) (string, string, error) {
    // extract user credentials from basic auth header
    string decodedBasicAuthHeader = util:base64Decode(authHeader.subString(5, authHeader.length()).trim());
    string[] decodedCredentials = decodedBasicAuthHeader.split(":");
    if (lengthof decodedCredentials != 2) {
        return null, null, handleError("Incorrect basic authentication header format");
    } else {
        return decodedCredentials[0], decodedCredentials[1], null;
    }
}

function createSecurityContext (string username, boolean isAuthenticated) (context:SecurityContext) {
    context:SecurityContext secCxt = {username:username, roles:null, isAuthenticated:isAuthenticated, properties:null};
    return secCxt;
}

function createAuthCache () (caching:Cache) {
    if (utils:isCacheEnabled(AUTH_CACHE)) {
        int expiryTime;
        int capacity;
        float evictionFactor;
        expiryTime, capacity, evictionFactor = utils:getCacheConfigurations(AUTH_CACHE);
        return caching:createCache(AUTH_CACHE, expiryTime, capacity, evictionFactor);
    }
    log:printInfo("Cache " + AUTH_CACHE + " disabled");
    return null;
}

function handleError (string message) (error) {
    error e = {msg:message};
    log:printError(message);
    return e;
}
