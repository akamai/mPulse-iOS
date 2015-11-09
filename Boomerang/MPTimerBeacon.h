//
//  MPTimerBeacon.h
//  Boomerang
//
//  Created by Tana Jackson on 4/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPTimerBeacon : MPBeacon

@property (readonly) BOOL hasTimerStarted;
@property (readonly) BOOL hasTimerEnded;

-(id) initWithStart:(NSString *)timerName;
-(id) initWithIndex:(NSInteger)timerIndex;
-(id) initWithTimerName:(NSString *)timerName andValue:(NSTimeInterval)value;

@property (readwrite) NSString* timerName;
@property (readonly) NSTimeInterval elapsed;

-(void) startTimer;
-(void) endTimer;

@end
