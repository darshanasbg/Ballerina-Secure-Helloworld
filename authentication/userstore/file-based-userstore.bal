package authentication.userstore;

import ballerina.config;
import ballerina.log;

@Description{value:"Configuration key for password in userstore"}
const string USERSTORE_PASSWORD_ENTRY = "password";
@Description{value:"Configuration key for groups for a user, in userstore"}
const string USERSTORE_GROUPS_ENTRY = "groups";
@Description{value:"Configuration key for userids in userstore"}
const string USERSTORE_USERIDS_ENTRY = "userids";

@Description {value:"Reads the password hash for a user"}
@Param {value:"string: username"}
@Return {value:"string: password hash read from userstore, or null if not found"}
public function readPasswordHash (string username) (string) {
    // first read the user id from user->id mapping
    string userid = readUserId(username);
    if (userid == null) {
        log:printDebug("No userid found for user: " + username);
        return null;
    }
    // read the hashed password from the userstore file, using the user id
    return config:getInstanceValue(userid, USERSTORE_PASSWORD_ENTRY);
}

@Description {value:"Reads the groups for a user"}
@Param {value:"string: username"}
@Return {value:"string: comma separeted groups list, as specified in the userstore file"}
public function readGroups (string username) (string) {
    // first read the user id from user->id mapping
    string userid = readUserId(username);
    if (userid == null) {
        log:printDebug("No userid found for user: " + username);
        return null;
    }
    // reads the groups for the userid
    return config:getInstanceValue(userid, USERSTORE_GROUPS_ENTRY);
}

@Description {value:"Reads the user id for the given username"}
@Param {value:"string: username"}
@Return {value:"string: user id read from the userstore, or null if not found"}
function readUserId (string username) (string) {
    return config:getInstanceValue(USERSTORE_USERIDS_ENTRY, username);
}
