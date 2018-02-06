# Ballerina-Secure-Helloworld
Hello World service written in Ballerina (https://ballerinalang.org/), secured with Basic authentication.

### How to use
1. Add usernames and passwords in ballerina.conf file (see file content for examples)
2. Start the service with the following command:
   ```
   ballerina run secure-helloworld.bal
   ```
3. Invoke the service with the correct basic authenication header, relevant to your username and passwrod:
   ```
   curl -v -H "Authorization: Basic xxxxx" http://localhost:9090/helloWorld/sayHello
   ```   
