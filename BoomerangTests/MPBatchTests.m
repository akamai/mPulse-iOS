//
//  MPBatchTests.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/26/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MPBatch.h"
#import "MPBucketUtility.h"
#import "NSString+MPExtensions.h"

@interface MPBatchTests : XCTestCase

@end

@implementation MPBatchTests

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

- (void)testConvert
{
  NSLog(@"Testing sparse 16-bit format.");
  [self convert:(Byte) 1]; // sparse - short
  NSLog(@"");

  NSLog(@"Testing dense 16-bit format.");
  [self convert:(Byte) 0]; // dense - int
  NSLog(@"");

  NSLog(@"Testing sparse 32-bit format.");
  [self convert:(Byte) 2]; // sparse - int
  NSLog(@"");
}

-(void)convert:(Byte)format
{
  int val = 0xFFFF;
  int* values = (int*)calloc(NUM_BUCKETS, sizeof(int));
  int dataLength;
  Byte* data = [MPBatch histogramIntArrayToBinary:values withLength:NUM_BUCKETS andFormat:format outputLength:&dataLength];
  if (format == 1)
  {
    XCTAssert(data == NULL, "all zeros in histogram array should return null");
  }
  for (int i = 0; i < NUM_BUCKETS; i++)
  {
    values[i] = val--;
  }
  data = [MPBatch histogramIntArrayToBinary:values withLength:NUM_BUCKETS andFormat:format outputLength:&dataLength];
  XCTAssertEqual(0, data[0] & 0x7F, "since the first array element is set the marker byte delta must be zero");
  if (format == 1)
  {
    XCTAssertEqual(0, data[364] & 0x7F, "last sparse delta must be zero");
  }

  int* converted = [MPBatch binaryHistogramToIntArray:data withLength:dataLength];
  NSLog(@"values #1: %@", [NSString mp_stringWithIntArray:values andLength:NUM_BUCKETS]);
  NSLog(@"conver #1: %@", [NSString mp_stringWithIntArray:converted andLength:NUM_BUCKETS]);
  [self assertArraysEqual:values a2:converted length:NUM_BUCKETS];

  // overflow
  val = INT_MAX;
  for (int i = 0; i < NUM_BUCKETS; i++)
  {
    values[i] = val--;
  }
  data = [MPBatch histogramIntArrayToBinary:values withLength:NUM_BUCKETS andFormat:format outputLength:&dataLength];
  converted = [MPBatch binaryHistogramToIntArray:data withLength:dataLength];
  if (format == 1)
  {
    for (int i = 0; i < NUM_BUCKETS; i++)
    {
      XCTAssertEqual(0xFFFF, converted[i]);
    }
  }
  else
  {
    NSLog(@"values #2 (overflow test): %@", [NSString mp_stringWithIntArray:values andLength:NUM_BUCKETS]);
    NSLog(@"conver #2 (overflow test): %@", [NSString mp_stringWithIntArray:converted andLength:NUM_BUCKETS]);
    [self assertArraysEqual:values a2:converted length:NUM_BUCKETS];
  }

  for (int i = 0; i < NUM_BUCKETS; i++)
  {
    values[i] = i;
  }
  data = [MPBatch histogramIntArrayToBinary:values withLength:NUM_BUCKETS andFormat:format outputLength:&dataLength];
  converted = [MPBatch binaryHistogramToIntArray:data withLength:dataLength];
  NSLog(@"values #1: %@", [NSString mp_stringWithIntArray:values andLength:NUM_BUCKETS]);
  NSLog(@"conver #1: %@", [NSString mp_stringWithIntArray:converted andLength:NUM_BUCKETS]);
  [self assertArraysEqual:values a2:converted length:NUM_BUCKETS];

  for (int i = 0; i < NUM_BUCKETS; i++)
  {
    values[i] = 0;
  }
  // some random buckets
  values[10] = 555;
  values[15] = 554;
  values[16] = 553;
  values[17] = 552;
  values[45] = 551;
  values[49] = 550;
  values[67] = 549;
  values[69] = 548;
  values[77] = 547;
  values[80] = 546;
  values[100] = 545;
  values[121] = 544;
  data = [MPBatch histogramIntArrayToBinary:values withLength:NUM_BUCKETS andFormat:format outputLength:&dataLength];
  converted = [MPBatch binaryHistogramToIntArray:data withLength:dataLength];
  NSLog(@"data #4: %@", [NSString mp_stringWithByteArray:data andLength:dataLength]);
  NSLog(@"values #4: %@", [NSString mp_stringWithIntArray:values andLength:NUM_BUCKETS]);
  NSLog(@"conver #4: %@", [NSString mp_stringWithIntArray:converted andLength:NUM_BUCKETS]);
  [self assertArraysEqual:values a2:converted length:NUM_BUCKETS];

  // test offsets reference next entry -- maintain integrity of the forward references
  int mult = format == 1 ? 3 : 5;
  int offset = format; // skip the marker bytes for sparse format
  int index = 0;
  int prev = 0;
  int deltaCounter = 0;
  if (format == 0)
  {
    for (int i = 0; i < NUM_BUCKETS; i++)
    {
      if (values[i] == 0)
      {
        index++;
        continue;
      }
      deltaCounter += data[(prev * mult) + offset];
      XCTAssertEqual(i, deltaCounter, "the sum of deltas match the current array position");
      prev = index++;
    }
  }
  else
  {
    deltaCounter = 10;
    for (int i = 0; i < NUM_BUCKETS; i++)
    {
      if (values[i] == 0)
        continue;
      XCTAssertEqual(i, deltaCounter, "the sum of deltas match the current array position");
      deltaCounter += data[(index++ * mult) + offset];
    }
  }
}

-(void)assertArraysEqual:(int[])a1 a2:(int[])a2 length:(int)length
{
  for (int i = 0; i < length; i++)
  {
    XCTAssertEqual(a1[i], a2[i], "Incorrect value at array index: %d", i);
  }
}

@end
