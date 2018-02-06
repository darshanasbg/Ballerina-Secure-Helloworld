package authentication.basic;

import ballerina.log;
import authentication.userstore;
import ballerina.config;
const string authSceme = "basic";
const string fileBasedUserstoreType = "file";
const string fjdbcUserstoreType = "file";
const string ldapUserstoreType = "ldap";
string[] userstoreTypes;

public function createBasicAuthenticator () (error) {
    if (userstoreTypes != null) {
        // already initialized
        return null;
    }
    string userStoreTypesString = readUserstoreTypes();
    if (userStoreTypesString == null) {
        return handleError("No userstore types defined for " + authSceme + " authenticator");
    }
    userstoreTypes = userStoreTypesString.split(",");
    log:printInfo("Basic authenticator initialized");
    return null;
}

public function authenticate (string username, string password) (boolean, error) {
    foreach userstoreType in userstoreTypes {
        if (userstoreType.trim() == fileBasedUserstoreType) {
            userstore:FileBasedUserstore fileBasedUserstore = userstore:createFileBasedUserstore
                                                              (fileBasedUserstoreType, null);
            if (fileBasedUserstore.authenticateUser(username, password)) {
                return true, null;
            }
        } else {
            // TODO: add support for other user stores
            string errorMsg = "Userstore " + userstoreType + " not supported yet";
            log:printError(errorMsg);
            error e = {msg:errorMsg};
            return false, e;
        }
    }
    return false, null;
}

function readUserstoreTypes () (string) {
    return config:getInstanceValue(authSceme, "userstores");
}

function handleError (string message) (error) {
    error e = {msg:message};
    log:printError(message);
    return e;
}
