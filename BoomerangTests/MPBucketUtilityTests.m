//
//  BucketUtilityTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/21/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBucketUtility.h"

@interface MPBucketUtilityTests : XCTestCase

@end

@implementation MPBucketUtilityTests

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

- (void)test_getBucketIndex
{
  int timers[7][2] = { {0, 0}, {1, 1}, {21, 20}, {42, 30}, {45, 31}, {599999, 121}, {600001, 122}  };
  
  for ( int i = 0; i < 7; i++ )
  {
    XCTAssertEqual(timers[i][1], [MPBucketUtility getBucketIndex:timers[i][0]], @"Bucket Index incorrect for timer= %d", timers[i][0]);
  }
}

@end
