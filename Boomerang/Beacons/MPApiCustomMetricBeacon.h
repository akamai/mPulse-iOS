//
//  MPApiCustomMetricBeacon.h
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPApiCustomMetricBeacon : MPBeacon

//
// Methods
//

/**
 * Initialize with the specific metric name and value
 * @param metricName Metric name
 * @param value Value
 */
-(id) initWithMetricName:(NSString *)metricName andValue:(NSNumber *)value;

/**
 * Initialize with the specific metric index and value
 * @param metricIndex Metric index
 * @param value Value
 */
-(id) initWithMetricIndex:(NSInteger)metricIndex andValue:(NSNumber *)metricValue andName:(NSString *)metricName;

//
// Properties
//
/**
 * Metric name
 */
@property (readwrite) NSString *metricName;

//
// Properties on the Protobuf beacon
//
/**
 * Metric index
 */
@property NSInteger metricIndex;

/**
 * Metric value
 */
@property int32_t metricValue;

@end
