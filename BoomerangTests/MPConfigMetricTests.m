//
//  MPConfigMetricTests.m
//  Boomerang
//
//  Created by Giri Senji on 5/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPConfigMetric.h"
#import "NSObject+TT_SBJSON.h"
#import "NSString+MPExtensions.h"
#import "JSON.h"

@interface MPConfigMetricTests : XCTestCase

@end

@implementation MPConfigMetricTests

-(void) testActionMetric
{
  NSString *metricJson = @"{\"name\":\"MetricButton\",\"index\":0,\"type\":\"TouchMetric\",\"label\":\"cmet.MetricButton\",\"dataType\":\"Currency\",\"action\":{\"name\":\"Tap\",\"locator\":\"text=Touch Metric Button[1]\"},\"extract\":{\"accessor\":\"output-elementText\",\"locator\":\"classname=UILabel[1]\"}}";
  MPConfigMetric *metric = [[MPConfigMetric alloc] initWithDictionary:[metricJson tt_JSONValue]];
  
  XCTAssertNotNil(metric, @"initWithDictionary should always return a valid MPConfigMetric.");
  
  XCTAssertEqualObjects(metric.name, @"MetricButton", @"Incorrect metric name.");
  XCTAssertEqual(metric.index, 0, @"Incorrect metric index.");
  XCTAssertEqualObjects(metric.type, @"TouchMetric", @"Incorrect metric type.");
  XCTAssertEqualObjects(metric.label, @"cmet.MetricButton", @"Incorrect metric type.");
}

-(void) testConditionMetric
{
  NSString *metricJson = @"{\"name\":\"CondMetric\",\"index\":1,\"type\":\"TouchMetric\",\"label\":\"cmet.CondMetric\",\"dataType\":\"Currency\",\"condition\":{\"accessor\":\"output-elementPropertyValue\",\"locator\":\"text=Touch Metric Button[1]\",\"value\":\"1\",\"propertyName\":\"enabled\"},\"extract\":{\"accessor\":\"output-elementText\",\"locator\":\"classname=UILabel[1]\"}}";
  MPConfigMetric *metric = [[MPConfigMetric alloc] initWithDictionary:[metricJson tt_JSONValue]];
  
  XCTAssertNotNil(metric, @"initWithDictionary should always return a valid MPConfigMetric.");
  
  XCTAssertEqualObjects(metric.name, @"CondMetric", @"Incorrect metric name.");
  XCTAssertEqual(metric.index, 1, @"Incorrect metric index.");
  XCTAssertEqualObjects(metric.type, @"TouchMetric", @"Incorrect metric type.");
  XCTAssertEqualObjects(metric.label, @"cmet.CondMetric", @"Incorrect metric type.");
}

@end
