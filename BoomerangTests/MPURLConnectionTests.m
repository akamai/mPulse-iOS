//
//  MPURLConnectionTests.m
//  Boomerang
//
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import "MPHttpRequestTestBase.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPURLConnectionDelegateHelper.h"

@interface MPURLConnectionTests : MPHttpRequestTestBase<NSURLConnectionDataDelegate>
{
  MPURLConnectionDelegateHelper *requestHelper;
}

@end

@implementation MPURLConnectionTests

/**
 * Class setup
 */
-(void) setUp
{
  [super setUp];
  
  // Intialization of BoomerangURLConnectionDelegate
  [MPInterceptURLConnectionDelegate sharedInstance];
  
  // Initialize MPURLConnectionDelegateHelper for delegation
  requestHelper = [[MPURLConnectionDelegateHelper alloc] init];
}

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

@end
