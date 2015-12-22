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
#import "MPInterceptURLConnectionDelegate.h"
#import "MPInterceptURLSessionDelegate.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPHttpRequestDelegateHelper.h"
#import "MPBeaconTestBase.h"

@interface MPHttpRequestTests : MPBeaconTestBase<NSURLSessionTaskDelegate>
{
  MPHttpRequestDelegateHelper *requestHelper;
}

@end

@implementation MPHttpRequestTests
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
static int const BEACON_ADD_WAIT = 5;

// How long to set the socket to timeout
static int const SOCKET_TIMEOUT_INTERVAL = 10;

// Loop time out for connections that delegate.  On iOS <= 4, some actions may
// take 300 seconds (5 minutes) to timeout, especially on devices (vs. emulator).
// Set to a safe value (6 minutes) to ensure we capture them in any environment.
static int const LOOP_TIMEOUT = 360;

// Wait for download to start
static int const DOWNLOAD_START_WAIT = 5;

// Skip Network Error Code check
static int const SKIP_NETWORK_ERROR_CODE_CHECK = 9999;

// HTTP 404 = Page Not Found
static short const HTTP_ERROR_PAGE_NOT_FOUND = 404;

// NSURL Success Code
static short const NSURLSUCCESS = 0;

-(void) setUp
{
  [super setUp];
  
  // Intialization of BoomerangURLSessionDelegate
  [MPInterceptURLSessionDelegate sharedInstance];
  
  // Intialization of BoomerangURLConnectionDelegate
  [MPInterceptURLConnectionDelegate sharedInstance];
  
  // Initialize MPHttpRequestDelegateHelper for delegation
  requestHelper = [[MPHttpRequestDelegateHelper alloc] init];
}

#pragma mark -
#pragma mark Response XCTests

