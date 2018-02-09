package context;

public struct SecurityContext {
    string username;
    string[] roles;
    boolean isAuthenticated;
    map properties;
}