//
//  MPApiCustomTimerBeacon.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import "MPApiCustomTimerBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPApiCustomTimerBeacon
{
  /**
   * Start time
   */
  NSDate *_startTime;
}

//
// Methods
//
/**
 * Initialize a timer with the specified name and start timing
 * @param timerName Timer name
 */
-(id) initAndStart:(NSString *)timerName
{
  self = [super init];

  if (self)
  {
    _timerIndex = -1;
    _timerName = timerName;
    
    for (MPConfigTimer *timer in [[[MPConfig sharedInstance] pageParamsConfig] timers])
    {
      if ([timer.name isEqualToString:timerName])
      {
        _timerIndex = timer.index;

        [self startTimer];

        break;
      }
    }
  }

  return self;
}

/**
 * Initialize a timer with the specified index
 * @param timerIndex Timer index
 */
-(id) initWithIndex:(NSInteger)timerIndex
{
  self = [super init];
  
  if (self)
  {
    _timerIndex = timerIndex;
  }
  
  return self;
}

/**
 * Initialize a timer with the specified name and value
 * @param timerName Timer name
 * @param value Value
 */
-(id) initWithName:(NSString *)timerName andValue:(NSTimeInterval)value
{
  self = [super init];

  if (self)
  {
    _timerIndex = -1;
    _timerName = timerName;

    for (MPConfigTimer *timer in [[[MPConfig sharedInstance] pageParamsConfig] timers])
    {
      if ([timer.name isEqualToString:timerName])
      {
        _timerIndex = timer.index;
        _timerValue = value * 1000;

        _hasTimerStarted = YES;
        _hasTimerEnded = YES;

        MPLogDebug(@"Initialized timer beacon: index=%d, value=%f", (int)_timerIndex, _timerValue);

        // Send the timer beacon
        [[MPBeaconCollector sharedInstance] addBeacon:self];

        break;
      }
    }
  }

  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return API_CUSTOM_TIMER;
}

/**
 * Serializes the beacon for the Protobuf record
 */
-(void) serialize:(void *)recordPtr
{
  //
  //  message ApiCustomTimerData {
  //    // timer duration (ms)
  //    optional int32 timer_value = 1;
  //    
  //    // custom timer index
  //    optional int32 timer_index = 2;
  //  }
  //

  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
  = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;

  //
  // Api Custom Timer data
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiCustomTimerData* data
    = record->mutable_api_custom_timer_data();
  
  // metric index
  data->set_timer_index((int)_timerIndex);
  
  // metric index
  data->set_timer_value(_timerValue);
}

/**
 * Starts a timer beacon
 */
-(void) startTimer
{
  _startTime = [NSDate date];
  _hasTimerStarted = YES;
  
  // reset duration and ended flag
  _timerValue = 0;
  _hasTimerEnded = NO;
}

/**
 * Ends the timer and sends the beacon
 */
-(void) endTimer
{
  // convert to milliseconds
  _timerValue = [[NSDate date] timeIntervalSinceDate:_startTime] * 1000;
  _hasTimerEnded = YES;
  
  MPLogDebug(@"Initialized timer beacon: index=%d, value=%f", (int)_timerIndex, _timerValue);

  if (_timerIndex != -1)
  {
    [[MPBeaconCollector sharedInstance] addBeacon:self];    
  }
}

@end
