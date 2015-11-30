//
//  MPHttpRequestTests.m
//  Boomerang
//
//  Created by Shilpi Nayak on 6/25/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPBatchRecord.h"
#import "MPBeaconCollector.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPInterceptURLSessionDelegate.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPHttpRequestDelegateHelper.h"

@interface MPHttpRequestTests : XCTestCase <NSURLSessionTaskDelegate>
{
  MPHttpRequestDelegateHelper *requestHelper;
}
@end

@implementation MPHttpRequestTests

NSString * const SUCCESS_URL = @"http://67.111.67.24:8080/concerto/DevTest/delay?timeToDelay=3000";
NSString * const REDIRECT_URL = @"http://67.111.67.24:8080/concerto";
NSString * const PAGENOTFOUND_URL = @"http://67.111.67.24:8080/concertoXYZ";
NSString * const CONNECTION_REFUSED_URL = @"http://67.111.67.24:1200/concertoXYZ";
NSString * const UNKNOWN_HOST_URL = @"http://bearsbearsbears123.com";
NSString * const CONNECTION_TIMEOUT_URL = @"http://1.2.3.4:8080/concerto";
NSString * const SOCKET_TIMEOUT_URL = @"http://67.111.67.24:8080/concerto/DevTest/delay?timeToDelay=300000";
NSString * const BATCH_URL = @"http://67.111.67.24/";
NSString * const CONNECTION_TIMEOUT_BATCH_URL = @"http://1.2.3.4/";
NSString * const UNKNOWN_BATCH_URL = @"http://bearsbearsbears123.com/";
NSString * const LONG_DOWNLOAD_URL = @"http://67.111.67.24:8080/concerto/DevTest/chunkedResponse?chunkSize=100&chunkCount=1000000&chunkDelay=100";
NSString * const LONG_DOWNLOAD_URL_DOMAIN = @"http://67.111.67.24/";

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;
// Timeout is 30 seconds because we are running in simulator
// iOS devices have 4 minute timeout - set this to 300 seconds.
static int const SOCKET_TIMEOUT_ASYNC_WAIT = 30;
// Connection time out : 30 seconds
static int const CONNECTION_TIMEOUT_ASYNC_WAIT = 30;
// Loop time out for connections that delegate
static int const LOOP_TIMEOUT = 300;
// Wait for download to start
static int const DOWNLOAD_START_WAIT = 5;

// Skip Network Error Code check
static int const SKIP_NETWORK_ERROR_CODE_CHECK = 9999;

static short const HTTPERRORPAGENOTFOUND = 404;
static short const NSURLSUCCESS = 0;
static BOOL initializedWithAPIKey = NO;
static BOOL networkRequestComplete = NO;

- (void)setUp
{
  [super setUp];
  
  if (!initializedWithAPIKey)
  {
    [MPulse initializeWithAPIKey:@"K9MSB-TL87R-NA6PR-XZPBL-5SLU5"];
    [self waitForNetworkRequestCompletion];
  }
  else
  {
    [[MPSession sharedInstance] reset];
  }
  
  NSString *responseSample = @"{\"h.key\": \"K9MSB-TL87R-NA6PR-XZPBL-5SLU5\",\"h.d\": \"com.soasta.ios.SampleMPulseApp\",\"h.t\": 1428602384684,\"h.cr\": \"23a0384939e93bbc22af11b74654a82f180f5910\",  \"session_id\": \"5e29a2e6-4017-4fc8-97bc-f5e2a475d6fa\", \"site_domain\": \"com.soasta.ios.SampleMPulseApp\",\"beacon_url\": \"//rum-dev-collector.soasta.com/beacon/\",\"beacon_interval\": 5,\"BW\": {\"enabled\": false},\"RT\": {\"session_exp\": 1800},\"ResourceTiming\": {  \"enabled\": false},\"Angular\": {  \"enabled\": false},\"PageParams\": {\"pageGroups\": [], \"customMetrics\": [{\"name\":\"Metric1\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"cmet.Metric1\",\"dataType\":\"Number\"}],  \"customTimers\": [{\"name\":\"Touch Timer\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"custom0\"},{\"name\":\"Code Timer\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"custom1\"}],  \"customDimensions\": [],\"urlPatterns\": [],\"params\": true},\"user_ip\": \"67.111.67.3\"}";

  // Initialize config object with sample string
  [[MPConfig sharedInstance] initWithResponse:responseSample];

  // Disable Config refresh
  [[MPConfig sharedInstance] setRefreshDisabled:YES];

  // Initialize session object
  [MPSession sharedInstance];

  // Disable batch record sending as the server is not receiving any beacons
  [MPBeaconCollector sharedInstance].disableBatchSending = YES;
  
  // Intialization of BoomerangURLSessionDelegate
  [MPInterceptURLSessionDelegate sharedInstance];

  // Intialization of BoomerangURLConnectionDelegate
  [MPInterceptURLConnectionDelegate sharedInstance];

  // Sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];

  // Clearing beacons before adding
  [[MPBeaconCollector sharedInstance] clearBatch];

  // Initialize MPHttpRequestDelegateHelper for delegation
  requestHelper = [[MPHttpRequestDelegateHelper alloc] init];
  
  initializedWithAPIKey = YES;
}

