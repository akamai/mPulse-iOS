//
//  MPApiCustomMetricBeaconTests.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPApiCustomMetricBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPSession.h"
#import "MPBeaconTestBase.h"

@interface MPApiCustomMetricBeaconTests : MPBeaconTestBase
{
}

@end

@implementation MPApiCustomMetricBeaconTests

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

/*
 * Checks if the records collected by MPBeaconCollector have the desired number of 
 * beacons and custom metric values.
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
    
    // get tested name, index and value
    NSString *metricName = [validation objectAtIndex:0];
    NSNumber *metricIndex = [validation objectAtIndex:1];
    NSNumber *metricValue = [validation objectAtIndex:2];
    
    // view group
    NSString *viewGroup = @"";

    if ([validation count] >= 4)
    {
      viewGroup = [validation objectAtIndex:3];
    }
    
    // a/b test
    NSString *abTest = @"";

    if ([validation count] >= 5)
    {
      abTest = [validation objectAtIndex:4];
    }
    
    // compare the beacon for this validation
    MPApiCustomMetricBeacon *beacon = [testBeacons objectAtIndex:i];
    
    MPLogDebug(@"Metric Name : %@ Index : %ld Value : %d",
               beacon.metricName,
               (long)beacon.metricIndex,
               beacon.metricValue);
    
    XCTAssertEqual([beacon getBeaconType], API_CUSTOM_METRIC, "Beacon type");
    
    XCTAssertTrue([beacon.metricName isEqualToString:metricName], "Custom Metric name error");
    
    XCTAssertEqual(beacon.metricIndex, [metricIndex longValue], "Custom Metric index error");
    
    XCTAssertEqual(beacon.metricValue, [metricValue longValue], "Custom Metric value error");

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
#pragma mark Metric Beacon Tests

-(void) testSendMetricBeacon
{
  [[MPulse sharedInstance] sendMetric:@"Metric1" value:@1];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test the one beacon
  [self validateBeacons:@[
                          @[@"Metric1", @0, @1]
                        ]];
}

-(void) testSendThreeMetricBeacons
{
  [[MPulse sharedInstance] sendMetric:@"Metric1" value:@1];
  [[MPulse sharedInstance] sendMetric:@"Metric1" value:@2];
  [[MPulse sharedInstance] sendMetric:@"Metric2" value:@3];
  
  // Sleep - waiting for beacons to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for 3 beacons
  [self validateBeacons:@[
                          @[@"Metric1", @0, @1],
                          @[@"Metric1", @0, @2],
                          @[@"Metric2", @1, @3]
                        ]];
}

-(void) testUnknownMetricName
{
  [[MPulse sharedInstance] sendMetric:@"MetricUnknown" value:@1];
  
  // Sleep - waiting for beacons to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // No beacons
  [self validateBeacons:@[]];
}

-(void) testDimensions
{
  [[MPulse sharedInstance] setViewGroup:@"Foo"];
  [[MPulse sharedInstance] setABTest:@"A/B"];
  [[MPulse sharedInstance] sendMetric:@"Metric1" value:@1];
  
  [[MPulse sharedInstance] resetViewGroup];
  [[MPulse sharedInstance] resetABTest];
  [[MPulse sharedInstance] sendMetric:@"Metric2" value:@2];
  
  // Sleep - waiting for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];
  
  // Test for time beacon being added to the batch with duration exactly 3 seconds
  [self validateBeacons:@[
                          @[@"Metric1", @0, @1, @"Foo", @"A/B"],
                          @[@"Metric2", @1, @2, @"", @""]
                        ]];
}

-(void) testBeaconType
{
  MPApiCustomMetricBeacon *beacon = [[MPApiCustomMetricBeacon alloc] initWithMetricName:@"Metric1" andValue:@1];
  
  XCTAssertNotNil(beacon);
  XCTAssertEqual([beacon getBeaconType], API_CUSTOM_METRIC);
}

@end
