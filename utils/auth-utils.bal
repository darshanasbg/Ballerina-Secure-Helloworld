package utils;

import ballerina.config;
import ballerina.log;

const string CACHE_ENABLED = "enabled";
const string CACHE_EXPIRY_TIME = "expiryTime";
const string CACHE_CAPACITY = "capacity";
const string CACHE_EVICTION_FACTOR = "evictionFactor";

const boolean CACHE_ENABLED_DEFAULT_VALUE = true;
const int CACHE_EXPIRY_DEFAULT_VALUE = 300000;
const int CACHE_CAPACITY_DEFAULT_VALUE = 100;
const float CACHE_EVICTION_FACTOR_DEFAULT_VALUE = 0.25;

public function isCacheEnabled (string cacheName) (boolean) {
    string isCacheEnabled = config:getInstanceValue(cacheName, CACHE_ENABLED);
    boolean boolIsCacheEnabled;
    if (isCacheEnabled == null) {
        // by default we enable the cache
        boolIsCacheEnabled = CACHE_ENABLED_DEFAULT_VALUE;
    } else {
        TypeConversionError typeConversionErr;
        boolIsCacheEnabled, typeConversionErr = <boolean> isCacheEnabled;
        if (typeConversionErr != null) {
            boolIsCacheEnabled = CACHE_ENABLED_DEFAULT_VALUE;
        }
    }
    return boolIsCacheEnabled;
}

public function getCacheConfigurations (string cacheName) (int, int, float) {
    // expiry time
    string expiryTime = config:getInstanceValue(cacheName, CACHE_EXPIRY_TIME);
    int intExpiryTime;
    if (expiryTime == null) {
        // set the default
        intExpiryTime = CACHE_EXPIRY_DEFAULT_VALUE;
    } else {
        TypeConversionError typeConversionErr;
        intExpiryTime, typeConversionErr = <int> expiryTime;
        if (typeConversionErr != null) {
            intExpiryTime = CACHE_EXPIRY_DEFAULT_VALUE;
        }
    }
    // capacity
    string capacity = config:getInstanceValue(cacheName, CACHE_CAPACITY);
    int intCapacity;
    if (capacity == null) {
        intCapacity = CACHE_CAPACITY_DEFAULT_VALUE;
    } else {
        TypeConversionError typeConversionErr;
        intCapacity, typeConversionErr = <int> capacity;
        if (typeConversionErr != null) {
            intCapacity = CACHE_CAPACITY_DEFAULT_VALUE;
        }
    }
    // eviction factor
    string evictionFactor = config:getInstanceValue(cacheName, CACHE_EVICTION_FACTOR);
    float floatEvictionFactor;
    if (evictionFactor == null) {
        floatEvictionFactor = CACHE_EVICTION_FACTOR_DEFAULT_VALUE;
    }  else {
        TypeConversionError typeConversionErr;
        floatEvictionFactor, typeConversionErr = <float> evictionFactor;
        if (typeConversionErr != null || floatEvictionFactor > 1.0) {
            floatEvictionFactor = CACHE_EVICTION_FACTOR_DEFAULT_VALUE;
        }
    }

    log:printInfo(cacheName + " enabled with parameters expiryTime: " + intExpiryTime + ", capacity: " +
                  intCapacity + ", eviction factor: " + floatEvictionFactor);
    return intExpiryTime, intCapacity, floatEvictionFactor;
}
