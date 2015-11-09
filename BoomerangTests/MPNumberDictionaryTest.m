//
//  MPNumberDictionaryTest.m
//  Boomerang
//
//  Created by Matthew Solnit on 5/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBucketUtility.h"
#import "MPNumberDictionary.h"

@interface MPNumberDictionaryTest : XCTestCase

@end

@implementation MPNumberDictionaryTest

- (void)testEmpty
{
  MPNumberDictionary* dict = [[MPNumberDictionary alloc] init];
  XCTAssertEqual(0, dict.count, @"Incorrect count for empty dictionary.");
  NSArray* array1 = [dict asNSArray];
  XCTAssertNil(array1, @"Empty dictionary should always return nil NSArray.");
  int* array2 = [dict asCArray:NUM_BUCKETS];
  XCTAssertTrue(array2 == NULL, @"Empty dictionary should always return null C array.");
}

- (void)testNSarray
{
  MPNumberDictionary* dict = [[MPNumberDictionary alloc] init];

  [dict incrementBucket:0 value:1];
  [dict incrementBucket:1 value:2];
  [dict incrementBucket:1 value:2];
  [dict incrementBucket:2 value:3];
  [dict incrementBucket:2 value:3];
  [dict incrementBucket:2 value:3];

  // Non-consecutive bucket (leaves a gap from the previous ones).
  [dict incrementBucket:5 value:6];

  NSArray* array = [dict asNSArray];
  XCTAssertNotNil(array, @"Non-empty dictionary should always return a valid NSArray.");
  XCTAssertEqual(6, array.count, @"The array should have one element per bucket, including gaps.");
  XCTAssertEqualObjects([NSNumber numberWithInt:1], [array objectAtIndex:0], @"Incorrect value for 0th bucket.");
  XCTAssertEqualObjects([NSNumber numberWithInt:4], [array objectAtIndex:1], @"Incorrect value for 1st bucket.");
  XCTAssertEqualObjects([NSNumber numberWithInt:9], [array objectAtIndex:2], @"Incorrect value for 2nd bucket.");
  XCTAssertEqualObjects([NSNumber numberWithInt:0], [array objectAtIndex:3], @"Incorrect value for 3rd bucket.");
  XCTAssertEqualObjects([NSNumber numberWithInt:0], [array objectAtIndex:4], @"Incorrect value for 4th bucket.");
  XCTAssertEqualObjects([NSNumber numberWithInt:6], [array objectAtIndex:5], @"Incorrect value for 5th bucket.");
}

- (void)testCArray
{
  MPNumberDictionary* dict = [[MPNumberDictionary alloc] init];
  
  [dict incrementBucket:0 value:1];
  [dict incrementBucket:1 value:2];
  [dict incrementBucket:1 value:2];
  [dict incrementBucket:2 value:3];
  [dict incrementBucket:2 value:3];
  [dict incrementBucket:2 value:3];
  
  // Non-consecutive bucket (leaves a gap from the previous ones).
  [dict incrementBucket:5 value:6];
  
  int* array = [dict asCArray:NUM_BUCKETS];
  XCTAssertTrue(array != NULL, @"Non-empty dictionary should always return a valid C array.");
  XCTAssertEqual(1, array[0], @"Incorrect value for 0th bucket.");
  XCTAssertEqual(4, array[1], @"Incorrect value for 1st bucket.");
  XCTAssertEqual(9, array[2], @"Incorrect value for 2nd bucket.");
  XCTAssertEqual(0, array[3], @"Incorrect value for 3rd bucket.");
  XCTAssertEqual(0, array[4], @"Incorrect value for 4th bucket.");
  XCTAssertEqual(6, array[5], @"Incorrect value for 5th bucket.");
  
  // Clean up.
  free(array);
}

@end
