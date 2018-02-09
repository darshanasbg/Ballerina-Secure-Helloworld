package authentication.userstore;

import ballerina.config;
import ballerina.log;

const string USERSTORE_PASSWORD_ENTRY = "password";
const string USERSTORE_GROUPS_ENTRY = "groups";
const string USERSTORE_USERIDS_ENTRY = "userids";

public function readPasswordHash (string username) (string) {
    // first read the user id from user->id mapping
    string userid = readUserId(username);
    if (userid == null) {
        // TODO: make debug
        log:printInfo("No userid found for user: " + username);
        return null;
    }
    // read the hashed password from the userstore file, using the user id
    return config:getInstanceValue(userid, USERSTORE_PASSWORD_ENTRY);
}

public function readGroups (string username) (string) {
    // first read the user id from user->id mapping
    string userid = readUserId(username);
    if (userid == null) {
        // TODO: make debug
        log:printInfo("No userid found for user: " + username);
        return null;
    }
    // reads the groups for the userid
    return config:getInstanceValue(userid, USERSTORE_GROUPS_ENTRY);
}

function readUserId (string username) (string) {
    return config:getInstanceValue(USERSTORE_USERIDS_ENTRY, username);
}