/*
 * Checks if the records collected by MPBeaconCollector have the desired number of beacons, network request duration,
 * url and network error code
 * called after each NSURLConnection methods
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

#pragma mark -
#pragma mark NSURLConnection methods

-(void) syncRequest:(NSString *)urlString
          isSuccess:(BOOL)isSuccess
      checkResponse:(BOOL)checkResponse
     responseString:(NSString *)responseString
{
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
  
  // check for error and fail if success is expected
  if (error != nil)
  {
    MPLogDebug(@"Request failed. %@", error);
    
    if (isSuccess)
    {
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  
  // verify response text if asked for
  if (checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) connectionWithRequest:(NSString *)urlString
                    isSuccess:(BOOL)isSuccess
                checkResponse:(BOOL)checkResponse
               responseString:(NSString *)responseString
{
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:requestHelper];
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:LOOP_TIMEOUT];
  
  while (![requestHelper finished])
  {
    // Not finished yet.
    
    // Give the asynchronous HTTP request some time to work.
    
    // This will return if either:
    // (a) the HTTP request status changes in any way
    // (b) we time out.
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
  }
  
  // check for error and fail if success is expected
  if ([requestHelper error] != nil || connection == nil)
  {
    
    if (isSuccess)
    {
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  
  // verify response text if asked for
  if (checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  
  // sleep - wating for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) asyncRequest:(NSString *)urlString
           isSuccess:(BOOL)isSuccess
       checkResponse:(BOOL)checkResponse
      responseString:(NSString *)responseString
{
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                          timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  [NSURLConnection sendAsynchronousRequest:urlRequest
                                     queue:queue
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
   {
     // check for error and fail if success is expected
     if (error != nil)
     {
       MPLogDebug(@"Request failed. %@", error);
       if (isSuccess)
       {
         XCTFail("Request Failed in function @%s", __FUNCTION__);
       }
     }
     
     // verify response text if asked for
     if (checkResponse)
     {
       NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
       MPLogDebug( @"Response data: %@" , dataString);
       XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
     }
   }];
  
  // sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) initWithRequestStartImmediatelyYes:(NSString *)urlString
                                 isSuccess:(BOOL)isSuccess
                             checkResponse:(BOOL)checkResponse
                            responseString:(NSString *)responseString
{
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:requestHelper];
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:LOOP_TIMEOUT];
  
  while (![requestHelper finished])
  {
    // Not finished yet.
    
    // Give the asynchronous HTTP request some time to work.
    
    // This will return if either:
    // (a) the HTTP request status changes in any way
    // (b) we time out.
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
  }
  
  // check for error and fail if success is expected
  if ([requestHelper error] != nil || connection == nil)
  {
    
    if (isSuccess)
    {
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  
  // verify response text if asked for
  if (checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  
  // sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) initWithRequestStartImmediatelyNo:(NSString *)urlString
                                isSuccess:(BOOL)isSuccess
                            checkResponse:(BOOL)checkResponse
                           responseString:(NSString *)responseString
{
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
  
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest
                                                                delegate:requestHelper
                                                        startImmediately:NO];
  
  [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [connection start];
  
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:LOOP_TIMEOUT];
  
  while (![requestHelper finished])
  {
    // Not finished yet.
    
    // Give the asynchronous HTTP request some time to work.
    
    // This will return if either:
    // (a) the HTTP request status changes in any way
    // (b) we time out.
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
  }
  
  // check for error and fail if success is expected
  if ([requestHelper error] != nil)
  {
    
    if (isSuccess)
    {
      XCTFail("Request Failed in function @%s. Success expected", __FUNCTION__);
    }
  }
  
  // verify response text if asked for
  if (checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  
  // sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

#pragma mark -
#pragma mark SynchronousConnection Tests

-(void) testSyncRequestSuccess
{
  // Send Synchronous Request
  [self syncRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success with duration more than 3 sec
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testSyncRequestSuccessHTTPRedirect
{
  // Send Synchronous Request
  [self syncRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testSyncRequestFailHTTPError
{
  // Send Synchronous Request
  [self syncRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testSyncRequestConnectionRefused
{
  // Send Synchronous Request
  [self syncRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

-(void) testSyncRequestUnknownHost
{
  // Send Synchronous Request
  [self syncRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testSyncRequestConnectionTimeOut
{
  // Send Synchronous Request
  [self syncRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testSyncRequestSocketTimeOut
{
  // Send Synchronous Request
  [self syncRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark ConnectionWithRequest Tests

-(void) testConnectionWithRequestSuccess
{
  // create connectionWithRequest
  [self connectionWithRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success with duration more than 3000 ms
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testConnectionWithRequestSuccessHTTPRedirect
{
  // create connectionWithRequest
  [self connectionWithRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testConnectionWithRequestFailHTTPError
{
  // create connectionWithRequest
  [self connectionWithRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testConnectionWithRequestConnectionRefused
{
  // create connectionWithRequest
  [self connectionWithRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

-(void) testConnectionWithRequestUnknownHost
{
  // create connectionWithRequest
  [self connectionWithRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testConnectionWithRequestConnectionTimeOut
{
  // create connectionWithRequest
  [self connectionWithRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testConnectionWithRequestSocketTimeOut
{
  // create connectionWithRequest
  [self connectionWithRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark AsynchronousConnection Tests

-(void) testAsyncRequestSuccess
{
  // send Asynchronous Request
  [self asyncRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testAsyncRequestSuccessHTTPRedirect
{
  // send Asynchronous Request
  [self asyncRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testAsyncRequestFailHTTPError
{
  // send Asynchronous Request
  [self asyncRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testAsyncRequestConnectionRefused
{
  // send Asynchronous Request
  [self asyncRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  // Test for failure
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

-(void) testAsyncRequestUnknownHost
{
  // send Asynchronous Request
  [self asyncRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testAsyncRequestConnectionTimeOut
{
  // send Asynchronous Request
  [self asyncRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testAsyncRequestSocketTimeOut
{
  // send Asynchronous Request
  [self asyncRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  // Test for failure
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark initWithRequestStartImmediatelyYes Tests

-(void) testInitWithRequestStartImmediatelyYesSuccess
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testInitWithRequestStartImmediatelyYesSuccessHTTPRedirect
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testInitWithRequestStartImmediatelyYesFailHTTPError
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testInitWithRequestStartImmediatelyYesConnectionRefused
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

-(void) testInitWithRequestStartImmediatelyYesUnknownHost
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testInitWithRequestStartImmediatelyYesConnectionTimeOut
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testInitWithRequestStartImmediatelyYesSocketTimeOut
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark initWithRequestStartImmediatelyNo Tests

-(void) testInitWithRequestStartImmediatelyNoSuccess
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyYes:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // test for success with duration more than 3000 ms
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testInitWithRequestStartImmediatelyNoSuccessHTTPRedirect
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyNo:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testInitWithRequestStartImmediatelyNoFailHTTPError
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyNo:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testInitWithRequestStartImmediatelyNoConnectionRefused
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyNo:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

-(void) testInitWithRequestStartImmediatelyNoUnknownHost
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyNo:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testInitWithRequestStartImmediatelyNoConnectionTimeOut
{
  // create connection - start response later
  [self initWithRequestStartImmediatelyNo:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testInitWithRequestStartImmediatelyNoSocketTimeOut
{
  // create connection - start response immediately
  [self initWithRequestStartImmediatelyNo:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark NSURLSession methods

-(void) dataTaskWithRequest:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for dataTaskWithRequest: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) dataTaskWithRequestCompletionHandler:(NSString *)urlString
                                   isSuccess:(BOOL)isSuccess
                               checkResponse:(BOOL)checkResponse
                              responseString:(NSString *)responseString
                                        done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    [self checkDataResponse:data
                   response:response
                      error:error
                  isSuccess:isSuccess
              checkResponse:checkResponse
             responseString:responseString
                       done:done];
  }];
  
  // start the task
  [task resume];
}

-(void) dataTaskWithURL:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for dataTaskWithURL: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDataTask *task = [session dataTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) dataTaskWithURLCompletionHandler:(NSString *)urlString
                               isSuccess:(BOOL)isSuccess
                           checkResponse:(BOOL)checkResponse
                          responseString:(NSString *)responseString
                                    done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    [self checkDataResponse:data
                   response:response
                      error:error
                  isSuccess:isSuccess
              checkResponse:checkResponse
             responseString:responseString
                       done:done];
  }];
  
  // start the task
  [task resume];
}

-(void) uploadTaskWithRequestFromFile:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for uploadTaskWithRequest:fromFile: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromFile:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) uploadTaskWithRequestFromFileCompletionHandler:(NSString *)urlString
                                             isSuccess:(BOOL)isSuccess
                                         checkResponse:(BOOL)checkResponse
                                        responseString:(NSString *)responseString
                                                  done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request
                                                       fromFile:url
                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                [self checkDataResponse:data
                                                               response:response
                                                                  error:error
                                                              isSuccess:isSuccess
                                                          checkResponse:checkResponse
                                                         responseString:responseString
                                                                   done:done];
                                              }];
  
  // start the task
  [task resume];
}

-(void) uploadTaskWithRequestFromData:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for uploadTaskWithRequest:fromData: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromData:[[NSData alloc] init]];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) uploadTaskWithRequestFromDataCompletionHandler:(NSString *)urlString
                                             isSuccess:(BOOL)isSuccess
                                         checkResponse:(BOOL)checkResponse
                                        responseString:(NSString *)responseString
                                                  done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request
                                                       fromData:[[NSData alloc] init]
                                              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                [self checkDataResponse:data
                                                               response:response
                                                                  error:error
                                                              isSuccess:isSuccess
                                                          checkResponse:checkResponse
                                                         responseString:responseString
                                                                   done:done];
                                              }];
  
  // start the task
  [task resume];
}

-(void) downloadTaskWithRequest:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for downloadTaskWithRequest: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) downloadTaskWithRequestCompletionHandler:(NSString *)urlString
                                       isSuccess:(BOOL)isSuccess
                                   checkResponse:(BOOL)checkResponse
                                  responseString:(NSString *)responseString
                                            done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
    [self checkDataResponse:nil
                   response:response
                      error:error
                  isSuccess:isSuccess
              checkResponse:checkResponse
             responseString:responseString
                       done:done];
  }];
  
  // start the task
  [task resume];
}

-(void) downloadTaskWithURL:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  // NOTE they're specifically asking for downloadTaskWithURL: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) downloadTaskWithURLCompletionHandler:(NSString *)urlString
                                   isSuccess:(BOOL)isSuccess
                               checkResponse:(BOOL)checkResponse
                              responseString:(NSString *)responseString
                                        done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
    [self checkDataResponse:nil
                   response:response
                      error:error
                  isSuccess:isSuccess
              checkResponse:checkResponse
             responseString:responseString
                       done:done];
  }];
  
  // start the task
  [task resume];
}

-(void) uploadTaskWithStreamedRequest:(NSString *)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                     timeoutInterval:SOCKET_TIMEOUT_INTERVAL];
  
  [request setHTTPMethod:@"POST"];
  
  // start with a default configuration
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  
  // create a session with ourself as a delegate
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                        delegate:self
                                                   delegateQueue:nil];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = SOCKET_TIMEOUT_INTERVAL;
  session.configuration.timeoutIntervalForResource = SOCKET_TIMEOUT_INTERVAL;
  
  // NOTE they're specifically asking for uploadTaskWithStreamedRequest, which doesn't a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask *task = [session uploadTaskWithStreamedRequest:request];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

-(void) URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
}

-(void) URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
  NSString *str = @"test";
  NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
  NSInputStream *stream = [NSInputStream inputStreamWithData:data];
  completionHandler(stream);
}

-(void) checkDataResponse:(NSData *)data
                 response:(NSURLResponse *)response
                    error:(NSError *)error
                isSuccess:(BOOL)isSuccess
            checkResponse:(BOOL)checkResponse
           responseString:(NSString *)responseString
                     done:(void (^)())done
{
  // check for error and fail if success is expected
  if (error != nil)
  {
    MPLogDebug(@"Request failed. %@", error);
    
    if (isSuccess)
    {
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  
  // verify response text if asked for
  if (checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    MPLogDebug(@"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  if (done != nil)
  {
    done();
  }
}

#pragma mark -
#pragma mark NSURLSession Tests
#pragma mark -
#pragma mark #pragma mark dataTaskWithRequest:

-(void) testDataTaskWithRequestSuccess
{
  [self dataTaskWithRequest:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testDataTaskWithRequestHTTPRedirect
{
  [self dataTaskWithRequest:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testDataTaskWithRequestFailHTTPError
{
  [self dataTaskWithRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testDataTaskWithRequestConnectionRefused
{
  [self dataTaskWithRequest:CONNECTION_REFUSED_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDataTaskWithRequestUnknownHost
{
  [self dataTaskWithRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDataTaskWithRequestConnectionTimeOut
{
  [self dataTaskWithRequest:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

-(void) testDataTaskWithRequestSocketTimeOut
{
  [self dataTaskWithRequest:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithRequest:completionHandler:

-(void) testDataTaskWithRequestCompetionHandlerSuccess
{
  [self dataTaskWithRequestCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerHTTPRedirect
{
  [self dataTaskWithRequestCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerFailHTTPError
{
  [self dataTaskWithRequestCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerConnectionRefused
{
  [self dataTaskWithRequestCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerUnknownHost
{
  [self dataTaskWithRequestCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerConnectionTimeOut
{
  [self dataTaskWithRequestCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithRequestCompetionHandlerSocketTimeOut
{
  [self dataTaskWithRequestCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithURL:

-(void) testDataTaskWithURLSuccess
{
  [self dataTaskWithURL:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testDataTaskWithURLHTTPRedirect
{
  [self dataTaskWithURL:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testDataTaskWithURLFailHTTPError
{
  [self dataTaskWithURL:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testDataTaskWithURLConnectionRefused
{
  [self dataTaskWithURL:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDataTaskWithURLUnknownHost
{
  [self dataTaskWithURL:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDataTaskWithURLConnectionTimeOut
{
  [self dataTaskWithURL:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDataTaskWithURLSocketTimeOut
{
  [self dataTaskWithURL:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithURL:completionHandler:

-(void) testDataTaskWithURLCompetionHandlerSuccess
{
  [self dataTaskWithURLCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerHTTPRedirect
{
  [self dataTaskWithURLCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerFailHTTPError
{
  [self dataTaskWithURLCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerConnectionRefused
{
  [self dataTaskWithURLCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerUnknownHost
{
  [self dataTaskWithURLCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerConnectionTimeOut
{
  [self dataTaskWithURLCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDataTaskWithURLCompetionHandlerSocketTimeOut
{
  [self dataTaskWithURLCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:fromFile:

-(void) testUploadTaskWithRequestFromFileSuccess
{
  [self uploadTaskWithRequestFromFile:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithRequestFromFileHTTPRedirect
{
  [self uploadTaskWithRequestFromFile:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithRequestFromFileFailHTTPError
{
  [self uploadTaskWithRequestFromFile:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testUploadTaskWithRequestFromFileConnectionRefused
{
  [self uploadTaskWithRequestFromFile:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromFileUnknownHost
{
  [self uploadTaskWithRequestFromFile:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromFileConnectionTimeOut
{
  [self uploadTaskWithRequestFromFile:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromFileSocketTimeOut
{
  [self uploadTaskWithRequestFromFile:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:completionHandler:

-(void) testUploadTaskWithRequestFromFileCompetionHandlerSuccess
{
  [self uploadTaskWithRequestFromFileCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerHTTPRedirect
{
  [self uploadTaskWithRequestFromFileCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerFailHTTPError
{
  [self uploadTaskWithRequestFromFileCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerConnectionRefused
{
  [self uploadTaskWithRequestFromFileCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerUnknownHost
{
  [self uploadTaskWithRequestFromFileCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerConnectionTimeOut
{
  [self uploadTaskWithRequestFromFileCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromFileCompetionHandlerSocketTimeOut
{
  [self uploadTaskWithRequestFromFileCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:fromData:

-(void) testUploadTaskWithRequestFromDataSuccess
{
  [self uploadTaskWithRequestFromData:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithRequestFromDataHTTPRedirect
{
  [self uploadTaskWithRequestFromData:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithRequestFromDataFailHTTPError
{
  [self uploadTaskWithRequestFromData:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testUploadTaskWithRequestFromDataConnectionRefused
{
  [self uploadTaskWithRequestFromData:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromDataUnknownHost
{
  [self uploadTaskWithRequestFromData:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromDataConnectionTimeOut
{
  [self uploadTaskWithRequestFromData:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithRequestFromDataSocketTimeOut
{
  [self uploadTaskWithRequestFromData:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:completionHandler:

-(void) testUploadTaskWithRequestFromDataCompetionHandlerSuccess
{
  [self uploadTaskWithRequestFromDataCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerHTTPRedirect
{
  [self uploadTaskWithRequestFromDataCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerFailHTTPError
{
  [self uploadTaskWithRequestFromDataCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerConnectionRefused
{
  [self uploadTaskWithRequestFromDataCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerUnknownHost
{
  [self uploadTaskWithRequestFromDataCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerConnectionTimeOut
{
  [self uploadTaskWithRequestFromDataCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testUploadTaskWithRequestFromDataCompetionHandlerSocketTimeOut
{
  [self uploadTaskWithRequestFromDataCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithSteamedRequest:

-(void) testUploadTaskWithStreamedRequestSuccess
{
  [self uploadTaskWithStreamedRequest:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithStreamedRequestHTTPRedirect
{
  [self uploadTaskWithStreamedRequest:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testUploadTaskWithStreamedRequestFailHTTPError
{
  [self uploadTaskWithStreamedRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testUploadTaskWithStreamedRequestConnectionRefused
{
  [self uploadTaskWithStreamedRequest:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithStreamedRequestUnknownHost
{
  [self uploadTaskWithStreamedRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithStreamedRequestConnectionTimeOut
{
  [self uploadTaskWithStreamedRequest:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testUploadTaskWithStreamedRequestSocketTimeOut
{
  [self uploadTaskWithStreamedRequest:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithRequest:

-(void) testDownloadTaskWithRequestSuccess
{
  [self downloadTaskWithRequest:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testDownloadTaskWithRequestHTTPRedirect
{
  [self downloadTaskWithRequest:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testDownloadTaskWithRequestFailHTTPError
{
  [self downloadTaskWithRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testDownloadTaskWithRequestConnectionRefused
{
  [self downloadTaskWithRequest:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithRequestUnknownHost
{
  [self downloadTaskWithRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithRequestConnectionTimeOut
{
  [self downloadTaskWithRequest:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithRequestSocketTimeOut
{
  [self downloadTaskWithRequest:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithRequest:completionHandler:

-(void) testDownloadTaskWithRequestCompetionHandlerSuccess
{
  [self downloadTaskWithRequestCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerHTTPRedirect
{
  [self downloadTaskWithRequestCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerFailHTTPError
{
  [self downloadTaskWithRequestCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerConnectionRefused
{
  [self downloadTaskWithRequestCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerUnknownHost
{
  [self downloadTaskWithRequestCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerConnectionTimeOut
{
  [self downloadTaskWithRequestCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithRequestCompetionHandlerSocketTimeOut
{
  [self downloadTaskWithRequestCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithURL:

-(void) testDownloadTaskWithURLSuccess
{
  [self downloadTaskWithURL:SUCCESS_URL];
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testDownloadTaskWithURLHTTPRedirect
{
  [self downloadTaskWithURL:REDIRECT_URL];
  [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
}

-(void) testDownloadTaskWithURLFailHTTPError
{
  [self downloadTaskWithURL:PAGENOTFOUND_URL];
  [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
}

-(void) testDownloadTaskWithURLConnectionRefused
{
  [self downloadTaskWithURL:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithURLUnknownHost
{
  [self downloadTaskWithURL:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithURLConnectionTimeOut
{
  [self downloadTaskWithURL:CONNECTION_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

-(void) testDownloadTaskWithURLSocketTimeOut
{
  [self downloadTaskWithURL:SOCKET_TIMEOUT_URL];
  
  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];
  
  [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithURL:completionHandler:

-(void) testDownloadTaskWithURLCompetionHandlerSuccess
{
  [self downloadTaskWithURLCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerHTTPRedirect
{
  [self downloadTaskWithURLCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:REDIRECT_URL minDuration:0 networkErrorCode:NSURLSUCCESS];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerFailHTTPError
{
  [self downloadTaskWithURLCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:PAGENOTFOUND_URL minDuration:0 networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerConnectionRefused
{
  [self downloadTaskWithURLCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_REFUSED_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerUnknownHost
{
  [self downloadTaskWithURLCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_HOST_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerConnectionTimeOut
{
  [self downloadTaskWithURLCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_URL minDuration:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

-(void) testDownloadTaskWithURLCompetionHandlerSocketTimeOut
{
  [self downloadTaskWithURLCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:SOCKET_TIMEOUT_URL minDuration:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithResumeData:

-(void) testDownloadTaskWithResumeData
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[LONG_DOWNLOAD_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // wait a few seconds for the download to get some bytes
  [NSThread sleepForTimeInterval:DOWNLOAD_START_WAIT];
  
  // cancel the download
  [task cancelByProducingResumeData:^(NSData *resumeData) {
    XCTAssert(resumeData != nil, @"Need resumeData");
    
    if (resumeData)
    {
      NSURLSessionDownloadTask *secondTask = [session downloadTaskWithResumeData:resumeData];
      
      // start downloading again
      [secondTask resume];
      
      // don't need to wait for bytes, just cancel after a second
      [NSThread sleepForTimeInterval:1];
      
      [secondTask cancelByProducingResumeData:^(NSData *secondResumeData) {
        // No more resumeData needed
      }];
    }
  }];
  
  // sleep - waiting for the second download to start, then the beacon to be added
  [NSThread sleepForTimeInterval:(DOWNLOAD_START_WAIT + BEACON_ADD_WAIT)];
  [self validateResumeDataBeacon];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithResumeData:completionHandler:

-(void) testDownloadTaskWithResumeDataCompetionHandler
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[LONG_DOWNLOAD_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession *session = [self getSharedSession];
  
  NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // wait a few seconds for the download to get some bytes
  [NSThread sleepForTimeInterval:DOWNLOAD_START_WAIT];
  
  // cancel the download
  [task cancelByProducingResumeData:^(NSData *resumeData) {
    XCTAssert(resumeData != nil, @"Need resumeData");
    
    if (resumeData)
    {
      // immediately create a task to restart it
      NSURLSessionDownloadTask *secondTask = [session downloadTaskWithResumeData:resumeData
                                                               completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error)
                                              {
                                                [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
                                                [self validateResumeDataBeacon];
                                              }];
      
      // start downloading again
      [secondTask resume];
      
      // don't need to wait for bytes, just cancel after a second
      [NSThread sleepForTimeInterval:1];
      
      [secondTask cancelByProducingResumeData:^(NSData *secondResumeData) {
        // No more resumeData needed
      }];
    }
  }];
  
  // sleep - waiting for the second download to start, then the beacon to be added
  [NSThread sleepForTimeInterval:(DOWNLOAD_START_WAIT + BEACON_ADD_WAIT)];
}

/**
 * Validates beacons from a resumeData test
 */
