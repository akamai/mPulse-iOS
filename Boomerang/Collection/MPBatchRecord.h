//
//  MPBatchRecord.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPBeacon.h"
#import "MPTimerData.h"

@interface MPBatchRecord : NSObject

+(id) initWithTimestamp:(int64_t)timestamp pageGroup:(NSString *)pageGroup abTest:(NSString*)abTest url:(NSString*)url networkErrorCode:(short)networkErrorCode;

@property (readonly) NSString* key;

@property (readonly) int64_t timestamp;
@property (readonly) NSString* pageGroup;
@property (readonly) NSString* abTest;
@property (readonly) NSString* url;
@property (readonly) short networkErrorCode;

@property (readonly) int totalBeacons;
@property (readonly) int totalCrashes;
@property (readonly) int totalInstalls;
@property (readonly) NSArray *customDimensions;

@property (readonly) MPTimerData* networkRequestTimer;
@property (readonly) MPTimerData* dnsTimer;
@property (readonly) MPTimerData* tcpHandshakeTimer;
@property (readonly) MPTimerData* sslHandshakeTimer;
@property (readonly) MPTimerData* timeToFirstByteTimer;
@property (readonly) MPTimerData* timeToLastByteTimer;

-(void) addBeacon:(MPBeacon*) beacon;

-(BOOL) hasCustomTimers;
-(NSArray*) customTimerArray;

-(BOOL) hasCustomMetrics;
-(NSArray*) customMetricArray;

@end
