//
//  MPSession.h
//  Boomerang
//
//  Created by Mukul Sharma on 4/24/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

/*
 * Singleton class to represent the mPulse session.
 */

@interface MPSession : NSObject

+(MPSession *) sharedInstance;
-(void) addBeacon:(MPBeacon*) beacon;
-(void) reset;

@property (readonly) int totalNetworkRequestDuration;
@property (readonly) int totalNetworkRequestCount;
@property (readonly) NSString* ID;
@property (readonly) NSDate* startTime;
@property (readonly) NSDate* lastBeaconTime;
@property (readonly) BOOL started;
@property (readonly) int token;

@end
