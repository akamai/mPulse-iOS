//
//  MPTouchMetricTests.m
//  Boomerang
//
//  Created by Giri Senji on 5/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPTouchMetric.h"
#import "NSObject+TT_SBJSON.h"
#import "NSString+MPExtensions.h"
#import "JSON.h"

@interface MPTouchMetricTests : XCTestCase

@end

@implementation MPTouchMetricTests

- (void)setUp
{
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testActionMetric
{
  NSString *metricJson = @"{\"name\":\"MetricButton\",\"index\":0,\"type\":\"TouchMetric\",\"label\":\"cmet.MetricButton\",\"dataType\":\"Currency\",\"action\":{\"name\":\"Tap\",\"locator\":\"text=Touch Metric Button[1]\"},\"extract\":{\"accessor\":\"output-elementText\",\"locator\":\"classname=UILabel[1]\"}}";
  MPTouchMetric *metric = [[MPTouchMetric alloc] initWithDictionary:[metricJson tt_JSONValue]];
  
  XCTAssertNotNil(metric, @"initWithDictionary should always return a valid MPTouchMetric.");
  
  XCTAssertEqualObjects(metric.name, @"MetricButton", @"Incorrect metric name.");
  XCTAssertEqual(metric.index, 0, @"Incorrect metric index.");
  XCTAssertEqualObjects(metric.type, @"TouchMetric", @"Incorrect metric type.");
  XCTAssertEqualObjects(metric.label, @"cmet.MetricButton", @"Incorrect metric type.");
  XCTAssertNotNil(metric.action, @"action should not be nil");
  XCTAssertEqualObjects(metric.action.name, @"Tap", @"Incorrect metric action name.");
  XCTAssertEqualObjects([metric.action.locator serializeShort], @"text=Touch Metric Button[1]", @"Incorrect metric action locator.");
  XCTAssertEqualObjects(metric.extract.accessor, @"output-elementText", @"Incorrect metric extract accessor.");
  XCTAssertEqualObjects([metric.extract.locator serializeShort], @"classname=UILabel[1]", @"Incorrect metric extract locator.");
}

- (void)testConditionMetric
{
  NSString *metricJson = @"{\"name\":\"CondMetric\",\"index\":1,\"type\":\"TouchMetric\",\"label\":\"cmet.CondMetric\",\"dataType\":\"Currency\",\"condition\":{\"accessor\":\"output-elementPropertyValue\",\"locator\":\"text=Touch Metric Button[1]\",\"value\":\"1\",\"propertyName\":\"enabled\"},\"extract\":{\"accessor\":\"output-elementText\",\"locator\":\"classname=UILabel[1]\"}}";
  MPTouchMetric *metric = [[MPTouchMetric alloc] initWithDictionary:[metricJson tt_JSONValue]];
  
  XCTAssertNotNil(metric, @"initWithDictionary should always return a valid MPTouchMetric.");
  
  XCTAssertEqualObjects(metric.name, @"CondMetric", @"Incorrect metric name.");
  XCTAssertEqual(metric.index, 1, @"Incorrect metric index.");
  XCTAssertEqualObjects(metric.type, @"TouchMetric", @"Incorrect metric type.");
  XCTAssertEqualObjects(metric.label, @"cmet.CondMetric", @"Incorrect metric type.");
  XCTAssertNotNil(metric.condition, @"condition should not be nil");
  XCTAssertEqualObjects(metric.condition.accessor, @"output-elementPropertyValue", @"Incorrect metric condition accessor.");
  XCTAssertEqualObjects([metric.condition.locator serializeShort], @"text=Touch Metric Button[1]", @"Incorrect metric condition locator.");
  XCTAssertEqualObjects(metric.condition.propertyName, @"enabled", @"Incorrect metric condition propertyName.");
  XCTAssertEqualObjects(metric.condition.value, @"1", @"Incorrect metric condition value.");
  XCTAssertEqualObjects(metric.extract.accessor, @"output-elementText", @"Incorrect metric extract accessor.");
  XCTAssertEqualObjects([metric.extract.locator serializeShort], @"classname=UILabel[1]", @"Incorrect metric extract locator.");
}

- (void)testNumberValueParsing
{
  NSNumber *valueNumber = [@"$10.92" mp_numberValue:@"Currency"];
  XCTAssertEqual(1092, valueNumber.floatValue);
  
  valueNumber = [@"$##10.92,@" mp_numberValue:@"Currency"];
  XCTAssertEqual(1092, valueNumber.floatValue);
  
  valueNumber = [@"$##10.92,@" mp_numberValue:nil];
  XCTAssertEqual(10, valueNumber.intValue);
  
  valueNumber = [@"$##-10.92,@" mp_numberValue:nil];
  XCTAssertEqual(-10, valueNumber.intValue);
  
  valueNumber = [@"$29" mp_numberValue:@"Currency"];
  XCTAssertEqual(2900, valueNumber.floatValue);
  
  valueNumber = [@"$29" mp_numberValue:@"Currency"];
  XCTAssertEqual(2900, valueNumber.intValue);
 }

@end
