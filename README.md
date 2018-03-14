# Ballerina-Secure-Helloworld
Hello World service written in Ballerina (https://ballerinalang.org/), secured with Basic authentication. 
Authorization works with scopes, where a scope maps to one or more groups. An API resource can be secured with a scope, 
and a user who needs to access the particular resource should have the relevant groups assigned. 

### How to use
1. Create a file-based userstore using the scripts userstore-generator-cli.sh and permissionstore-generator-cli.sh. 
   The scripts will:
	i. Add usernames, a random user id mapping, and sha256 hash of the passwords in ballerina.conf file.
    ii. Assign group(s) to the user.
	iii. Define scopes and map scopes with groups.

###### Usage
   ```
   ./userstore-generator.sh -u {username} -p {password} -g {comma separated groups} 
   ```
   ex.: ./userstore-generator.sh -u user1 -p password123 -g group1,group2,group3

   ```
   ./permissionstore-generator.sh -s {scope name} -g {comma separated groups}
   ```
   ex.: ./permissionstore-generator.sh -s scope1 -g group1,group3

2. Engage authentication and authorization in your service:
   ```
    endpoint<http:Service> backendEp {
        port:9096,
        ssl:{
            keyStoreFile:"${ballerina.home}/bre/security/ballerinaKeystore.p12",
            keyStorePassword:"ballerina",
            certPassword:"ballerina"
        }
    }
    
    @http:serviceConfig {
        basePath:"/helloWorld",
        endpoints:[backendEp]
    }
    service<http:Service> helloWorld {
        @http:resourceConfig {
            methods:["GET"],
            path:"/sayHello"
        }
        resource sayHello (http:ServerConnector conn, http:Request request) {
            http:Response res = {};
            AuthStatus authStatus = checkAuth(request, "scope2", "/sayHello");
            if(authStatus.success) {
                res.setJsonPayload("Hello, World!!");
            } else {
                res = {statusCode:authStatus.statusCode, reasonPhrase:authStatus.message};
            }
            _ = conn -> respond(res);
        }
    }

    function checkAuth (http:Request request, string scopeName, string resourceName) (AuthStatus) {
        basic:HttpBasicAuthnHandler authnHandler = {};
        authz:HttpAuthzHandler authzHandler = {};
        if (!authnHandler.handle(request)) {
            AuthStatus authnStatus = {success:false, statusCode:401, message:"Unauthenticated"};
            return authnStatus;
        } else if (!authzHandler.handle(request, scopeName, resourceName)) {
            AuthStatus authzStatus = {success:false, statusCode:403, message:"Unauthorized"};
            return authzStatus;
        } else {
            AuthStatus authStatus = {success:true, statusCode:200, message:"Successful"};
            return authStatus;
        }
    }

    public struct AuthStatus {
        boolean success;
        int statusCode;
        string message;
    }
   ```
3. Start the service with the following command:
   ```
   ballerina run secure-helloworld.bal
   ```
4. Invoke the service with the correct basic authenication header, relevant to your username and password:
   ```
   curl -vk -H "Authorization: Basic xxxxx" https://localhost:9096/helloWorld/sayHello
   ```   
##### Note: Please see the ballerina.conf file included for the format of the userstore and other configurations.
