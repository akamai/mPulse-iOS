//
//  MPConfigTimerTests.m
//  Boomerang
//
//  Created by Giri Senji on 5/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPConfigTimer.h"
#import "NSObject+TT_SBJSON.h"
#import "JSON.h"

@interface MPConfigTimerTests : XCTestCase

@end

@implementation MPConfigTimerTests

-(void) testActionTimer
{
  NSString *actionTimerJson = @"{\"name\":\"TapTimer\",\"index\":0,\"type\":\"TouchTimer\",\"label\":\"custom0\",\"start\":{\"action\":{\"name\":\"Tap\",\"locator\":\"text=Start Timer[1]\"}},\"end\":{\"action\":{\"name\":\"Tap\",\"locator\":\"text=End Timer[1]\"}}}";
  MPConfigTimer *timer = [[MPConfigTimer alloc] initWithDictionary:[actionTimerJson tt_JSONValue]];
  
  XCTAssertNotNil(timer, @"initWithDictionary should always return a valid MPConfigTimer.");
  
  XCTAssertEqualObjects(timer.name, @"TapTimer", @"Incorrect timer name.");
  XCTAssertEqual(timer.index, 0, @"Incorrect timer index.");
  XCTAssertEqualObjects(timer.type, @"TouchTimer", @"Incorrect timer type.");
  XCTAssertEqualObjects(timer.label, @"custom0", @"Incorrect timer type.");
}

-(void) testConditionTimer
{
  NSString *conditionalTimerJson = @"{\"name\":\"TestTimer\",\"index\":0,\"type\":\"TouchTimer\",\"label\":\"custom0\",\"start\":{\"condition\":{\"accessor\":\"output-isElementPresent\",\"locator\":\"text=testElement1\"}},\"end\":{\"condition\":{\"accessor\":\"output-isElementPresent\",\"locator\":\"text=testElement2\"}}}";

  MPConfigTimer *timer = [[MPConfigTimer alloc] initWithDictionary:[conditionalTimerJson tt_JSONValue]];
  
  XCTAssertNotNil(timer, @"initWithDictionary should always return a valid MPConfigTimer.");
  
  XCTAssertEqualObjects(timer.name, @"TestTimer", @"Incorrect timer name.");
  XCTAssertEqual(timer.index, 0, @"Incorrect timer index.");
  XCTAssertEqualObjects(timer.type, @"TouchTimer", @"Incorrect timer type.");
  XCTAssertEqualObjects(timer.label, @"custom0", @"Incorrect timer type.");
}

@end
