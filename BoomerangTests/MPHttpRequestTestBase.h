//
//  MPHttpRequestTestBase.h
//  Boomerang
//
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPBeaconTestBase.h"

@interface MPHttpRequestTestBase : MPBeaconTestBase
{
}

//
// Public functions
//

/**
 * Class setup
 */
-(void) setUp;

/**
 * Checks if the records collected by MPBeaconCollector have the desired number of beacons, network request duration,
 * url and network error code
 */
-(void) responseBeaconTest:(NSString *)url
               minDuration:(long)minDuration
          networkErrorCode:(short)networkErrorCode;
/**
 * Ensures no beacons were sent
 */
-(void) assertNoBeacons;

/**
 * Waits for at least one beacon to show up, or, the timeout to be reached
 *
 * @param timeOut Timeout (in seconds)
 */
-(void) waitForBeacon:(int)timeOut;

//
// Constants
//

//
// URLs
//
// A good URL
extern NSString *const SUCCESS_URL;

// A good URL with little delay
extern NSString *const QUICK_SUCCESS_URL;

// A URL that redirects
extern NSString *const REDIRECT_URL;

// A 404 URL
extern NSString *const PAGENOTFOUND_URL;

// A URL where the port isn't listening
extern NSString *const CONNECTION_REFUSED_URL;

// An unknown host
extern NSString *const UNKNOWN_HOST_URL;

// A port where the connection couldn't be initiated
extern NSString *const CONNECTION_TIMEOUT_URL;

// A port where the socket is delayed in sending a response
extern NSString *const SOCKET_TIMEOUT_URL;

// A URL where the download takes too long (chunked-data)
extern NSString *const LONG_DOWNLOAD_URL;

//
// Timeouts
//

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
extern int const BEACON_ADD_WAIT;

// How long to set the socket to timeout
extern int const SOCKET_TIMEOUT_INTERVAL;

// Loop time out for connections that delegate.  On iOS <= 4, some actions may
// take 300 seconds (5 minutes) to timeout, especially on devices (vs. emulator).
// Set to a safe value (6 minutes) to ensure we capture them in any environment.
extern int const LOOP_TIMEOUT;

// Wait for download to start
extern int const DOWNLOAD_START_WAIT;

// Skip Network Error Code check
extern int const SKIP_NETWORK_ERROR_CODE_CHECK;

// HTTP 404 = Page Not Found
extern short const HTTP_ERROR_PAGE_NOT_FOUND;

// NSURL Success Code
extern short const NSURLSUCCESS;

@end