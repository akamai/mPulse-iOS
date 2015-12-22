//
//  MPAppInactiveBeacon.h
//  Boomerang
//
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPAppInactiveBeacon : MPBeacon

/**
 * Sends the beacon
 */
+(void) sendBeacon;

@end
