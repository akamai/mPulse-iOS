//
//  MPBatchRecordTests.m
//  Boomerang
//
//  Created by Matthew Solnit on 5/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBatchRecord.h"
#import "MPBeacon.h"
#import "MPTimerData.h"

@interface MPBatchRecordTests : XCTestCase

@end

@implementation MPBatchRecordTests

- (void)testCustomTimers
{
  MPBatchRecord* batchRecord = [[MPBatchRecord alloc] init];

  XCTAssertFalse([batchRecord hasCustomTimers], @"New batch record should not have any custom timers.");
  XCTAssertNil([batchRecord customTimerArray], @"New batch record should not return a valid timer array.");

  MPBeacon* timer0Beacon = [[MPBeacon alloc] init];
  timer0Beacon.timerIndex = 0;
  timer0Beacon.timerValue = 5;
  [batchRecord addBeacon:timer0Beacon];

  XCTAssertTrue([batchRecord hasCustomTimers], @"After adding a custom timer beacon, \"hasCustomTimers\" should return true.");

  MPBeacon* timer1Beacon = [[MPBeacon alloc] init];
  timer1Beacon.timerIndex = 1;
  timer1Beacon.timerValue = 3;
  [batchRecord addBeacon:timer1Beacon];
  
  XCTAssertTrue([batchRecord hasCustomTimers], @"After adding a second custom timer beacon, \"hasCustomTimers\" should still return true.");

  NSArray* timerArray = [batchRecord customTimerArray];
  XCTAssertNotNil(timerArray, @"After adding timer beacons, the batch record should return a valid timer array.");
  XCTAssertEqual(2, timerArray.count, @"Incorrect # of timers in the array.");

  [self testTimerData:[timerArray objectAtIndex:0] expectedCount:1 expectedMin:5000 expectedMax:5000 expectedSum:5000 expectedSumOfSquares:25000000 expectedHasHistogram:YES];
  [self testTimerData:[timerArray objectAtIndex:1] expectedCount:1 expectedMin:3000 expectedMax:3000 expectedSum:3000 expectedSumOfSquares:9000000 expectedHasHistogram:YES];
}

-(void)testNonConsecutiveCustomTimers
{
  MPBatchRecord* batchRecord = [[MPBatchRecord alloc] init];
  
  XCTAssertFalse([batchRecord hasCustomTimers], @"New batch record should not have any custom timers.");
  XCTAssertNil([batchRecord customTimerArray], @"New batch record should not return a valid timer array.");
  
  MPBeacon* timer0Beacon = [[MPBeacon alloc] init];
  timer0Beacon.timerIndex = 1;
  timer0Beacon.timerValue = 5;
  [batchRecord addBeacon:timer0Beacon];
  
  XCTAssertTrue([batchRecord hasCustomTimers], @"After adding a custom timer beacon, \"hasCustomTimers\" should return true.");
  
  MPBeacon* timer1Beacon = [[MPBeacon alloc] init];
  timer1Beacon.timerIndex = 4;
  timer1Beacon.timerValue = 3;
  [batchRecord addBeacon:timer1Beacon];
  
  XCTAssertTrue([batchRecord hasCustomTimers], @"After adding a second custom timer beacon, \"hasCustomTimers\" should still return true.");
  
  NSArray* timerArray = [batchRecord customTimerArray];
  XCTAssertNotNil(timerArray, @"After adding timer beacons, the batch record should return a valid timer array.");
  XCTAssertEqual(5, timerArray.count, @"Incorrect # of timers in the array (should be highest timer index, plus one).");
  
  [self testTimerData:[timerArray objectAtIndex:0] expectedCount:0 expectedMin:-1 expectedMax:0 expectedSum:0 expectedSumOfSquares:0 expectedHasHistogram:NO];
  [self testTimerData:[timerArray objectAtIndex:1] expectedCount:1 expectedMin:5000 expectedMax:5000 expectedSum:5000 expectedSumOfSquares:25000000 expectedHasHistogram:YES];
  [self testTimerData:[timerArray objectAtIndex:2] expectedCount:0 expectedMin:-1 expectedMax:0 expectedSum:0 expectedSumOfSquares:0 expectedHasHistogram:NO];
  [self testTimerData:[timerArray objectAtIndex:3] expectedCount:0 expectedMin:-1 expectedMax:0 expectedSum:0 expectedSumOfSquares:0 expectedHasHistogram:NO];
  [self testTimerData:[timerArray objectAtIndex:4] expectedCount:1 expectedMin:3000 expectedMax:3000 expectedSum:3000 expectedSumOfSquares:9000000 expectedHasHistogram:YES];
}

-(void)testTimerData:(MPTimerData*)timerData expectedCount:(int)expectedCount expectedMin:(int)expectedMin expectedMax:(int)expectedMax expectedSum:(long)expectedSum expectedSumOfSquares:(long)expectedSumOfSquares expectedHasHistogram:(BOOL)expectedHasHistogram
{
  XCTAssertNotNil(timerData, @"Timer data is missing.");
  
  XCTAssertEqual(expectedCount, timerData.count, @"Incorrect count.");
  XCTAssertEqual(expectedMin, timerData.min, @"Incorrect min.");
  XCTAssertEqual(expectedMax, timerData.max, @"Incorrect max.");
  XCTAssertEqual(expectedSum, timerData.sum, @"Incorrect sum.");
  XCTAssertEqual(expectedSumOfSquares, timerData.sumOfSquares, @"Incorrect sum of squares.");

  // TODO: Test the actual histogram content as well.
  XCTAssertEqual(expectedHasHistogram, timerData.hasHistogram, @"Incorrect \"has histogram\" flag.");
}

@end
