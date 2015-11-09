//
//  MPBucketUtility.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/21/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBucketUtility.h"

@implementation MPBucketUtility

int const NUM_BUCKETS = 122;

/**
 * The list of variable width timer buckets used by various parts of the system.
 * <p>
 * These buckets are primarily relevant for timers.  There are 122 bucket intervals
 * ranging from 1ms to 10 minutes. Each bucket's value is the supremum of (least
 * upper bound of the open interval ending at) the bucket.  The closed lower bound
 * of the bucket is the value of the previous bucket or 0 if no previous bucket exists (ie.
 * these are the bucket end times).
 * </p>
 * <p>
 * In Mathematical notation, a bucket's range is:<br><code><strong>[</strong>&lt;value of previous bucket or 0&gt;, &lt;value of bucket&gt;<strong>)</strong></code>
 * </p>
 */
const static int _bucket[] = {
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,  // 20
  22, 24, 26, 28, 30, 32, 34, 36, 38, 40,                                 // 10
  45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100,                        // 12
  110, 120, 130, 140, 150,                                                // 5
  170, 190, 210, 230, 250,                                                // 5
  300, 350, 400, 450, 500, 550, 600,                                      // 7
  700, 800, 900,                                                          // 3
  1050, 1200, 1350, 1500, 1650, 1800, 1950, 2100, 2250, 2400, 2550, 2700, 2850, 3000, 3150, 3300, 3450, 3600, 3750, 3950, 4200,               // 21
  4500, 4800, 5100, 5400, 5700, 6000, 6300, 6600, 6900, 7200, 7500, 7800, 8100, 8400, 8700, 9000, 9300, 9600, 9900, 10200, 10500, 10800,      // 22
  11400, 12000, 12600, 13200, 13800, 14400, 15000, 16200, 17400, 18600, 20000, 37500, 75000, 150000, 300000, 450000, 600001                   // 17
};


/**
 * Get the bucket index that a particular timer value would fit into.
 * Given a timer value, this method looks through its internal list of buckets and determines which
 * bucket the timer value would fit into.
 * Note: after calling this method, must check whether the index returned >= 0 && < NUM_BUCKETS.
 * BucketUtilityTests.test_getBucketIndex tests this method.
 * @param timer_value the value of the timer to find a bucket for
 * @return  the index of the bucket that the time value will fit into.  The lower bound is 0, the upper bound is equal to buckets.length
 */
+ (int) getBucketIndex:(int) timer_value
{
  for (int index=0; index<NUM_BUCKETS; index++)
  {
    int bucket_value = _bucket[index];
    if (bucket_value < timer_value)
    {
      continue; // Continue to find a value which either matches or is bigger than timer_value.
    }
    else if (bucket_value == timer_value)
    {
      return index+1; // bucket_value matches the timer_value, thus it can be put in the next bucket.
    }
    else if (bucket_value > timer_value)
    {
      return index; // bucket_value is larger than the timer_value, thus timer_value can be put in this bucket.
    }
  }
  
  // Our buckets can handle time duration as large as 10 minutes but Connection timeouts are usually much lower than that.
  // Thus a time duration value larger than 10 minutes is invalid and should be rejected/ignored.
  // The reason why NUM_BUCKETS is used instead of other invalid index, is to make it align with the Android version.
  return NUM_BUCKETS;
}

@end
