//
//  MPApiCustomTimerBeacon.h
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPApiCustomTimerBeacon : MPBeacon

//
// Methods
//
/**
 * Initialize a timer with the specified name and start timing
 * @param timerName Timer name
 */
-(id) initAndStart:(NSString *)timerName;

/**
 * Initialize a timer with the specified index
 * @param timerIndex Timer index
 */
-(id) initWithIndex:(NSInteger)timerIndex;

/**
 * Initialize a timer with the specified name and value
 * @param timerName Timer name
 * @param value Value
 */
-(id) initWithName:(NSString *)timerName andValue:(NSTimeInterval)value;

/**
 * Starts a timer beacon
 */
-(void) startTimer;

/**
 * Ends the timer and sends the beacon
 */
-(void) endTimer;

//
// Properties
//
/**
 * Timer name
 */
@property (readwrite) NSString *timerName;

/*
 * Whether or not the timer has started
 */
@property (readonly) BOOL hasTimerStarted;

/**
 * Whether or not the timer has ended
 */
@property (readonly) BOOL hasTimerEnded;

//
// Properties on the Protobuf beacon
//
/**
 * Timer index
 */
@property NSInteger timerIndex;

/**
 * Timer value
 */
@property NSTimeInterval timerValue;

@end
