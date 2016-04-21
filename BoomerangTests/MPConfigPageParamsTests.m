//
//  MPConfigPageParamsTests.m
//  Boomerang
//
//  Created by Nicholas Jansma on 3/28/16.
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPConfigPageParams.h"
#import "NSObject+TT_SBJSON.h"
#import "NSString+MPExtensions.h"
#import "JSON.h"

@interface MPConfigPageParamsTests : XCTestCase

@end

@implementation MPConfigPageParamsTests

-(void) testInitWithJSONWithEmptyJSONArrays
{
  // Human readable version of JSON
  //    {
  //      "pageGroups": [],
  //      "customMetrics": [],
  //      "customTimers": []
  //    }
  NSString *metricJson = @"{\"pageGroups\": [], \"customMetrics\": [],\"customTimers\": []}";

  MPConfigPageParams *params = [[MPConfigPageParams alloc] initWithJson:[metricJson tt_JSONValue]];

  XCTAssertNotNil(params, @"initWithJson should always return a valid MPConfigPageParams.");

  XCTAssertEqual([params.pageGroups count], 0, @"Incorrect page group name.");
  XCTAssertEqual([params.metrics count], 0, @"Incorrect metrics name.");
  XCTAssertEqual([params.timers count], 0, @"Incorrect timers name.");
  XCTAssertEqual([params.dimensions count], 0, @"Incorrect dimensions name.");
}

-(void) testInitWithJSONWithMultipleEntriesInJSONArrays
{
  // Human readable version of JSON
  //    {
  //      "pageGroups": [
  //          {},
  //          {},
  //          {}
  //      ],
  //      "customMetrics": [
  //          {},
  //          {},
  //          {}
  //      ],
  //      "customTimers": [
  //          {},
  //          {}
  //      ]
  //    }
  NSString *metricJson = @"{\"pageGroups\": [{},{},{}], \"customMetrics\": [{},{},{}],\"customTimers\": [{},{}]}";

  MPConfigPageParams *params = [[MPConfigPageParams alloc] initWithJson:[metricJson tt_JSONValue]];

  XCTAssertNotNil(params, @"initWithJson should always return a valid MPConfigPageParams.");

  XCTAssertEqual([params.pageGroups count], 3, @"Incorrect page group name.");
  XCTAssertEqual([params.metrics count], 3, @"Incorrect metrics name.");
  XCTAssertEqual([params.timers count], 2, @"Incorrect timers name.");
  XCTAssertEqual([params.dimensions count], 0, @"Incorrect dimensions name.");
}

@end
