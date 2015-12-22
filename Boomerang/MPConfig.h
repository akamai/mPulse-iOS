//
//  MPConfig.h
//  Boomerang
//
//  Created by Mukul Sharma on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPTouchConfig.h"

/*
 * Singleton class to represent the mPulse configuration file and data available in the file.
 * This file is downloaded from the mPulse server whose URL is available in Boomerang.plist file.
 */
 
@interface MPConfig : NSObject

extern NSString* const BOOMERANG_CONFIG_REFRESHED;
extern NSString* const CONFIG_GET_REQUEST_COMPLETE;
extern NSString* const BOOMERANG_PLIST;
extern NSString* const SESSION_ID_KEY;

+(MPConfig *) sharedInstance;

@property (readwrite) BOOL userEnabledBeacons;
@property (readwrite) NSString* APIKey;
@property (readwrite) NSURL* mPulseServerURL;
@property (readonly) NSURL* configURL;
@property (readonly) NSURL* beaconURL;
@property (readwrite) BOOL generateNetworkErrors;
@property (readwrite) BOOL isHUDEnabled;
@property (readwrite) NSString* HUDColor;
@property (readwrite) NSTimeInterval HUDDisplayDuration;
@property (readonly) NSArray* urlPatterns;
@property (readonly) NSTimeInterval beaconInterval;
@property (readonly) NSTimeInterval sessionExpirationTime;
@property (readwrite) BOOL refreshDisabled;
@property (readonly) BOOL stripQueryStrings;

@property (readonly) MPTouchConfig* touchConfig;

-(BOOL) beaconsEnabled;

-(void)initWithResponse:(NSString *)responseBody;

-(void) buildConfigRequestURL;

-(void) refresh;

@end
