//
//  MPTimerBeaconTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 5/22/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPBatchRecord.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"

@interface MPTimerBeaconTests : XCTestCase
{
}
@end

@implementation MPTimerBeaconTests

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

- (void)setUp
{
  [super setUp];
  
  [MPulse initializeWithAPIKey:@"K9MSB-TL87R-NA6PR-XZPBL-5SLU5"];

  NSString *responseSample = @"{\"h.key\": \"K9MSB-TL87R-NA6PR-XZPBL-5SLU5\",\"h.d\": \"com.soasta.ios.SampleMPulseApp\",\"h.t\": 1428602384684,\"h.cr\": \"23a0384939e93bbc22af11b74654a82f180f5910\",  \"session_id\": \"5e29a2e6-4017-4fc8-97bc-f5e2a475d6fa\", \"site_domain\": \"com.soasta.ios.SampleMPulseApp\",\"beacon_url\": \"//rum-dev-collector.soasta.com/beacon/\",\"beacon_interval\": 5,\"BW\": {\"enabled\": false},\"RT\": {\"session_exp\": 1800},\"ResourceTiming\": {  \"enabled\": false},\"Angular\": {  \"enabled\": false},\"PageParams\": {\"pageGroups\": [], \"customMetrics\": [{\"name\":\"Metric1\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"cmet.Metric1\",\"dataType\":\"Number\"}],  \"customTimers\": [{\"name\":\"Touch Timer\",\"index\":0,\"type\":\"Programmatic\",\"label\":\"custom0\"},{\"name\":\"Code Timer\",\"index\":1,\"type\":\"Programmatic\",\"label\":\"custom1\"}],  \"customDimensions\": [],\"urlPatterns\": [],\"params\": true},\"user_ip\": \"67.111.67.3\"}";
  
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
 * Checks if the records collected by MPBeaconCollector.have the desired number of beacons and custom timer duration.
 */
- (void) responseBeaconTest: (NSNumber*)minDuration exactDuration:(NSNumber*)exactDuration beaconCount:(int)beaconCount
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
    NSArray* customTimerArray = [record customTimerArray];
    
    if (customTimerArray != nil)
    {
      XCTAssertEqual([customTimerArray count], beaconCount, "Array size incorrect");
    }

    MPTimerData *customTimer = [customTimerArray objectAtIndex:beaconCount-1];
    
    MPLogDebug(@"Timer Duration : %ld Beacon Count : %d  Crash Count : %d ", [customTimer sum] , [record totalBeacons] , [record totalCrashes]);
    
    if (minDuration != nil)
    {
      XCTAssertTrue([customTimer sum] >= [minDuration longValue], "Custom Timer min duration error");
    }
    
    if (exactDuration != nil)
    {
      XCTAssertEqual([customTimer sum], [exactDuration longValue], "Custom Timer exact duration error");
    }
    
    XCTAssertEqual([record totalBeacons], beaconCount, @"Wrong beacon count.");
  }
}

#pragma mark -
#pragma mark Timer Beacon Tests

- (void)testSendTimerBeacon
{
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:3];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self responseBeaconTest:nil exactDuration:@3000 beaconCount:1];
}

- (void)testStartStopTimerBeacon
{
  NSString* timerID = [[MPulse sharedInstance] startTimer:@"Touch Timer"];
  
  // Sleep for 3 seconds and let the timer run.
  [NSThread sleepForTimeInterval:3];
   
  [[MPulse sharedInstance] stopTimer:timerID];
   
   // Sleep - waiting for beacon to be added
   [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self responseBeaconTest:@3000 exactDuration:nil beaconCount:1];
}

@end
