//
//  MPAppLaunchBeaconBeaconTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 5/22/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPAppLaunchBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPBeaconTestBase.h"

@interface MPAppLaunchBeaconBeaconTests : MPBeaconTestBase
{
}

@end

@implementation MPAppLaunchBeaconBeaconTests

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

/*
 * Checks if the records collected by MPBeaconCollector.have the desired number of beacons and custom metric values.
 */
-(void) validateBeacons:(NSArray *)beaconValidation
{
  NSMutableArray *testBeacons = [[MPBeaconCollector sharedInstance] getBeacons];
  
  XCTAssertNotEqual(testBeacons, nil);
  
  // beacon count
  XCTAssertEqual([testBeacons count], [beaconValidation count], "Beacons count incorrect");
  
  for (int i = 0; i < [beaconValidation count]; i++)
  {
    MPAppLaunchBeacon *beacon = [testBeacons objectAtIndex:i];
    
    NSArray *validation = [beaconValidation objectAtIndex:i];
    
    NSString *viewGroup = @"";

    if ([validation count] >= 1)
    {
      viewGroup = [validation objectAtIndex:0];
    }
    
    NSString *abTest = @"";

    if ([validation count] >= 2)
    {
      abTest = [validation objectAtIndex:1];
    }
    
    XCTAssertEqual([beacon getBeaconType], APP_LAUNCH, "Beacon type");
    
    if (![viewGroup isEqualToString:@""])
    {
      XCTAssertEqual(beacon.pageGroup, viewGroup, "Beacon View Group");
    }
    
    if (![abTest isEqualToString:@""])
    {
      XCTAssertEqual(beacon.abTest, abTest, "A/B test");
    }
  }
}

#pragma mark -
#pragma mark App Launch Beacon Tests

-(void) testAppLaunchBeacon
{
  [MPAppLaunchBeacon sendBeacon];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self validateBeacons:@[@[]]];
}

-(void) testSendThreeLaunchBeacons
{
  [MPAppLaunchBeacon sendBeacon];
  [MPAppLaunchBeacon sendBeacon];
  [MPAppLaunchBeacon sendBeacon];
  
  // Sleep - waiting for beacons to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for 3 beacons
  [self validateBeacons:@[@[], @[], @[]]];
}

-(void) testDimensions
{
  [[MPulse sharedInstance] setViewGroup:@"Foo"];
  [[MPulse sharedInstance] setABTest:@"A/B"];
  [MPAppLaunchBeacon sendBeacon];
  
  [[MPulse sharedInstance] resetViewGroup];
  [[MPulse sharedInstance] resetABTest];
  [MPAppLaunchBeacon sendBeacon];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Should be no dimensions for a launch beacon
  [self validateBeacons:@[
                          @[@"", @""],
                          @[@"", @""]
                          ]];
}

-(void) testBeaconType
{
  MPAppLaunchBeacon *beacon = [[MPAppLaunchBeacon alloc] init];
  
  XCTAssertNotNil(beacon);
  XCTAssertEqual([beacon getBeaconType], APP_LAUNCH);
}

@end