-(void) validateResumeDataBeacon
{
  NSArray *testBeacons = [[MPBeaconCollector sharedInstance] getBeacons];
  XCTAssert(testBeacons != nil, "Beacons must exist");
  
  if (testBeacons == nil)
  {
    return;
  }
  
  XCTAssertEqual([testBeacons count], 2, "Beacon count incorrect");
  
  if ([testBeacons count] != 1)
  {
    return;
  }
  
  MPApiNetworkRequestBeacon *beacon = [testBeacons objectAtIndex:0];
  
  XCTAssertEqualObjects(beacon.url, LONG_DOWNLOAD_URL, @" Wrong URL string.");
  XCTAssertEqual(beacon.networkErrorCode, NSURLErrorCancelled, "Wrong network error code");
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
  
  NSLog(@"Waited %d seconds for a beacon, but nothing showed up!", timeOut);
  // hit the time limit, return
}

/**
 * Gets a shared NSURLSession with the proper timeouts configured
 *
 * @returns Shared Session
 */
-(NSURLSession *) getSharedSession
{
  // grab the shared session
  NSURLSession *session = [NSURLSession sharedSession];

  // set our timeouts
  session.configuration.timeoutIntervalForRequest = SOCKET_TIMEOUT_INTERVAL;
  session.configuration.timeoutIntervalForResource = SOCKET_TIMEOUT_INTERVAL;
  
  return session;
}

@end
