//
//  MPConfigTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 5/28/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPConfig.h"
#import "MPBeaconCollector.h"

@interface MPConfigTests : XCTestCase

@end

@implementation MPConfigTests

  NSString *INVALID_RESPONSE = @"{\"message\":\"Domain is not a subdomain registered with this API Key\"}";

  NSString *VALID_RESPONSE = @"{\"h.key\": \"K9MSB-TL87R-NA6PR-XZPBL-5SLU5\",\"h.d\": \"com.soasta.ios.SampleMPulseApp\",\"h.t\": 1428602384684,\"h.cr\": \"23a0384939e93bbc22af11b74654a82f180f5910\",  \"session_id\": \"5e29a2e6-4017-4fc8-97bc-f5e2a475d6fa\", \"site_domain\": \"com.soasta.ios.SampleMPulseApp\",\"beacon_url\": \"//rum-dev-collector.soasta.com/beacon/\",\"beacon_interval\": 5,\"BW\": {\"enabled\": false},\"RT\": {\"session_exp\": 1800},\"ResourceTiming\": {  \"enabled\": false},\"Angular\": {  \"enabled\": false},\"PageParams\": {\"pageGroups\": [], \"customMetrics\": [{\"name\":\"Metric1\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"cmet.Metric1\",\"dataType\":\"Number\"}],  \"customTimers\": [{\"name\":\"Touch Timer\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"custom0\"},{\"name\":\"Code Timer\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"custom1\"}],  \"customDimensions\": [],\"urlPatterns\": [],\"params\": true},\"user_ip\": \"67.111.67.3\"}";

  NSString *API_KEY = @"K9MSB-TL87R-NA6PR-XZPBL-5SLU5";
  BOOL initializedWithAPIKey = NO;
  BOOL networkRequestComplete = NO;

- (void)setUp
{
  [super setUp];
  
  // We should initialize the mPulse instance only once for all tests in this class.
  if (!initializedWithAPIKey)
  {
    [MPulse initializeWithAPIKey:API_KEY];
    [self waitForNetworkRequestCompletion];
  
    // Disable batch record sending as the server is not receiving any beacons
    [MPBeaconCollector sharedInstance].disableBatchSending = YES;
    
    initializedWithAPIKey = YES;
  }
}

- (void)testInvalidJSONInResponseContent
{
  // Initialize config object
  MPConfig* mpConfig = [MPConfig sharedInstance];
  [mpConfig setRefreshDisabled:YES];

  // Initialize with valid response
  [mpConfig initWithResponse:VALID_RESPONSE];
  XCTAssertTrue([mpConfig beaconsEnabled], @"Beacons are disabled for valid response content.");
  
  // Initialize with invalid response
  [mpConfig initWithResponse:INVALID_RESPONSE];
  XCTAssertFalse([mpConfig beaconsEnabled], @"Beacons are enabled for invalid response content.");
  
  // Re-enable refresh so other tests could run
  [mpConfig setRefreshDisabled:NO];
}

- (void)testConfigRefreshTimeout
{
  NSDate *timerStart = [NSDate date];
  
  [MPulse initializeWithAPIKey:API_KEY andServerURL:[NSURL URLWithString:@"http://1.2.3.4:8080/concerto"]];
  
  NSDate *timerEnd = [NSDate date];
  NSTimeInterval executionTime = [timerEnd timeIntervalSinceDate:timerStart];
  
  XCTAssertTrue(executionTime < 1, @"initializeWithAPIKey and setServerURL calls did not return quickly. Time taken: %f seconds", executionTime);
  XCTAssertFalse([[MPConfig sharedInstance] beaconsEnabled], @"Beacons should not be enable when we are supposed to timeout.");
  
  [self waitForNetworkRequestCompletion];
}

- (void)testSlowConfigRefresh
{
  NSDate *timerStart = [NSDate date];

  [MPulse initializeWithAPIKey:API_KEY andServerURL:[NSURL URLWithString:@"http://67.111.67.24:8080/concerto/api/config.json?delay=5000"]];

  NSDate *timerEnd = [NSDate date];
  NSTimeInterval executionTime = [timerEnd timeIntervalSinceDate:timerStart];
  
  XCTAssertTrue(executionTime < 1, @"initializeWithAPIKey and setServerURL calls did not return quickly. Time taken: %f seconds", executionTime);
  XCTAssertFalse([[MPConfig sharedInstance] beaconsEnabled], @"Beacons should not be enabled while we are waiting for a slow Config Refresh.");
  
  [self waitForNetworkRequestCompletion];
  
  XCTAssertTrue([[MPConfig sharedInstance] beaconsEnabled], @"Beacons should be enabled now that we have received the Slow delivery of Config data.");
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

@end
