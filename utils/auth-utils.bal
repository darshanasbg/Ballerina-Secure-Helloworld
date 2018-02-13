package utils;

import ballerina.config;
import ballerina.log;

@Description {value:"Configuration entry to check if a cache is enabled"}
const string CACHE_ENABLED = "enabled";
@Description {value:"Configuration entry for cache expiry time"}
const string CACHE_EXPIRY_TIME = "expiryTime";
@Description {value:"Configuration entry for cache capacity"}
const string CACHE_CAPACITY = "capacity";
@Description {value:"Configuration entry for eviction factor"}
const string CACHE_EVICTION_FACTOR = "evictionFactor";

@Description {value:"Default value for enabling cache"}
const boolean CACHE_ENABLED_DEFAULT_VALUE = true;
@Description {value:"Default value for cache expiry"}
const int CACHE_EXPIRY_DEFAULT_VALUE = 300000;
@Description {value:"Default value for cache capacity"}
const int CACHE_CAPACITY_DEFAULT_VALUE = 100;
@Description {value:"Default value for cache eviction factor"}
const float CACHE_EVICTION_FACTOR_DEFAULT_VALUE = 0.25;

@Description {value:"Checks if the specified cache is enalbed"}
@Param {value:"cacheName: cache name"}
@Return {value:"boolean: true of the cache is enabled, else false"}
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

@Description {value:"Reads the cache configurations"}
@Param {value:"cacheName: cache name"}
@Return {value:"int: cache expiry time"}
@Return {value:"int: cache capacity"}
@Return {value:"float: cache eviction factor"}
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

    log:printDebug(cacheName + " enabled with parameters expiryTime: " + intExpiryTime + ", capacity: " +
                  intCapacity + ", eviction factor: " + floatEvictionFactor);
    return intExpiryTime, intCapacity, floatEvictionFactor;
}
