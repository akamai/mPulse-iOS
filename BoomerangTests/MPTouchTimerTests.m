//
//  MPTouchTimerTests.m
//  Boomerang
//
//  Created by Giri Senji on 5/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPTouchTimer.h"
#import "NSObject+TT_SBJSON.h"
#import "JSON.h"

@interface MPTouchTimerTests : XCTestCase

@end

@implementation MPTouchTimerTests

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

- (void)testActionTimer
{
  NSString *actionTimerJson = @"{\"name\":\"TapTimer\",\"index\":0,\"type\":\"TouchTimer\",\"label\":\"custom0\",\"start\":{\"action\":{\"name\":\"Tap\",\"locator\":\"text=Start Timer[1]\"}},\"end\":{\"action\":{\"name\":\"Tap\",\"locator\":\"text=End Timer[1]\"}}}";
  MPTouchTimer *timer = [[MPTouchTimer alloc] initWithDictionary:[actionTimerJson tt_JSONValue]];
  
  XCTAssertNotNil(timer, @"initWithDictionary should always return a valid MPTouchTimer.");
  
  XCTAssertEqualObjects(timer.name, @"TapTimer", @"Incorrect timer name.");
  XCTAssertEqual(timer.index, 0, @"Incorrect timer index.");
  XCTAssertEqualObjects(timer.type, @"TouchTimer", @"Incorrect timer type.");
  XCTAssertEqualObjects(timer.label, @"custom0", @"Incorrect timer type.");
  XCTAssertNotNil(timer.startAction, @"timer startAction should not be nil");
  XCTAssertNil(timer.startCondition, @"timer startCondition must be nil");
  XCTAssertEqualObjects(timer.startAction.name, @"Tap", @"Incorrect startAction name.");
  XCTAssertEqualObjects([timer.startAction.locator serializeShort], @"text=Start Timer[1]", @"Incorrect startAction locator.");
  XCTAssertNotNil(timer.endAction, @"timer endAction should not be nil");
  XCTAssertNil(timer.endCondition, @"timer endCondition must be nil");
  XCTAssertEqualObjects(timer.endAction.name, @"Tap", @"Incorrect endAction name.");
  XCTAssertEqualObjects([timer.endAction.locator serializeShort], @"text=End Timer[1]", @"Incorrect endAction locator.");
}

- (void)testConditionTimer
{
  NSString* conditionalTimerJson = @"{\"name\":\"TestTimer\",\"index\":0,\"type\":\"TouchTimer\",\"label\":\"custom0\",\"start\":{\"condition\":{\"accessor\":\"output-isElementPresent\",\"locator\":\"text=testElement1\"}},\"end\":{\"condition\":{\"accessor\":\"output-isElementPresent\",\"locator\":\"text=testElement2\"}}}";

  MPTouchTimer *timer = [[MPTouchTimer alloc] initWithDictionary:[conditionalTimerJson tt_JSONValue]];
  
  XCTAssertNotNil(timer, @"initWithDictionary should always return a valid MPTouchTimer.");
  
  XCTAssertEqualObjects(timer.name, @"TestTimer", @"Incorrect timer name.");
  XCTAssertEqual(timer.index, 0, @"Incorrect timer index.");
  XCTAssertEqualObjects(timer.type, @"TouchTimer", @"Incorrect timer type.");
  XCTAssertEqualObjects(timer.label, @"custom0", @"Incorrect timer type.");
  XCTAssertNotNil(timer.startCondition, @"timer startCondition should not be nil");
  XCTAssertNil(timer.startAction, @"timer startAction must be nil");
  XCTAssertEqualObjects(timer.startCondition.accessor, @"output-isElementPresent", @"Incorrect startCondition name.");
  XCTAssertEqualObjects([timer.startCondition.locator serializeShort], @"text=testElement1", @"Incorrect startCondition locator.");
  XCTAssertNotNil(timer.endCondition, @"timer endCondition should not be nil");
  XCTAssertNil(timer.endAction, @"timer endAction must be nil");
  XCTAssertEqualObjects(timer.endCondition.accessor, @"output-isElementPresent", @"Incorrect endCondition name.");
  XCTAssertEqualObjects([timer.endCondition.locator serializeShort], @"text=testElement2", @"Incorrect endCondition locator.");
}

@end
