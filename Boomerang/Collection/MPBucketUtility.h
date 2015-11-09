//
//  MPBucketUtility.h
//  Boomerang
//
//  Created by Mukul Sharma on 4/21/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPBucketUtility : NSObject

extern int const NUM_BUCKETS;

+ (int) getBucketIndex:(int) timer_value;

@end
