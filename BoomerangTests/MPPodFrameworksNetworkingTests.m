//
//  MPAFNetworkingTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 12/8/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MPulse.h"
#import "MPSession.h"
#import "MPConfig.h"
#import "MPBatchRecord.h"
#import "MPTimerData.h"
#import "MPBeaconCollector.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPHttpRequestDelegateHelper.h"
#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "AFXMLRequestOperation.h"
#import "AFPropertyListRequestOperation.h"
#import "SDWebImageDownloader.h"


@interface MPPodFrameworksNetworkingTests : XCTestCase
{
  MPHttpRequestDelegateHelper *requestHelper;
}
@end

@implementation MPPodFrameworksNetworkingTests

NSString * const SUCCESS_URL = @"http://67.111.67.24:8080/concerto/DevTest/delay?timeToDelay=3000";
NSString * const BATCH_URL = @"http://67.111.67.24/";
NSString* IMAGE_DOWNLOAD_URL = @"http://indianapublicmedia.org/support/files/2011/09/04_03_1-Stock-Market-Prices_web.jpg";
NSString* IMAGE_DOWNLOAD_BATCH_URL = @"http://indianapublicmedia.org/";

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
int const BEACON_ADD_WAIT = 5;
// Timeout is 30 seconds because we are running in simulator
// iOS devices have 4 minute timeout - set this to 300 seconds.
int const SOCKET_TIMEOUT_ASYNC_WAIT = 30;
// Connection time out : 30 seconds
int const CONNECTION_TIMEOUT_ASYNC_WAIT = 30;
// Loop time out for connections that delegate
int const LOOP_TIMEOUT = 300;

short const HTTPERRORPAGENOTFOUND = 404;
short const NSURLSUCCESS = 0;


- (void)setUp
{
  [super setUp];
  
  // Disable Config refresh
  [[MPConfig sharedInstance] setRefreshDisabled:YES];
  
  [MPulse initializeWithAPIKey:@"K9MSB-TL87R-NA6PR-XZPBL-5SLU5"];
  
  NSString *responseSample = @"{\"h.key\": \"K9MSB-TL87R-NA6PR-XZPBL-5SLU5\",\"h.d\": \"com.soasta.ios.SampleMPulseApp\",\"h.t\": 1428602384684,\"h.cr\": \"23a0384939e93bbc22af11b74654a82f180f5910\",  \"session_id\": \"5e29a2e6-4017-4fc8-97bc-f5e2a475d6fa\", \"site_domain\": \"com.soasta.ios.SampleMPulseApp\",\"beacon_url\": \"//rum-dev-collector.soasta.com/beacon/\",\"beacon_interval\": 5,\"BW\": {\"enabled\": false},\"RT\": {\"session_exp\": 1800},\"ResourceTiming\": {  \"enabled\": false},\"Angular\": {  \"enabled\": false},\"PageParams\": {\"pageGroups\": [], \"customMetrics\": [{\"name\":\"Metric1\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"cmet.Metric1\",\"dataType\":\"Number\"}],  \"customTimers\": [{\"name\":\"Touch Timer\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"custom0\"},{\"name\":\"Code Timer\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"custom1\"}],  \"customDimensions\": [],\"urlPatterns\": [],\"params\": true},\"user_ip\": \"67.111.67.3\"}";
  
  // Initialize config object with sample string
  [[MPConfig sharedInstance] initWithResponse:responseSample];
  
  // Initialize session object
  [MPSession sharedInstance];
  
  // Disable batch record sending as the server is not receiving any beacons
  [MPBeaconCollector sharedInstance].disableBatchSending = YES;
  
  // Intialization of BoomerangURLConnectionDelegate
  [MPInterceptURLConnectionDelegate sharedInstance];
  
  //sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  //clearing beacons before adding
  [[MPBeaconCollector sharedInstance] clearBatch];
  
  //initialize MPHttpRequestDelegateHelper for delegation
  requestHelper = [[MPHttpRequestDelegateHelper alloc] init];
}

- (void)tearDown
{
  // Make sure we clean up after ourselves
  [[MPBeaconCollector sharedInstance] clearBatch];

  [super tearDown];
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
  // Sleep - wait for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  NSMutableDictionary *testRecords = [[MPBeaconCollector sharedInstance] records];
  XCTAssertEqual([testRecords count], 1, "Dictionary size incorrect");
  
  id key = [[testRecords allKeys] objectAtIndex:0];
  MPBatchRecord *record = [testRecords objectForKey:key];
  MPTimerData* networkRequestTimer = [record networkRequestTimer];
  
  MPLogDebug(@"Timer Duration : %ld Beacon Count : %d  Crash Count : %d ", [networkRequestTimer sum] , [record totalBeacons] , [record totalCrashes]);
  MPLogDebug(@"URL : %@ Network Error Code: %hd ", [record url] , [record networkErrorCode]);
  
  XCTAssertTrue([networkRequestTimer sum] >= minDuration, "network request duration error");
  XCTAssertEqual([record totalBeacons], beaconCount, @"Wrong beacon count.");
  XCTAssertEqual([record totalCrashes ], crashCount, @"Wrong crash count.");
  XCTAssertEqualObjects([record url], urlString, @" Wrong URL string.");
  XCTAssertTrue([record networkErrorCode] == networkErrorCode, "Wrong network error code");
}

- (void)testAFJSONRequestOperationInterception
{
  // This URL does not return JSON data, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFJSONRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                              {
                                                MPLogInfo(@"Request successful.");
                                              }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                              {
                                                MPLogInfo(@"Request failed.");
                                              }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testAFImageRequestOperation
{
  // This URL does not return an Image, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFImageRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                                         success:^(UIImage *image)
                                                                                          {
                                                                                            MPLogInfo(@"Request successful.");
                                                                                          }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testAFPropertyListRequestOperation
{
  // This URL does not return a Property List, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFImageRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFPropertyListRequestOperation *operation = [AFPropertyListRequestOperation propertyListRequestOperationWithRequest:request
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList)
                                                      {
                                                        MPLogInfo(@"Request successful.");
                                                      }
                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList)
                                                      {
                                                        MPLogInfo(@"Request failed.");
                                                      }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

- (void)testAFXMLRequestOperation
{
  // This URL does not return XML data, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFXMLRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFXMLRequestOperation *operation = [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser)
                                               {
                                                 MPLogInfo(@"Request successful.");
                                               }
                                      failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser)
                                               {
                                                 MPLogInfo(@"Request failed.");
                                               }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:BATCH_URL minDuration:3000 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

// Downloads a sample image using SDWebImageDownloader and verifies that we add a beacon for the request.
- (void)testSDWebImageDownloaderInterception
{
  __block BOOL downloadComplete = NO;
  [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:IMAGE_DOWNLOAD_URL]
                                                      options:0
                                                     progress:nil
                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
   {
     if (image && finished)
     {
       // Image download complete
       downloadComplete = YES;
     }
   }];
  
  int secondsSlept = 0;
  while (!downloadComplete)
  {
    if (secondsSlept >= 30)
    {
      break; // Timeout if we've waited for 30 seconds.
    }
    
    sleep(2); // Sleep until download is complete
    secondsSlept += 2;
  }
  
  // Test for success
  [self responseBeaconTest:IMAGE_DOWNLOAD_BATCH_URL minDuration:0 beaconCount:1 crashCount:0 networkErrorCode:NSURLSUCCESS];
}

@end
