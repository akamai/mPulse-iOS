//
//  MPMetricBeacon.h
//  Boomerang
//
//  Created by Tana Jackson on 4/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPMetricBeacon : MPBeacon

-(id) initWithMetricName:(NSString *)metricName andValue:(NSNumber *)value;
-(id) initWithMetricIndex:(NSInteger)metricIndex andValue:(NSNumber *)metricValue;

@end
