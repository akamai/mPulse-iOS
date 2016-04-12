//
//  MPHttpRequestTests.m
//  Boomerang
//
//  Created by Shilpi Nayak on 6/25/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPBeaconCollector.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPBeaconTestBase.h"
#import "MPHttpRequestTestBase.h"

@implementation MPHttpRequestTestBase
//
// Constants
//

//
// URLs
//
// A good URL
NSString *const SUCCESS_URL = @"http://67.111.67.24:8080/concerto/DevTest/delay?timeToDelay=3000";

// A URL that redirects
NSString *const REDIRECT_URL = @"http://67.111.67.24:8080/concerto";

// A 404 URL
NSString *const PAGENOTFOUND_URL = @"http://67.111.67.24:8080/concertoXYZ";

// A URL where the port isn't listening
NSString *const CONNECTION_REFUSED_URL = @"http://67.111.67.24:1200/concertoXYZ";

// An unknown host
NSString *const UNKNOWN_HOST_URL = @"http://bearsbearsbears123.com/";

// A port where the connection couldn't be initiated
NSString *const CONNECTION_TIMEOUT_URL = @"http://1.2.3.4:8080/concerto";

// A port where the socket is delayed in sending a response
NSString *const SOCKET_TIMEOUT_URL = @"http://67.111.67.24:8080/concerto/DevTest/delay?timeToDelay=300000";

// A URL where the download takes too long (chunked-data)
NSString *const LONG_DOWNLOAD_URL = @"http://67.111.67.24:8080/concerto/DevTest/chunkedResponse?chunkSize=100&chunkCount=1000000&chunkDelay=100";

//
// Timeouts
//

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
int const BEACON_ADD_WAIT = 5;

// How long to set the socket to timeout
int const SOCKET_TIMEOUT_INTERVAL = 5;

// Loop time out for connections that delegate.  On iOS <= 4, some actions may
// take 300 seconds (5 minutes) to timeout, especially on devices (vs. emulator).
// Set to a safe value (6 minutes) to ensure we capture them in any environment.
int const LOOP_TIMEOUT = 360;

// Wait for download to start
int const DOWNLOAD_START_WAIT = 5;

// Skip Network Error Code check
int const SKIP_NETWORK_ERROR_CODE_CHECK = 9999;

// HTTP 404 = Page Not Found
short const HTTP_ERROR_PAGE_NOT_FOUND = 404;

// NSURL Success Code
short const NSURLSUCCESS = 0;

/**
 * Class setup
 */
-(void) setUp
{
  [super setUp];
}

/**
 * Checks if the records collected by MPBeaconCollector have the desired number of beacons, network request duration,
 * url and network error code
 */
-(void) responseBeaconTest:(NSString *)url
               minDuration:(long)minDuration
          networkErrorCode:(short)networkErrorCode
{
  NSMutableArray *testBeacons = [[MPBeaconCollector sharedInstance] getBeacons];
  
  XCTAssertNotEqual(testBeacons, nil);
  
  // ensure there isn't a rogue AppLaunch beacon, and if so, remove it first
  if ([testBeacons count] >= 1)
  {
    if ([[testBeacons objectAtIndex:0] getBeaconType] == APP_LAUNCH)
    {
      [testBeacons removeObjectAtIndex:0];
    }
  }

  // beacon count
  XCTAssertEqual([testBeacons count], 1, "Beacons count incorrect");
  
  if ([testBeacons count] != 1)
  {
    // don't know up if there are no beacons
    return;
  }
  
  // ensure it's a network beacon
  XCTAssertEqual(API_NETWORK_REQUEST, [[testBeacons objectAtIndex:0] getBeaconType]);
  
  MPApiNetworkRequestBeacon *beacon = [testBeacons objectAtIndex:0];
  
  MPLogDebug(@"Network Request URL : %@ Duration : %d Error Code %d",
             beacon.url,
             beacon.duration,
             beacon.networkErrorCode);
  
  XCTAssertEqualObjects(beacon.url, url, @" Wrong URL string");
  
  if (minDuration > 0)
  {
    XCTAssertTrue((beacon.duration) >= minDuration, "Network request duration");
  }
  
  if (networkErrorCode != SKIP_NETWORK_ERROR_CODE_CHECK)
  {
    // if the test is done via VPN, the actual error code may differ below
    if (networkErrorCode == NSURLErrorCannotConnectToHost || networkErrorCode == NSURLErrorTimedOut)
    {
      // allow for either error, which are very similar
      XCTAssertTrue(beacon.networkErrorCode == NSURLErrorCannotConnectToHost ||
                    beacon.networkErrorCode == NSURLErrorTimedOut , "Wrong network error code");
    }
    else
    {
      XCTAssertEqual(beacon.networkErrorCode, networkErrorCode, "Wrong network error code");
    }
  }
}

/**
 * Waits for at least one beacon to show up, or, the timeout to be reached
 *
 * @param timeOut Timeout (in seconds)
 */
-(void) waitForBeacon:(int)timeOut
{
  NSLog(@"Waiting up to %d seconds for a beacon...", timeOut);
  
  // keep track of when we started
  NSDate *startTime = [NSDate date];
  
  NSDate *now = startTime;
  
  while ([now timeIntervalSinceDate:startTime] < timeOut)
  {
    // sleep for one second first
    [NSThread sleepForTimeInterval:1];
    
    now = [NSDate date];
    
    // look for beacons
    NSArray *testBeacons = [[MPBeaconCollector sharedInstance] getBeacons];
    
    if ([testBeacons count] > 0)
    {
      // determine how long it took
      int took = [now timeIntervalSinceDate:startTime];
      
      NSLog(@"Waited %d seconds for a beacon!", took);
      return;
    }
  }
  
  // hit the time limit, return
  NSLog(@"Waited %d seconds for a beacon, but nothing showed up!", timeOut);
}

@end
