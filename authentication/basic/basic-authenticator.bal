package authentication.basic;

import ballerina.log;
import authentication.userstore;
import ballerina.net.http;
import ballerina.util;
import ballerina.caching;
import ballerina.security.crypto;
import context;
import utils;

@Description{value:"Authentication header name"}
const string AUTH_HEADER = "Authorization";
@Description{value:"Basic authentication scheme"}
const string AUTH_SCHEME = "Basic";
@Description{value:"Authentication cache name"}
const string AUTH_CACHE = "auth_cache";

@Description{value:"Represents a Basic Authenticator"}
@Field {value:"authCache: authentication cache object"}
public struct BasicAuthenticator {
    caching:Cache authCache ;
}

@Description {value:"Basic Authenticator instance"}
BasicAuthenticator authenticator;

@Description {value:"Creates a Basic Authenticator"}
@Return {value:"BasicAuthenticator instance"}
public function createAuthenticator () (BasicAuthenticator) {
    if (authenticator == null) {
        authenticator = {authCache:createAuthCache()};
    }
    return authenticator;
}

@Description {value:"Authenticates a request using basic auth"}
@Param {value:"req: request object"}
@Return {value:"boolean: true if authentication is a success, else false"}
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
        log:printDebug("Auth cache hit for request URL: " + req.getRequestURL());
        TypeCastError typeCastErr;
        secContext, typeCastErr = (context:SecurityContext) cachedAuthResult;
        if (typeCastErr == null) {
            // no type cast error, return cached result.
            return secContext.isAuthenticated, secContext;
        }
        // if a casting error occurs, clear the cache entry
        clearCachedAuthResult(basicAuthHeaderValue);
    }
    log:printDebug("Auth cache miss for request URL: " + req.getRequestURL());

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

@Description {value:"Authenticates against the userstore"}
@Param {value:"username: user name"}
@Param {value:"password: password"}
@Return {value:"boolean: true if authentication is a success, else false"}
function authenticateAgaistUserstore (string username, string password) (boolean) {
    string passwordHashReadFromUserstore = userstore:readPasswordHash(username);
    if (passwordHashReadFromUserstore == null) {
        log:printDebug("No credentials found for user: " + username);
        return false;
    }

    // compare the hashed password with then entry read from the userstore
    if (crypto:getHash(password, crypto:Algorithm.SHA256) == passwordHashReadFromUserstore) {
        log:printDebug("Successfully authenticated user " + username + " against the userstore");
        return true;
    }
    return false;
}

@Description {value:"Retrieves the cached authentication result if any, for the given basic auth header value"}
@Param {value:"basicAuthHeaderValue: basic authentication header"}
@Return {value:"any: cached entry, or null in a cache miss"}
function getCachedAuthResult (string basicAuthHeaderValue) (any) {
    if (authenticator.authCache != null){
         return authenticator.authCache.get(basicAuthHeaderValue);
    }
    return null;
}

// TODO: correct once the security context is implemented
@Description {value:"Caches the authentication result"}
@Param {value:"basicAuthHeaderValue: value of basic authentication header sent with the request"}
@Param {value:"requestUrl: request Url"}
function cacheAuthResult (string basicAuthHeaderValue, context:SecurityContext securityContext, string requestUrl) {
    if (authenticator.authCache != null) {
        log:printDebug("Caching auth result for request path: " + requestUrl + ", result: " +
                      securityContext.isAuthenticated);
        authenticator.authCache.put(basicAuthHeaderValue, securityContext);
    }
}

@Description {value:"Clears any cached authentication result"}
@Param {value:"basicAuthHeaderValue: value of basic authentication header sent with the request"}
function clearCachedAuthResult (string basicAuthHeaderValue) {
    if (authenticator.authCache != null) {
        authenticator.authCache.remove(basicAuthHeaderValue);
    }
}

@Description {value:"Extracts the basic authentication header value from the request"}
@Param {value:"req: request instance"}
@Return {value:"string: value of the basic authentication header"}
@Return {value:"error: any error occurred while extracting the basic authentication header"}
function extractBasicAuthHeaderValue (http:Request req) (string, error) {
    // extract authorization header
    var basicAuthHeader = req.getHeader(AUTH_HEADER);
    if (basicAuthHeader == null && !basicAuthHeader.value.hasPrefix(AUTH_SCHEME)) {
        return null, handleError("Basic authentication header not sent with the request");
    }
    return basicAuthHeader.value, null;
}

@Description {value:"Extracts the basic authentication credentials from the header value"}
@Param {value:"authHeader: basic authentication header"}
@Return {value:"string: username extracted"}
@Return {value:"string: password extracted"}
@Return {value:"error: any error occurred while extracting creadentials"}
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

// TODO: remove once Sec context is added to Ballerina runtime
function createSecurityContext (string username, boolean isAuthenticated) (context:SecurityContext) {
    context:SecurityContext secCxt = {username:username, roles:null, isAuthenticated:isAuthenticated, properties:null};
    return secCxt;
}

@Description {value:"Creates a cache to store authentication results against basic auth headers"}
@Return {value:"cache: authentication cache instance"}
function createAuthCache () (caching:Cache) {
    if (utils:isCacheEnabled(AUTH_CACHE)) {
        int expiryTime;
        int capacity;
        float evictionFactor;
        expiryTime, capacity, evictionFactor = utils:getCacheConfigurations(AUTH_CACHE);
        return caching:createCache(AUTH_CACHE, expiryTime, capacity, evictionFactor);
    }
    log:printDebug("Cache " + AUTH_CACHE + " disabled");
    return null;
}

@Description {value:"Error handler"}
@Param {value:"message: error message"}
@Return {value:"error: error populated with the message"}
function handleError (string message) (error) {
    error e = {msg:message};
    log:printError(message);
    return e;
}
