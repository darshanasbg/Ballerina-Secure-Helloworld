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
   service<http> helloWorld {

       resource sayHello (http:Connection conn, http:InRequest req) {

           http:OutResponse res = {};
           basic:HttpBasicAuthnHandler authnHandler = {};
           authz:HttpAuthzHandler authzHandler = {};
           // authenticate
           if (!authnHandler.handle(req)) {
               res = {statusCode:401, reasonPhrase:"Unauthenticated"};
	     // to access the resource 'sayHello', a user would need to be in groups which are mapped to 'scope2'
           } else if (!authzHandler.handle(req, "scope2", "/sayHello")) {
               res = {statusCode:403, reasonPhrase:"Unauthorized"};
           } else {
               res.setStringPayload("Hello, World!!");
           }
           _ = conn.respond(res);
       }
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
