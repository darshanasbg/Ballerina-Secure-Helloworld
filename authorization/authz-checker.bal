package authorization;

import ballerina.log;
import authentication.userstore;
import ballerina.config;
import ballerina.caching;
import utils;

const string USERSTORE_GROUPS_ENTRY = "groups";
const string AUTHZ_CACHE = "authz_cache";

AuthorizationChecker authzChecker;

public struct AuthorizationChecker {
    boolean enableCache;
    caching:Cache authzCache;
}

public function createAuthorizationCheker () (AuthorizationChecker) {
    if (authzChecker == null) {
        authzChecker = {authzCache:createAuthzCache()};
    }
    return authzChecker;
}

public function <AuthorizationChecker authzChecker> checkAuthorization (string username, string scopeName,
                                                                        string requestUrl) (boolean) {

    // check in the cache. cache key is <username>-<requestUrl>,
    // since different resources can have different scopes
    string authzCacheKey = username + "-" + requestUrl;
    boolean isAuthorized;
    any cachedAuthzResult = getCachedAuthzResult(authzCacheKey);
    if (cachedAuthzResult != null) {
        log:printInfo("Authz cache hit for user: " + username +  ", request URL: " + requestUrl);
        TypeCastError typeCastErr;
        isAuthorized, typeCastErr = (boolean) cachedAuthzResult;
        if (typeCastErr == null) {
            // no type cast error, return cached result.
            return isAuthorized;
        }
        // if a casting error occurs, clear the cache entry
        clearCachedAuthzResult(authzCacheKey);
    }
    log:printInfo("Authz cache miss for user: " + username +  ", request URL: " + requestUrl);
    
    string[] groupsForScope;
    error err;
    groupsForScope, err = getGroupsArray(readGroups(username, scopeName));
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
        log:printInfo("Successfully authorized user: " + username + " for url: " + requestUrl);
    }
    cacheAuthzResult(authzCacheKey, isAuthorized, username, requestUrl);
    return isAuthorized;
}

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

function getGroupsArray (string groupString) (string[], error) {
    if (groupString == null || groupString.length() == 0) {
        return null, handleError("could not extract any groups from groupString: " + groupString);
    }
    return groupString.split(","), null;
}

function readGroups (string username, string scopeName) (string) {
    // reads the groups for the provided scope
    return config:getInstanceValue(scopeName, USERSTORE_GROUPS_ENTRY);
}

function getCachedAuthzResult (string authzCacheKey) (any) {
    if (authzChecker.authzCache != null) {
        return authzChecker.authzCache.get(authzCacheKey);
    }
    return null;
}

function cacheAuthzResult (string authzCacheKey, boolean isAuthorized, string username, string requestUrl) {
    if (authzChecker.authzCache != null) {
        log:printInfo("Caching authz result for user: " + username + ", request path: " + requestUrl + ", result: " +
                      isAuthorized);
        authzChecker.authzCache.put(authzCacheKey, isAuthorized);
    }
}

function clearCachedAuthzResult (string authzCacheKey) {
    if (authzChecker.authzCache != null) {
        authzChecker.authzCache.remove(authzCacheKey);
    }
}

function createAuthzCache () (caching:Cache) {
    if (utils:isCacheEnabled(AUTHZ_CACHE)) {
        int expiryTime;
        int capacity;
        float evictionFactor;
        expiryTime, capacity, evictionFactor = utils:getCacheConfigurations(AUTHZ_CACHE);
        return caching:createCache(AUTHZ_CACHE, expiryTime, capacity, evictionFactor);
    }
    log:printInfo("Cache " + AUTHZ_CACHE + " disabled");
    
    return null;
}

function handleError (string message) (error) {
    error e = {msg:message};
    log:printError(message);
    return e;
}