//
//  MPBeacon.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPBeacon : NSObject

@property(readonly) NSDate* timestamp;
@property BOOL isFirstInstall;
@property BOOL addedToCollector;
@property NSString* pageGroup;
@property NSString* abTest;
@property NSString* url;
@property short networkErrorCode;
@property NSString* errorMessage;
@property NSTimeInterval requestDuration;

@property NSInteger metricIndex;
@property int32_t metricValue;

@property NSInteger timerIndex;
@property NSTimeInterval timerValue;

-(id) init;

@end
