package authorization;

import ballerina.log;
import authentication.userstore;
import ballerina.config;
import ballerina.caching;
import utils;

@Description{value:"Configuration key for groups for a user, in userstore"}
const string USERSTORE_GROUPS_ENTRY = "groups";
@Description{value:"Authorization cache name"}
const string AUTHZ_CACHE = "authz_cache";

@Description {value:"AuthorizationChecker instance"}
AuthorizationChecker authzChecker;

@Description {value:"Representation of AuthorizationChecker"}
@Field {value:"authzCache: authorization cache instance"}
public struct AuthorizationChecker {
    caching:Cache authzCache;
}

@Description {value:"Creates a Basic Authenticator"}
@Return {value:"AuthorizationChecker instance"}
public function createChecker () (AuthorizationChecker) {
    if (authzChecker == null) {
        authzChecker = {authzCache:createAuthzCache()};
    }
    return authzChecker;
}

@Description {value:"Performs a authorization check, by comparing the groups of the user and the groups of the scope"}
@Param {value:"username: user name"}
@Param {value:"scopeName: name of the scope"}
@Param {value:"resourceName: name of the resource"}
@Return {value:"boolean: true if authorization check is a success, else false"}
public function <AuthorizationChecker authzChecker> check (string username, string scopeName,
                                                                        string resourceName) (boolean) {

    // check in the cache. cache key is <username>-<resource>,
    // since different resources can have different scopes
    string authzCacheKey = username + "-" + resourceName;
    boolean isAuthorized;
    any cachedAuthzResult = getCachedAuthzResult(authzCacheKey);
    if (cachedAuthzResult != null) {
        log:printDebug("Authz cache hit for user: " + username +  ", request URL: " + resourceName);
        TypeCastError typeCastErr;
        isAuthorized, typeCastErr = (boolean) cachedAuthzResult;
        if (typeCastErr == null) {
            // no type cast error, return cached result.
            return isAuthorized;
        }
        // if a casting error occurs, clear the cache entry
        clearCachedAuthzResult(authzCacheKey);
    }
    log:printDebug("Authz cache miss for user: " + username +  ", request URL: " + resourceName);
    
    string[] groupsForScope;
    error err;
    groupsForScope, err = getGroupsArray(readGroups(scopeName));
    if (err != null) {
        // no groups found for this scope, allow to continue
        return true;
    }

    string[] groupsOfUser;
    groupsOfUser, err = getGroupsArray(userstore:readGroups(username));
    if (err != null) {
        // no groups for user, authorization failure
        return false;
    }
    isAuthorized = rolesMatch(groupsForScope, groupsOfUser);
    if (isAuthorized) {
        log:printDebug("Successfully authorized user: " + username + " for resource: " + resourceName);
    }
    cacheAuthzResult(authzCacheKey, isAuthorized, username, resourceName);
    return isAuthorized;
}

@Description {value:"Matches the roles passed"}
@Param {value:"requiredGroupsForScope: array of roles for the scope"}
@Param {value:"groupsReadFromUserstore: array of roles for the user"}
@Return {value:"boolean: true if two arrays are equal in content, else false"}
function rolesMatch (string[] requiredGroupsForScope, string[] groupsReadFromUserstore) (boolean) {
    int groupCountRequiredForResource = lengthof requiredGroupsForScope;
    int matchingRoleCount = 0;
    foreach groupReadFromUserstore in groupsReadFromUserstore {
        foreach groupRequiredForResource in requiredGroupsForScope {
            if (groupRequiredForResource == groupReadFromUserstore){
                matchingRoleCount = matchingRoleCount + 1;
            }
        }
    }
    return matchingRoleCount == groupCountRequiredForResource;
}

@Description {value:"Construct an array of groups from the comma separed group string passed"}
@Param {value:"groupString: comma separated string of groups"}
@Return {value:"string[]: array of groups"}
@Return {value:"error: if the group string is nul or empty"}
function getGroupsArray (string groupString) (string[], error) {
    if (groupString == null || groupString.length() == 0) {
        return null, handleError("could not extract any groups from groupString: " + groupString);
    }
    return groupString.split(","), null;
}

@Description {value:"Reads groups for the given scopes"}
@Param {value:"scopeName: name of the scope"}
@Return {value:"string: comma separated groups specified for the scopename"}
function readGroups (string scopeName) (string) {
    // reads the groups for the provided scope
    return config:getInstanceValue(scopeName, USERSTORE_GROUPS_ENTRY);
}

@Description {value:"Retrieves the cached authorization result if any, for the given basic auth header value"}
@Param {value:"authzCacheKey: cache key - <username>-<resource>"}
@Return {value:"any: cached entry, or null in a cache miss"}
function getCachedAuthzResult (string authzCacheKey) (any) {
    if (authzChecker.authzCache != null) {
        return authzChecker.authzCache.get(authzCacheKey);
    }
    return null;
}

@Description {value:"Caches the authorization result"}
@Param {value:"authzCacheKey: cache key - <username>-<resource>"}
@Param {value:"isAuthorized: authorization decision"}
@Param {value:"username: user name"}
@Param {value:"requestUrl: request Url"}
function cacheAuthzResult (string authzCacheKey, boolean isAuthorized, string username, string requestUrl) {
    if (authzChecker.authzCache != null) {
        log:printDebug("Caching authz result for user: " + username + ", request path: " + requestUrl + ", result: " +
                      isAuthorized);
        authzChecker.authzCache.put(authzCacheKey, isAuthorized);
    }
}

@Description {value:"Clears any cached authorization result"}
@Param {value:"authzCacheKey: cache key - <username>-<resource>"}
function clearCachedAuthzResult (string authzCacheKey) {
    if (authzChecker.authzCache != null) {
        authzChecker.authzCache.remove(authzCacheKey);
    }
}

@Description {value:"Creates a cache to store authorization results against basic auth headers"}
@Return {value:"cache: authentication cache instance"}
function createAuthzCache () (caching:Cache) {
    if (utils:isCacheEnabled(AUTHZ_CACHE)) {
        int expiryTime;
        int capacity;
        float evictionFactor;
        expiryTime, capacity, evictionFactor = utils:getCacheConfigurations(AUTHZ_CACHE);
        return caching:createCache(AUTHZ_CACHE, expiryTime, capacity, evictionFactor);
    }
    log:printDebug("Cache " + AUTHZ_CACHE + " disabled");

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