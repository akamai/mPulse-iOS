//
//  MPAppErrorBeacon.h
//  Boomerang
//
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPBeacon.h"

@interface MPAppErrorBeacon : MPBeacon

//
// Constants
//
typedef NS_ENUM(NSUInteger, MPAppErrorSourceEnum) {
  SOURCE_APP = 0,
  SOURCE_BOOMERANG = 1,
};

typedef NS_ENUM(NSUInteger, MPAppErrorViaEnum) {
  VIA_APP = 0,
  VIA_GLOBAL_EXCEPTION_HANDLER = 2,
  VIA_NETWORK = 3,
  VIA_CONSOLE = 4,
  VIA_EVENTHANDLER = 5,
  VIA_TIMEOUT = 6,
};

/**
 * Sends the beacon
 */
+(void) sendBeacon;

//
// Properties on the Protobuf beacon
//
/**
 * Crash count
 */
@property NSNumber *count;

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
@property NSString *functionName;

/**
 * Crash file
 */
@property NSString *fileName;

/**
 * Crash line
 */
@property NSNumber *lineNumber;

/**
 * Crash character
 */
@property NSNumber *columnNumber;

/**
 * Crash class namee
 */
@property NSString *className;

/**
 * Crash stack
 */
@property NSString *stack;

/**
 * Crash type
 */
@property NSString *type;

/**
 * Crash extra
 */
@property NSString *extra;

/**
 * Crash source
 */
@property MPAppErrorSourceEnum source;

/**
 * Crash source
 */
@property MPAppErrorViaEnum via;

//
// TODO: Events, Frames?
//

@end
