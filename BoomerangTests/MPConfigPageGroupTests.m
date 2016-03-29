//
//  MPConfigPageGroupTests.m
//  Boomerang
//
//  Created by Nicholas Jansma on 3/28/16.
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPConfigPageGroup.h"
#import "NSObject+TT_SBJSON.h"
#import "NSString+MPExtensions.h"
#import "JSON.h"

@interface MPConfigPageGroupTests : XCTestCase

@end

@implementation MPConfigPageGroupTests

-(void) testConfigPageGroup
{
  // Human readable version of JSON
  //    {
  //      "name": "MetricName",
  //      "index": "10",
  //      "type": "MetricType",
  //      "label": "MetricLabel",
  //      "dataType": "MetricDataType"
  //    }
  NSString *metricJson = @"{\"name\":\"MetricName\",\"index\":\"10\",\"type\":\"MetricType\",\"label\":\"MetricLabel\",\"dataType\":\"MetricDataType\"}";
  
  MPConfigPageGroup *metric = [[MPConfigPageGroup alloc] initWithDictionary:[metricJson tt_JSONValue]];
  
  XCTAssertNotNil(metric, @"initWithDictionary should always return a valid MPConfigMetric.");
  
  XCTAssertEqualObjects(metric.name, @"MetricName", @"Incorrect metric name.");
  XCTAssertEqual(metric.index, 10, @"Incorrect metric index.");
  XCTAssertEqualObjects(metric.type, @"MetricType", @"Incorrect metric type.");
  XCTAssertEqualObjects(metric.label, @"MetricLabel", @"Incorrect metric type.");
}

@end
