//
//  MPAppCrashBeacon.h
//  Boomerang
//
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPBeacon.h"

@interface MPAppCrashBeacon : MPBeacon

/**
 * Sends the beacon
 */
+(void) sendBeacon;

//
// Properties on the Protobuf beacon
//
/**
 * Crash code
 */
@property NSNumber *code;

/**
 * Crash message
 */
@property NSString *message;

/**
 * Crash function
 */
@property NSString *function;

/**
 * Crash file
 */
@property NSString *file;

/**
 * Crash line
 */
@property NSNumber *line;

/**
 * Crash character
 */
@property NSNumber *character;

/**
 * Crash stack
 */
@property NSString *stack;

@end
