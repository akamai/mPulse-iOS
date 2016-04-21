//
//  MPApiCustomTimerBeaconTests.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPApiCustomTimerBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPBeaconTestBase.h"

@interface MPApiCustomTimerBeaconTests : MPBeaconTestBase
{
}

@end

@implementation MPApiCustomTimerBeaconTests

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

/*
 * Checks if the records collected by MPBeaconCollector have the desired number of 
 * beacons and custom timer duration.
 */
-(void) validateBeacons:(NSArray *)beaconValidation
{
  NSMutableArray *testBeacons = [[MPBeaconCollector sharedInstance] getBeacons];
  
  XCTAssertNotEqual(testBeacons, nil);
  
  // beacon count
  XCTAssertEqual([testBeacons count], [beaconValidation count], "Beacons count incorrect");
  
  for (int i = 0; i < [beaconValidation count]; i++)
  {
    NSArray *validation = [beaconValidation objectAtIndex:i];
    
    // validation payload
    NSString *timerName = [validation objectAtIndex:0];
    NSNumber *timerIndex = [validation objectAtIndex:1];
    NSNumber *minDuration = [validation objectAtIndex:2];
    NSNumber *exactDuration = [validation objectAtIndex:3];
    
    // view group
    NSString *viewGroup = @"";

    if ([validation count] >= 5)
    {
      viewGroup = [validation objectAtIndex:4];
    }
    
    // a/b test
    NSString *abTest = @"";

    if ([validation count] >= 6)
    {
      abTest = [validation objectAtIndex:5];
    }

    MPApiCustomTimerBeacon *beacon = [testBeacons objectAtIndex:i];
    
    MPLogDebug(@"Timer Name : %@ Index : %ld Duration : %f",
               beacon.timerName,
               (long)beacon.timerIndex,
               beacon.timerValue);
    
    //
    // Assert beacon matches our expected values
    //
    XCTAssertEqual([beacon getBeaconType], API_CUSTOM_TIMER, "Beacon type");
    
    XCTAssertTrue([beacon.timerName isEqualToString:timerName], "Custom Timer name error");
    
    XCTAssertEqual(beacon.timerIndex, [timerIndex longValue], "Custom Timer index error");

    if ([minDuration longValue] > 0)
    {
      XCTAssertTrue(beacon.timerValue >= [minDuration longValue], "Custom Timer min duration error");
    }
    
    if ([exactDuration longValue] > 0)
    {
      XCTAssertEqual(beacon.timerValue, [exactDuration longValue], "Custom Timer exact duration error");
    }
    
    if (![viewGroup isEqualToString:@""])
    {
      XCTAssertTrue([beacon.pageGroup isEqualToString:viewGroup], "Beacon View Group");
    }
    
    if (![abTest isEqualToString:@""])
    {
      XCTAssertTrue([beacon.abTest isEqualToString:abTest], "A/B test");
    }
  }
}

#pragma mark -
#pragma mark Timer Beacon Tests

-(void) testSendTimerBeacon
{
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:3];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self validateBeacons:@[
                          @[@"Touch Timer", @0, @0, @3000]
                        ]];
}

-(void) testStartStopTimerBeacon
{
  NSString *timerID = [[MPulse sharedInstance] startTimer:@"Touch Timer"];
  
  // Sleep for 3 seconds and let the timer run.
  [NSThread sleepForTimeInterval:3];
   
  [[MPulse sharedInstance] stopTimer:timerID];
   
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration at least 3 seconds
  [self validateBeacons:@[
                          @[@"Touch Timer", @0, @3, @0]
                        ]];
}