- (void)tearDown
{
  // Make sure we clean up after ourselves
  [[MPBeaconCollector sharedInstance] clearBatch];
  
  [super tearDown];
}

-(void) waitForNetworkRequestCompletion
{
  networkRequestComplete = NO;
  
  // MPConfig will notify us when network request is complete.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigRefreshCompleteNotification:) name:CONFIG_GET_REQUEST_COMPLETE object:nil];
  
  // Timeout after 30 seconds
  double waitTime = 0.0f;
  while (!networkRequestComplete && waitTime < 30.0f)
  {
    // Sleep until network request completion notification is not received.
    [NSThread sleepForTimeInterval:0.5f];
    waitTime += 0.5f;
  }
  
  // Fail if network request did not complete
  XCTAssertTrue(networkRequestComplete, @"Network request did not complete even after waiting %f seconds", waitTime);
}

-(void) receiveConfigRefreshCompleteNotification:(NSNotification *)notification
{
  networkRequestComplete = YES;
}

#pragma mark -
#pragma mark Response XCTests

/*
 * Checks if the records collected by MPBeaconCollector.have the desired number of beacons, network request duration,
 * url and network error code
 * called after each NSURLConnection methods
 */
- (void) responseBeaconTest: (NSString*)urlString minDuration:(long)minDuration beaconCount:(int)beaconCount
           crashCount:(int)crashCount networkErrorCode:(short)networkErrorCode
{
  NSMutableDictionary *testRecords = [[MPBeaconCollector sharedInstance] records];
  if (testRecords != nil)
  {
    // TODO: Number of records are not the same thing as number of beacons.
    // During these tests, we are only sending 1 beacon, thus the number of records can be compared with number of beacons,
    // but that is not the case in production.
    XCTAssertEqual([testRecords count], beaconCount, "Dictionary size incorrect");
  }
  
  if ([testRecords count] > 0)
  {
    id key = [[testRecords allKeys] objectAtIndex:0];
    MPBatchRecord *record = [testRecords objectForKey:key];
    MPTimerData* networkRequestTimer = [record networkRequestTimer];
    
    MPLogDebug(@"Timer Duration : %ld Beacon Count : %d  Crash Count : %d ", [networkRequestTimer sum] , [record totalBeacons] , [record totalCrashes]);
    MPLogDebug(@"URL : %@ Network Error Code: %hd ", [record url] , [record networkErrorCode]);
    
    XCTAssertTrue([networkRequestTimer sum] >= minDuration, "network request duration error");
    XCTAssertEqual([record totalBeacons], beaconCount, @"Wrong beacon count.");
    XCTAssertEqual([record totalCrashes], crashCount, @"Wrong crash count.");
    XCTAssertEqualObjects([record url], urlString, @" Wrong URL string.");
    
    if (networkErrorCode != SKIP_NETWORK_ERROR_CODE_CHECK)
    {
      XCTAssertTrue([record networkErrorCode] == networkErrorCode, "Wrong network error code");
    }
  }
}

#pragma mark -
#pragma mark NSURLConnection methods

