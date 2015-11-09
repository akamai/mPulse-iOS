//
//  MPTimerData.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTimerData.h"
#import "MPBucketUtility.h"
#import "MPNumberDictionary.h"

@implementation MPTimerData
{
  MPNumberDictionary* _histogram;
}

-(id)init
{
  self = [super init];
  if (self)
  {
    _min = -1;
  }
  return self;
}

-(void)addBeacon:(NSTimeInterval)duration
{
  int durationMS = (duration * 1000); // Convert to milliseconds
  int bucketIndex = [MPBucketUtility getBucketIndex:durationMS]; // Get bucket index
    
  // Check for invalid index
  if (bucketIndex < 0 || bucketIndex >= NUM_BUCKETS)
  {
    MPLogDebug(@"Invalid Request Duration: %d ms. Ignoring.", durationMS);
    return;
  }
  
  _count++;

  if (_min == -1 || _min > durationMS)
  {
    _min = durationMS;
  }
  if (_max < durationMS)
  {
    _max = durationMS;
  }
  
  _sum += durationMS;
  _sumOfSquares += (durationMS * durationMS);

  if (_histogram == nil)
  {
    _histogram = [[MPNumberDictionary alloc] init];
  }

  [_histogram incrementBucket:bucketIndex value:1];
}

-(BOOL)hasHistogram
{
  return _histogram.count > 0;
}

-(int*)histogramArray
{
  return [_histogram asCArray:NUM_BUCKETS];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[TimerData: count=%d, min=%d, max=%d, sum=%ld, sumOfSquares=%ld]", _count, _min, _max, _sum, _sumOfSquares];
}

@end
