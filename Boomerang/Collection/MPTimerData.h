//
//  MPTimerData.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPTimerData : NSObject

@property (readonly) int count;
@property (readonly) int min;
@property (readonly) int max;
@property (readonly) long sum;
@property (readonly) long sumOfSquares;

-(void)addBeacon:(NSTimeInterval)duration;

-(BOOL)hasHistogram;
-(int*)histogramArray;

@end