- (void) syncRequest: (NSString*) urlString isSuccess:(BOOL)isSuccess checkResponse:(BOOL)checkResponse responseString: (NSString*) responseString
{
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
  //check for error and fail if success is expected
  if (error != nil)
  {
    MPLogDebug(@"Request failed. %@", error);
    if(isSuccess){
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  //verify response text if asked for
  if(checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  //sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) connectionWithRequest: (NSString*) urlString isSuccess:(BOOL)isSuccess checkResponse:(BOOL)checkResponse responseString: (NSString*) responseString
{
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
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
  //check for error and fail if success is expected
  if ([requestHelper error] != nil || connection == nil)
  {
    if(isSuccess){
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  //verify response text if asked for
  if(checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  //sleep - wating for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) asyncRequest : (NSString*) urlString isSuccess:(BOOL)isSuccess checkResponse:(BOOL)checkResponse responseString: (NSString*) responseString
{
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
   {
     //check for error and fail if success is expected
     if (error != nil)
     {
       MPLogDebug(@"Request failed. %@", error);
       // TODO: Try this
       if(isSuccess){
         XCTFail("Request Failed in function @%s", __FUNCTION__);
       }
     }
     //verify response text if asked for
     if(checkResponse)
     {
       NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
       MPLogDebug( @"Response data: %@" , dataString);
       XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
     }
   }];
  //sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) initWithRequestStartImmediatelyYes : (NSString*) urlString isSuccess:(BOOL)isSuccess checkResponse:(BOOL)checkResponse responseString: (NSString*) responseString
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
  //check for error and fail if success is expected
  if ([requestHelper error] != nil || connection == nil)
  {
    if(isSuccess){
      XCTFail("Request Failed in function @%s", __FUNCTION__);
    }
  }
  //verify response text if asked for
  if(checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  //sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void)initWithRequestStartImmediatelyNo: (NSString*) urlString isSuccess:(BOOL)isSuccess checkResponse:(BOOL)checkResponse responseString: (NSString*) responseString
{
  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
  NSURLConnection * connection = [[NSURLConnection alloc]
                                  initWithRequest:theRequest
                                  delegate:requestHelper startImmediately:NO];
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
  //check for error and fail if success is expected
  if ([requestHelper error] != nil)
  {
    if(isSuccess){
      XCTFail("Request Failed in function @%s. Success expected", __FUNCTION__);
    }
  }
  //verify response text if asked for
  if(checkResponse)
  {
    NSString *dataString = [[NSString alloc] initWithData:[requestHelper responseData] encoding:NSUTF8StringEncoding];
    MPLogDebug( @"Response data: %@" , dataString);
    XCTAssertEqualObjects(dataString, responseString, @" Received wrong response string.");
  }
  //sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

#pragma mark -
#pragma mark SynchronousConnection Tests

- (void)testSyncRequestSuccess
{
  // Send Synchronous Request
  [self syncRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success with duration more than 3 sec
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testSyncRequestSuccessHTTPRedirect
{
  // Send Synchronous Request
  [self syncRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest: BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testSyncRequestFailHTTPError
{
  // Send Synchronous Request
  [self syncRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest: BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testSyncRequestConnectionRefused
{
  // Send Synchronous Request
  [self syncRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest: BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

- (void)testSyncRequestUnknownHost
{
  // Send Synchronous Request
  [self syncRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testSyncRequestConnectionTimeOut
{
  // Send Synchronous Request
  [self syncRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testSyncRequestSocketTimeOut
{
  // Send Synchronous Request
  [self syncRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest: BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark ConnectionWithRequest Tests

- (void)testConnectionWithRequestSuccess
{
  // create connectionWithRequest
  [self connectionWithRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success with duration more than 3000 ms
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testConnectionWithRequestSuccessHTTPRedirect
{
  // create connectionWithRequest
  [self connectionWithRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testConnectionWithRequestFailHTTPError
{
  // create connectionWithRequest
  [self connectionWithRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testConnectionWithRequestConnectionRefused
{
  // create connectionWithRequest
  [self connectionWithRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

- (void)testConnectionWithRequestUnknownHost
{
  // create connectionWithRequest
  [self connectionWithRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testConnectionWithRequestConnectionTimeOut
{
  // create connectionWithRequest
  [self connectionWithRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testConnectionWithRequestSocketTimeOut
{
  // create connectionWithRequest
  [self connectionWithRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark AsynchronousConnection Tests

- (void)testAsyncRequestSuccess
{
  // send Asynchronous Request
  [self asyncRequest:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testAsyncRequestSuccessHTTPRedirect
{
  // send Asynchronous Request
  [self asyncRequest:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testAsyncRequestFailHTTPError
{
  // send Asynchronous Request
  [self asyncRequest:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testAsyncRequestConnectionRefused
{
  // send Asynchronous Request
  [self asyncRequest:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

- (void)testAsyncRequestUnknownHost
{
  // send Asynchronous Request
  [self asyncRequest:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  //sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testAsyncRequestConnectionTimeOut
{
  // send Asynchronous Request
  [self asyncRequest:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  //sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testAsyncRequestSocketTimeOut
{
  // send Asynchronous Request
  [self asyncRequest:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // waiting for 30 seconds for socket timeout because we are running in simulator
  //TODO: should wait for 300 seconds if running on iOS devices.
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark initWithRequestStartImmediatelyYes Tests

- (void)testInitWithRequestStartImmediatelyYesSuccess
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testInitWithRequestStartImmediatelyYesSuccessHTTPRedirect
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testInitWithRequestStartImmediatelyYesFailHTTPError
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testInitWithRequestStartImmediatelyYesConnectionRefused
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

- (void)testInitWithRequestStartImmediatelyYesUnknownHost
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testInitWithRequestStartImmediatelyYesConnectionTimeOut
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testInitWithRequestStartImmediatelyYesSocketTimeOut
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyYes:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark initWithRequestStartImmediatelyNo Tests

- (void)testInitWithRequestStartImmediatelyNoSuccess
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyYes:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds"];
  
  // test for success with duration more than 3000 ms
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testInitWithRequestStartImmediatelyNoSuccessHTTPRedirect
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyNo:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@""];
  
  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testInitWithRequestStartImmediatelyNoFailHTTPError
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyNo:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testInitWithRequestStartImmediatelyNoConnectionRefused
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyNo:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorCannotConnectToHost];
}

- (void)testInitWithRequestStartImmediatelyNoUnknownHost
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyNo:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testInitWithRequestStartImmediatelyNoConnectionTimeOut
{
  //create connection - start response later
  [self initWithRequestStartImmediatelyNo:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testInitWithRequestStartImmediatelyNoSocketTimeOut
{
  //create connection - start response immediately
  [self initWithRequestStartImmediatelyNo:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@""];
  
  // Test for failure
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark NSURLSession methods

- (void) dataTaskWithRequest:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];

  // NOTE they're specifically asking for dataTaskWithRequest: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDataTask* task = [session dataTaskWithRequest:request];
  
  // start the task
  [task resume];

  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) dataTaskWithRequestCompletionHandler:(NSString*)urlString
                                    isSuccess:(BOOL)isSuccess
                                checkResponse:(BOOL)checkResponse
                               responseString:(NSString*)responseString
                                         done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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

- (void) dataTaskWithURL:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  // NOTE they're specifically asking for dataTaskWithURL: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDataTask* task = [session dataTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) dataTaskWithURLCompletionHandler:(NSString*)urlString
                                    isSuccess:(BOOL)isSuccess
                                checkResponse:(BOOL)checkResponse
                               responseString:(NSString*)responseString
                                         done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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

- (void) uploadTaskWithRequestFromFile:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  // NOTE they're specifically asking for uploadTaskWithRequest:fromFile: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromFile:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) uploadTaskWithRequestFromFileCompletionHandler:(NSString*)urlString
                                              isSuccess:(BOOL)isSuccess
                                          checkResponse:(BOOL)checkResponse
                                         responseString:(NSString*)responseString
                                                  done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
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

- (void) uploadTaskWithRequestFromData:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  // NOTE they're specifically asking for uploadTaskWithRequest:fromData: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:[[NSData alloc] init]];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) uploadTaskWithRequestFromDataCompletionHandler:(NSString*)urlString
                                              isSuccess:(BOOL)isSuccess
                                          checkResponse:(BOOL)checkResponse
                                         responseString:(NSString*)responseString
                                                   done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
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

- (void) downloadTaskWithRequest:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // NOTE they're specifically asking for downloadTaskWithRequest: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) downloadTaskWithRequestCompletionHandler:(NSString*)urlString
                                    isSuccess:(BOOL)isSuccess
                                checkResponse:(BOOL)checkResponse
                               responseString:(NSString*)responseString
                                         done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:30.0];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
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

- (void) downloadTaskWithURL:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  // NOTE they're specifically asking for downloadTaskWithURL: without a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void) downloadTaskWithURLCompletionHandler:(NSString*)urlString
                                isSuccess:(BOOL)isSuccess
                            checkResponse:(BOOL)checkResponse
                           responseString:(NSString*)responseString
                                     done:(void (^)())done
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
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

- (void) uploadTaskWithStreamedRequest:(NSString*)urlString
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                    timeoutInterval:30.0];
  
  [request setHTTPMethod:@"POST"];

  // start with a default configuration
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  
  // create a session with ourself as a delegate
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                        delegate:self
                                                   delegateQueue:nil];

  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  // NOTE they're specifically asking for uploadTaskWithStreamedRequest, which doesn't a completionHandler, so we need to test
  // that.  However, this doesn't give us the ability to look at the response.
  NSURLSessionUploadTask* task = [session uploadTaskWithStreamedRequest:request];
  
  // start the task
  [task resume];
  
  // sleep - waiting for network beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
}

- (void)   URLSession:(__unused NSURLSession *)session
                 task:(NSURLSessionTask *)task
 didCompleteWithError:(NSError *)error
{
  NSLog(@"Foo3!");
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
  NSString* str = @"test";
  NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
  NSInputStream* stream = [NSInputStream inputStreamWithData:data];
  completionHandler(stream);
}

- (void) checkDataResponse:(NSData *)data
                  response:(NSURLResponse *)response
                     error:(NSError *)error
                 isSuccess:(BOOL)isSuccess
             checkResponse:(BOOL)checkResponse
            responseString:(NSString*)responseString
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

- (void)testDataTaskWithRequestSuccess
{
  [self dataTaskWithRequest:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDataTaskWithRequestHTTPRedirect
{
  [self dataTaskWithRequest:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDataTaskWithRequestFailHTTPError
{
  [self dataTaskWithRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testDataTaskWithRequestConnectionRefused
{
  [self dataTaskWithRequest:CONNECTION_REFUSED_URL];
  [NSThread sleepForTimeInterval:(BEACON_ADD_WAIT*10)];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDataTaskWithRequestUnknownHost
{
  [self dataTaskWithRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDataTaskWithRequestConnectionTimeOut
{
  [self dataTaskWithRequest:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

- (void)testDataTaskWithRequestSocketTimeOut
{
  [self dataTaskWithRequest:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithRequest:completionHandler:

- (void)testDataTaskWithRequestCompetionHandlerSuccess
{
  [self dataTaskWithRequestCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerHTTPRedirect
{
  [self dataTaskWithRequestCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerFailHTTPError
{
  [self dataTaskWithRequestCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerConnectionRefused
{
  [self dataTaskWithRequestCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerUnknownHost
{
  [self dataTaskWithRequestCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerConnectionTimeOut
{
  [self dataTaskWithRequestCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithRequestCompetionHandlerSocketTimeOut
{
  [self dataTaskWithRequestCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithURL:

- (void)testDataTaskWithURLSuccess
{
  [self dataTaskWithURL:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDataTaskWithURLHTTPRedirect
{
  [self dataTaskWithURL:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDataTaskWithURLFailHTTPError
{
  [self dataTaskWithURL:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testDataTaskWithURLConnectionRefused
{
  [self dataTaskWithURL:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDataTaskWithURLUnknownHost
{
  [self dataTaskWithURL:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDataTaskWithURLConnectionTimeOut
{
  [self dataTaskWithURL:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDataTaskWithURLSocketTimeOut
{
  [self dataTaskWithURL:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark dataTaskWithURL:completionHandler:

- (void)testDataTaskWithURLCompetionHandlerSuccess
{
  [self dataTaskWithURLCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerHTTPRedirect
{
  [self dataTaskWithURLCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerFailHTTPError
{
  [self dataTaskWithURLCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerConnectionRefused
{
  [self dataTaskWithURLCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerUnknownHost
{
  [self dataTaskWithURLCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerConnectionTimeOut
{
  [self dataTaskWithURLCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDataTaskWithURLCompetionHandlerSocketTimeOut
{
  [self dataTaskWithURLCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:fromFile:

- (void)testUploadTaskWithRequestFromFileSuccess
{
  [self uploadTaskWithRequestFromFile:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithRequestFromFileHTTPRedirect
{
  [self uploadTaskWithRequestFromFile:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithRequestFromFileFailHTTPError
{
  [self uploadTaskWithRequestFromFile:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testUploadTaskWithRequestFromFileConnectionRefused
{
  [self uploadTaskWithRequestFromFile:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromFileUnknownHost
{
  [self uploadTaskWithRequestFromFile:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromFileConnectionTimeOut
{
  [self uploadTaskWithRequestFromFile:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromFileSocketTimeOut
{
  [self uploadTaskWithRequestFromFile:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:completionHandler:

- (void)testUploadTaskWithRequestFromFileCompetionHandlerSuccess
{
  [self uploadTaskWithRequestFromFileCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerHTTPRedirect
{
  [self uploadTaskWithRequestFromFileCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerFailHTTPError
{
  [self uploadTaskWithRequestFromFileCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerConnectionRefused
{
  [self uploadTaskWithRequestFromFileCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerUnknownHost
{
  [self uploadTaskWithRequestFromFileCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerConnectionTimeOut
{
  [self uploadTaskWithRequestFromFileCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromFileCompetionHandlerSocketTimeOut
{
  [self uploadTaskWithRequestFromFileCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:fromData:

- (void)testUploadTaskWithRequestFromDataSuccess
{
  [self uploadTaskWithRequestFromData:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithRequestFromDataHTTPRedirect
{
  [self uploadTaskWithRequestFromData:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithRequestFromDataFailHTTPError
{
  [self uploadTaskWithRequestFromData:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testUploadTaskWithRequestFromDataConnectionRefused
{
  [self uploadTaskWithRequestFromData:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromDataUnknownHost
{
  [self uploadTaskWithRequestFromData:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromDataConnectionTimeOut
{
  [self uploadTaskWithRequestFromData:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithRequestFromDataSocketTimeOut
{
  [self uploadTaskWithRequestFromData:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithRequest:completionHandler:

- (void)testUploadTaskWithRequestFromDataCompetionHandlerSuccess
{
  [self uploadTaskWithRequestFromDataCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerHTTPRedirect
{
  [self uploadTaskWithRequestFromDataCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerFailHTTPError
{
  [self uploadTaskWithRequestFromDataCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerConnectionRefused
{
  [self uploadTaskWithRequestFromDataCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerUnknownHost
{
  [self uploadTaskWithRequestFromDataCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerConnectionTimeOut
{
  [self uploadTaskWithRequestFromDataCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testUploadTaskWithRequestFromDataCompetionHandlerSocketTimeOut
{
  [self uploadTaskWithRequestFromDataCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark uploadTaskWithSteamedRequest:

- (void)testUploadTaskWithStreamedRequestSuccess
{
  [self uploadTaskWithStreamedRequest:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithStreamedRequestHTTPRedirect
{
  [self uploadTaskWithStreamedRequest:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testUploadTaskWithStreamedRequestFailHTTPError
{
  [self uploadTaskWithStreamedRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testUploadTaskWithStreamedRequestConnectionRefused
{
  [self uploadTaskWithStreamedRequest:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithStreamedRequestUnknownHost
{
  [self uploadTaskWithStreamedRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithStreamedRequestConnectionTimeOut
{
  [self uploadTaskWithStreamedRequest:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testUploadTaskWithStreamedRequestSocketTimeOut
{
  [self uploadTaskWithStreamedRequest:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithRequest:

- (void)testDownloadTaskWithRequestSuccess
{
  [self downloadTaskWithRequest:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDownloadTaskWithRequestHTTPRedirect
{
  [self downloadTaskWithRequest:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDownloadTaskWithRequestFailHTTPError
{
  [self downloadTaskWithRequest:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testDownloadTaskWithRequestConnectionRefused
{
  [self downloadTaskWithRequest:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithRequestUnknownHost
{
  [self downloadTaskWithRequest:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithRequestConnectionTimeOut
{
  [self downloadTaskWithRequest:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithRequestSocketTimeOut
{
  [self downloadTaskWithRequest:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithRequest:completionHandler:

- (void)testDownloadTaskWithRequestCompetionHandlerSuccess
{
  [self downloadTaskWithRequestCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerHTTPRedirect
{
  [self downloadTaskWithRequestCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerFailHTTPError
{
  [self downloadTaskWithRequestCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerConnectionRefused
{
  [self downloadTaskWithRequestCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerUnknownHost
{
  [self downloadTaskWithRequestCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerConnectionTimeOut
{
  [self downloadTaskWithRequestCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithRequestCompetionHandlerSocketTimeOut
{
  [self downloadTaskWithRequestCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithURL:

- (void)testDownloadTaskWithURLSuccess
{
  [self downloadTaskWithURL:SUCCESS_URL];
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDownloadTaskWithURLHTTPRedirect
{
  [self downloadTaskWithURL:REDIRECT_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testDownloadTaskWithURLFailHTTPError
{
  [self downloadTaskWithURL:PAGENOTFOUND_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
}

- (void)testDownloadTaskWithURLConnectionRefused
{
  [self downloadTaskWithURL:CONNECTION_REFUSED_URL];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithURLUnknownHost
{
  [self downloadTaskWithURL:UNKNOWN_HOST_URL];
  [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithURLConnectionTimeOut
{
  [self downloadTaskWithURL:CONNECTION_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:CONNECTION_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
}

- (void)testDownloadTaskWithURLSocketTimeOut
{
  [self downloadTaskWithURL:SOCKET_TIMEOUT_URL];
  [NSThread sleepForTimeInterval:SOCKET_TIMEOUT_ASYNC_WAIT];
  [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithURL:completionHandler:

- (void)testDownloadTaskWithURLCompetionHandlerSuccess
{
  [self downloadTaskWithURLCompletionHandler:SUCCESS_URL isSuccess:YES checkResponse:YES responseString:@"delayed: 3000 milliseconds" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerHTTPRedirect
{
  [self downloadTaskWithURLCompletionHandler:REDIRECT_URL isSuccess:YES checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerFailHTTPError
{
  [self downloadTaskWithURLCompletionHandler:PAGENOTFOUND_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:HTTPERRORPAGENOTFOUND];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerConnectionRefused
{
  [self downloadTaskWithURLCompletionHandler:CONNECTION_REFUSED_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerUnknownHost
{
  [self downloadTaskWithURLCompletionHandler:UNKNOWN_HOST_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:UNKNOWN_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerConnectionTimeOut
{
  [self downloadTaskWithURLCompletionHandler:CONNECTION_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:CONNECTION_TIMEOUT_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK];
  }];
}

- (void)testDownloadTaskWithURLCompetionHandlerSocketTimeOut
{
  [self downloadTaskWithURLCompletionHandler:SOCKET_TIMEOUT_URL isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self responseBeaconTest:BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLErrorTimedOut];
  }];
}

#pragma mark -
#pragma mark #pragma mark downloadTaskWithResumeData:

- (void)testDownloadTaskWithResumeData
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[LONG_DOWNLOAD_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url];
  
  // start the task
  [task resume];
  
  // wait a few seconds for the download to get some bytes
  [NSThread sleepForTimeInterval:DOWNLOAD_START_WAIT];
  
  // cancel the download
  [task cancelByProducingResumeData:^(NSData *resumeData) {
    XCTAssert(resumeData != nil, @"Need resumeData");
    
    if (resumeData)
    {
      NSURLSessionDownloadTask* secondTask = [session downloadTaskWithResumeData:resumeData];
      
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

- (void)testDownloadTaskWithResumeDataCompetionHandler
{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[LONG_DOWNLOAD_URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // grab the shared session
  NSURLSession* session = [NSURLSession sharedSession];
  
  // set our timeouts
  session.configuration.timeoutIntervalForRequest = 30;
  session.configuration.timeoutIntervalForResource = 30;
  
  NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url];
  
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
      NSURLSessionDownloadTask* secondTask = [session downloadTaskWithResumeData:resumeData
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
  NSMutableDictionary *testRecords = [[MPBeaconCollector sharedInstance] records];
  XCTAssert(testRecords != nil, "Records must exist");
  if (testRecords == nil)
  {
    return;
  }
  
  XCTAssertEqual([testRecords count], 1, "Record size incorrect");
  if ([testRecords count] != 1)
  {
    return;
  }
  
  id key = [[testRecords allKeys] objectAtIndex:0];
  MPBatchRecord *record = [testRecords objectForKey:key];
  
  XCTAssertEqual([record totalBeacons], 2, @"Wrong beacon count.");
  XCTAssertEqualObjects([record url], LONG_DOWNLOAD_URL_DOMAIN, @" Wrong URL string.");
  XCTAssertTrue([record networkErrorCode] == NSURLErrorCancelled, "Wrong network error code");
}

@end
