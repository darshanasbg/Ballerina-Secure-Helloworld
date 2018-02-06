package authentication.userstore;

import ballerina.config;
import ballerina.log;

public struct FileBasedUserstore {
    string userstoreType;
    string url;
    map userstoreProperties;
}

FileBasedUserstore fileBasedUserStore;
string userstoreFile = "ballerina.conf";

public function createFileBasedUserstore (string userstoreType, map properties) (FileBasedUserstore) {
    if (fileBasedUserStore != null) {
        return fileBasedUserStore;
    }
    // TODO: fix hardcoded config file name
    fileBasedUserStore = {userstoreType:userstoreType, url:userstoreFile, userstoreProperties:properties};
    log:printInfo("Userstore initialized, type:" + fileBasedUserStore.userstoreType + ", url: "
                  + fileBasedUserStore.url);
    return fileBasedUserStore;
}

public function <FileBasedUserstore userstore> authenticateUser (string username, string password) (boolean) {
    string passwordHash = userstore.readUserCredentials(username);
    if (passwordHash == null) {
        log:printInfo("No credentials found for user: " + username);
        return false;
    }
    //TODO: hash the password from the runtime and compare with the hash stored in userstore.
    //TODO: currently stored in plaintext, change to hash value
    if (password == passwordHash) {
        return true;
    }
    return false;
}

function <FileBasedUserstore userstore> readUserCredentials (string username) (string) {
    return config:getInstanceValue(username, "password");
}
