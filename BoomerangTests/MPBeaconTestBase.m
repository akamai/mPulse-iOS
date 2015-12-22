//
//  MPBeaconTestBase.m
//  Boomerang
//
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPBeaconTestBase.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"

@implementation MPBeaconTestBase

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

// Whether or not the config.js request was complete
static BOOL networkRequestComplete = NO;

// Whether or not the API key was initialized
static BOOL initializedWithAPIKey = NO;

-(NSString *) apiKey
{
  return @"K9MSB-TL87R-NA6PR-XZPBL-5SLU5";
}

-(void) setUp
{
  [super setUp];
  
  if (!initializedWithAPIKey)
  {
    [MPulse initializeWithAPIKey:[self apiKey]];
    [self waitForNetworkRequestCompletion];
  }
  else
  {
    [[MPSession sharedInstance] reset];
  }
  
  NSString *responseSample = @"{\"h.key\": \"K9MSB-TL87R-NA6PR-XZPBL-5SLU5\",\"h.d\": \"com.soasta.ios.SampleMPulseApp\",\"h.t\": 1428602384684,\"h.cr\": \"23a0384939e93bbc22af11b74654a82f180f5910\",  \"session_id\": \"5e29a2e6-4017-4fc8-97bc-f5e2a475d6fa\", \"site_domain\": \"com.soasta.ios.SampleMPulseApp\",\"beacon_url\": \"//rum-dev-collector.soasta.com/beacon/\",\"beacon_interval\": 5,\"BW\": {\"enabled\": false},\"RT\": {\"session_exp\": 1800},\"ResourceTiming\": {  \"enabled\": false},\"Angular\": {  \"enabled\": false},\"PageParams\": {\"pageGroups\": [], \"customMetrics\": [{\"name\":\"Metric1\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"cmet.Metric1\",\"dataType\":\"Number\"},{\"name\":\"Metric2\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"cmet.Metric2\",\"dataType\":\"Number\"}],  \"customTimers\": [{\"name\":\"Touch Timer\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"custom0\"},{\"name\":\"Code Timer\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"custom1\"}],  \"customDimensions\": [],\"urlPatterns\": [],\"params\": true},\"user_ip\": \"67.111.67.3\"}";
  
  // Initialize config object with sample string
  [[MPConfig sharedInstance] initWithResponse:responseSample];
  
  // Disable Config refresh
  [[MPConfig sharedInstance] setRefreshDisabled:YES];

  // Initialize session object
  [MPSession sharedInstance];
  
  // Disable batch record sending as the server is not receiving any beacons
  [MPBeaconCollector sharedInstance].disableBatchSending = YES;
  
  // Sleep - waiting for session start beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Clearing beacons before adding
  [[MPBeaconCollector sharedInstance] clearBatch];
  
  initializedWithAPIKey = YES;
}

-(void) tearDown
{
  // Make sure we clean up after ourselves
  [[MPBeaconCollector sharedInstance] clearBatch];
  
  [super tearDown];
}

-(void) waitForNetworkRequestCompletion
{
  networkRequestComplete = NO;
  
  // MPConfig will notify us when network request is complete.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(receiveConfigRefreshCompleteNotification:)
                                               name:CONFIG_GET_REQUEST_COMPLETE
                                             object:nil];
  
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