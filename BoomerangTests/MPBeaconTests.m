//
//  MPBeaconTests.m
//  Boomerang
//
//  Created by Nicholas Jansma on 10/15/15.
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPulse.h"
#import "MPBeacon.h"
#import "MPBeaconTestBase.h"

@interface MPBeaconTests : MPBeaconTestBase

@end

@implementation MPBeaconTests

-(void) testDimensions
{
  [[MPulse sharedInstance] setABTest:@"A/B"];
  [[MPulse sharedInstance] setViewGroup:@"View Group"];
  
  // create a beacon that will inherit the dimensions
  MPBeacon *beacon = [[MPBeacon alloc] init];
  
  XCTAssertEqual(beacon.abTest, @"A/B");
  XCTAssertEqual(beacon.pageGroup, @"View Group");
}

-(void) testClearPageDimensions
{
  [[MPulse sharedInstance] setABTest:@"A/B"];
  [[MPulse sharedInstance] setViewGroup:@"View Group"];
  
  // create a beacon that will inherit the dimensions
  MPBeacon *beacon = [[MPBeacon alloc] init];
  
  XCTAssertEqual(beacon.abTest, @"A/B");
  XCTAssertEqual(beacon.pageGroup, @"View Group");

  // clear dimensions
  [beacon clearPageDimensions];
  
  XCTAssertEqual(beacon.abTest, @"");
  XCTAssertEqual(beacon.pageGroup, @"");
}

-(void) testBeaconType
{
  MPBeacon *beacon = [[MPBeacon alloc] init];
  
  XCTAssertNotNil(beacon);
  XCTAssertEqual([beacon getBeaconType], BATCH);
}

@end
