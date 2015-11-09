//
//  MPTimerBeacon.m
//  Boomerang
//
//  Created by Tana Jackson on 4/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTimerBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"

@implementation MPTimerBeacon
{
  NSDate *_startTime;
}

-(id) initWithStart:(NSString *)timerName
{
  self = [super init];
  if (self)
  {
    for (MPTouchTimer *timer in [[[MPConfig sharedInstance] touchConfig] timers])
    {
      if ([timer.name isEqualToString:timerName])
      {
        self.timerIndex = timer.index;
        [self startTimer];
        break;
      }
    }
  }
  return self;
}

-(id) initWithTimerName:(NSString *)timerName andValue:(NSTimeInterval)value
{
  self = [super init];
  if (self)
  {
    for (MPTouchTimer *timer in [[[MPConfig sharedInstance] touchConfig] timers])
    {
      if ([timer.name isEqualToString:timerName])
      {
        self.timerIndex = timer.index;
        self.timerValue = value;
        _hasTimerStarted = YES;
        _hasTimerEnded = YES;
        
        // Send the timer beacon
        [[MPBeaconCollector sharedInstance] addBeacon:self];
        break;
      }
    }
  }
  return self;
}

-(id) initWithIndex:(NSInteger)timerIndex
{
  self = [super init];
  if (self)
  {
    self.timerIndex = timerIndex;
  }
  return self;
}

-(void) startTimer
{
  _startTime = [NSDate date];
  _hasTimerStarted = YES;
}

-(void) endTimer
{
  self.timerValue = [[NSDate date] timeIntervalSinceDate:_startTime];
  _hasTimerEnded = YES;
  
  [[MPBeaconCollector sharedInstance] addBeacon:self];
}

@end
