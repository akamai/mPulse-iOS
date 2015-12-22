//
//  MPAppLaunchBeacon.h
//  Boomerang
//
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPAppLaunchBeacon : MPBeacon

//
// Methods
//
/**
 * Sends the beacon
 */
+(void) sendBeacon;

//
// Properties on the Protobuf beacon
//
/**
 * Whether this launch is for the first install
 */
@property bool isFirstInstall;

@end