-(void) testStartStopStartStopTimerBeacon
{
  // test raw MPApiCustomTimerBeacon
  MPApiCustomTimerBeacon *beacon = [[MPApiCustomTimerBeacon alloc] initWithIndex:0];
  
  // start the timer
  [beacon startTimer];
  XCTAssertEqual(beacon.hasTimerStarted, YES, "hasTimerStarted after end");
  
  // Sleep for 1 second and let the timer run.
  [NSThread sleepForTimeInterval:3];
  
  // stop the timer
  [beacon endTimer];
  
  XCTAssertTrue(beacon.timerValue >= 3, "Duration after end");
  XCTAssertEqual(beacon.hasTimerEnded, YES, "hasTimerEnded after end");
  XCTAssertEqual(beacon.hasTimerStarted, YES, "hasTimerStarted after end");
  NSTimeInterval oldTime = beacon.timerValue;
  
  // start the timer
  [beacon startTimer];
  
  // end and duration should be un-set
  XCTAssertEqual(beacon.timerValue, 0, "Duration after end");
  XCTAssertEqual(beacon.hasTimerEnded, NO, "hasTimerEnded after end");
  XCTAssertEqual(beacon.hasTimerStarted, YES, "hasTimerStarted after end");
  
  // Sleep for 1 second and let the timer run.
  [NSThread sleepForTimeInterval:0.5];
  
  // stop the timer again
  [beacon endTimer];
  
  // new values
  XCTAssertTrue(beacon.timerValue >= 0, "Duration after end");
  XCTAssertTrue(beacon.timerValue <= 3000, "Duration after end");
  XCTAssertTrue(beacon.timerValue != oldTime, "Duration after end");
  XCTAssertEqual(beacon.hasTimerEnded, YES, "hasTimerEnded after end");
  XCTAssertEqual(beacon.hasTimerStarted, YES, "hasTimerStarted after end");
}

-(void) testSendThreeTimerBeacons
{
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:1];
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:2];
  [[MPulse sharedInstance] sendTimer:@"Code Timer" value:3];
  
  // Sleep - waiting for beacons to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for 3 beacons
  [self validateBeacons:@[
                          @[@"Touch Timer", @0, @0, @1000],
                          @[@"Touch Timer", @0, @0, @2000],
                          @[@"Code Timer",  @1, @0, @3000]
                        ]];
}

-(void) testUnknownTimerName
{
  [[MPulse sharedInstance] sendTimer:@"Bad Timer Name" value:1];
  
  // Sleep - waiting for beacons to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // No beacons
  [self validateBeacons:@[]];
}

-(void) testInitWithIndex
{
  // test raw MPApiCustomTimerBeacon
  MPApiCustomTimerBeacon *beacon = [[MPApiCustomTimerBeacon alloc] initWithIndex:1];
  
  XCTAssertEqual(beacon.timerIndex, 1, "Timer index");
}

-(void) testInitWithName
{
  // test raw MPApiCustomTimerBeacon
  MPApiCustomTimerBeacon *beacon = [[MPApiCustomTimerBeacon alloc] initWithName:@"Touch Timer" andValue:1.0f];
  
  XCTAssertEqual(beacon.timerIndex, 0, "Timer index");
  XCTAssertEqual(beacon.timerName, @"Touch Timer", "Timer name");
}

-(void) testDimensions
{
  [[MPulse sharedInstance] setViewGroup:@"Foo"];
  [[MPulse sharedInstance] setABTest:@"A/B"];
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:1];
  
  [[MPulse sharedInstance] resetViewGroup];
  [[MPulse sharedInstance] resetABTest];
  [[MPulse sharedInstance] sendTimer:@"Touch Timer" value:2];

  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self validateBeacons:@[
                          @[@"Touch Timer", @0, @0, @1000, @"Foo", @"A/B"],
                          @[@"Touch Timer", @0, @0, @2000, @"", @""]
                        ]];
}

-(void) testBeaconType
{
  MPApiCustomTimerBeacon *beacon = [[MPApiCustomTimerBeacon alloc] initAndStart:@"Touch Timer"];
  
  XCTAssertNotNil(beacon);
  XCTAssertEqual([beacon getBeaconType], API_CUSTOM_TIMER);
}

@end
