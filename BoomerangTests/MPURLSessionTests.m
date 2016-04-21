//
//  MPURLSessionTests.m
//  Boomerang
//
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import "MPHttpRequestTestBase.h"
#import "MPInterceptURLSessionDelegate.h"
#import "MPURLSessionDelegateHelper.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"

@interface MPURLSessionTests : MPHttpRequestTestBase<NSURLSessionTaskDelegate>
{
  dispatch_group_t _taskGroup;
}

@end

@implementation MPURLSessionTests

/**
 * Class setup
 */
-(void) setUp
{
  [super setUp];
  
  // Intialization of BoomerangURLSessionDelegate
  [MPInterceptURLSessionDelegate sharedInstance];
  
  // Used to join threads in the threading test
  _taskGroup = dispatch_group_create();
}

#pragma mark -
#pragma mark Helpers

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

-(void) dataTaskWithRequestDelegate:(NSString *)urlString
                        minDuration:(int)minDuration
                   networkErrorCode:(int)networkErrorCode
                        hasResponse:(BOOL)hasResponse

{
  // build a NSURL
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  // convert URL to a request
  NSURLRequest *request = [NSURLRequest requestWithURL:url
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:SOCKET_TIMEOUT_INTERVAL];

  // session configuration
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  
  // session connection queue
  NSOperationQueue *connectionQueue = [[NSOperationQueue alloc] init];
  connectionQueue.name = @"com.soasta.connqueue";
  connectionQueue.maxConcurrentOperationCount = 4;

  // Initialize MPURLSessionDelegateHelper for delegation
  MPURLSessionDelegateHelper *delegate = [[MPURLSessionDelegateHelper alloc] init];

  // specify a delegate
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                        delegate:delegate
                                                   delegateQueue:connectionQueue];

  NSURLSessionDataTask *task = [session dataTaskWithRequest:request];

  // start the task
  [task resume];

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

  // ensure the beacon is good
  [self responseBeaconTest:urlString minDuration:minDuration networkErrorCode:networkErrorCode];

  // ensure our delegate got called
  XCTAssertEqual(delegate.firedDidCompleteWithError,
                 true,
                 @"NSURLSession delegate should have called didCompleteWithError");

  if (hasResponse)
  {
    XCTAssertEqual(delegate.firedDidReceiveData,
                   true,
                   @"NSURLSession delegate should have called firedDidReceiveData");

    XCTAssertEqual(delegate.firedDidReceiveResponse,
                   true,
                   @"NSURLSession delegate should have called firedDidReceiveResponse");
  }
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
#pragma mark dataTaskWithRequest:

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

-(void) testDataTaskWithRequestBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self dataTaskWithRequest:[config.beaconURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark dataTaskWithRequest:completionHandler:

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

-(void) testDataTaskWithRequestCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self dataTaskWithRequestCompletionHandler:[config.beaconURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark dataTaskWithURL:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testDataTaskWithURLBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self dataTaskWithURL:[config.beaconURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark dataTaskWithURL:completionHandler:

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

-(void) testDataTaskWithURLCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self dataTaskWithURLCompletionHandler:[config.beaconURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark uploadTaskWithRequest:fromFile:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testUploadTaskWithRequestFromFileBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];

  [self uploadTaskWithRequestFromFile:[config.configURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark uploadTaskWithRequest:completionHandler:

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

-(void) testUploadTaskWithRequestFromFileCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self uploadTaskWithRequestFromFileCompletionHandler:[config.configURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark uploadTaskWithRequest:fromData:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testUploadTaskWithRequestFromDataBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];

  [self uploadTaskWithRequestFromData:[config.configURL absoluteString]];

  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];

  [self assertNoBeacons];
}

#pragma mark -
#pragma mark uploadTaskWithRequest:completionHandler:

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

-(void) testUploadTaskWithRequestFromDataCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self uploadTaskWithRequestFromDataCompletionHandler:[config.configURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark uploadTaskWithSteamedRequest:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testUploadTaskWithStreamedRequestBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self uploadTaskWithStreamedRequest:[config.configURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark downloadTaskWithRequest:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testDownloadTaskWithRequestBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self downloadTaskWithRequest:[config.configURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark downloadTaskWithRequest:completionHandler:

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

-(void) testDownloadTaskWithRequestCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];

  [self downloadTaskWithRequestCompletionHandler:[config.configURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark downloadTaskWithURL:

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

  // Loop until we see a beacon
  [self waitForBeacon:LOOP_TIMEOUT];

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

-(void) testDownloadTaskWithURLBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self downloadTaskWithURL:[config.configURL absoluteString]];
  
  // wait for a second to make sure there were no crashes
  [NSThread sleepForTimeInterval:1];
  
  [self assertNoBeacons];
}

#pragma mark -
#pragma mark downloadTaskWithURL:completionHandler:

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

-(void) testDownloadTaskWithURLCompetionHandlerBeaconUrl
{
  MPConfig *config = [MPConfig sharedInstance];
  
  [self downloadTaskWithURLCompletionHandler:[config.configURL absoluteString] isSuccess:NO checkResponse:NO responseString:@"" done:^{
    [self assertNoBeacons];
  }];
}

#pragma mark -
#pragma mark downloadTaskWithResumeData:

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
#pragma mark downloadTaskWithResumeData:completionHandler:

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

#pragma mark -
#pragma mark dataTaskWithRequest With a Delegate

-(void) testDataTaskWithRequestDelegateSuccess
{
  [self dataTaskWithRequestDelegate:SUCCESS_URL
                        minDuration:3000
                   networkErrorCode:NSURLSUCCESS
                        hasResponse:true];
}

-(void) testDataTaskWithRequestDelegateHTTPRedirect
{
  [self dataTaskWithRequestDelegate:REDIRECT_URL
                        minDuration:0
                   networkErrorCode:NSURLSUCCESS
                        hasResponse:true];
}

-(void) testDataTaskWithRequestDelegateFailHTTPError
{
  [self dataTaskWithRequestDelegate:PAGENOTFOUND_URL
                        minDuration:0
                   networkErrorCode:HTTP_ERROR_PAGE_NOT_FOUND
                        hasResponse:true];
}

-(void) testDataTaskWithRequestDelegateConnectionRefused
{
  [self dataTaskWithRequestDelegate:CONNECTION_REFUSED_URL
                        minDuration:0
                   networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK
                        hasResponse:false];
}

-(void) testDataTaskWithRequestDelegateUnknownHost
{
  [self dataTaskWithRequestDelegate:UNKNOWN_HOST_URL
                        minDuration:0
                   networkErrorCode:SKIP_NETWORK_ERROR_CODE_CHECK
                        hasResponse:false];
}

-(void) testDataTaskWithRequestDelegateConnectionTimeOut
{
  [self dataTaskWithRequestDelegate:CONNECTION_TIMEOUT_URL
                        minDuration:0
                   networkErrorCode:NSURLErrorTimedOut
                        hasResponse:false];
}

-(void) testDataTaskWithRequestDelegateSocketTimeOut
{
  [self dataTaskWithRequestDelegate:SOCKET_TIMEOUT_URL
                        minDuration:0
                   networkErrorCode:NSURLErrorTimedOut
                        hasResponse:false];
}

-(void) testThreadedDataTaskWithRequestSuccess
{
  const long THREAD_TIMEOUT_NS = (long) 10 * 60 * 1000000000; // 10 mins should be more than enough
  const int THREAD_COUNT = 100;
  const int REQUEST_COUNT = 5;
    
  for (int i=0; i < THREAD_COUNT; i++)
  {
    dispatch_group_enter(_taskGroup);
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadLoop:) object:@{@"threadnum": [NSNumber numberWithInt:i], @"requests": [NSNumber numberWithInt:REQUEST_COUNT]}];
    [thread start];
  }
    
  if (dispatch_group_wait(_taskGroup, dispatch_time(DISPATCH_TIME_NOW, THREAD_TIMEOUT_NS)) != 0)
  {
    // Timeout
    XCTFail(@"Timeout occured");
  }
}

- (void)threadLoop: (NSDictionary *)threadInfo
{
  int requests = [threadInfo[@"requests"] intValue];
  int threadnum = [threadInfo[@"threadnum"] intValue];
  
  NSLog(@"thread %d started", threadnum);
  while (requests-- > 0)
  {
    [self dataTaskWithRequest:QUICK_SUCCESS_URL];
  }
  NSLog(@"thread %d done", threadnum);
    
  dispatch_group_leave(_taskGroup);
}

@end
