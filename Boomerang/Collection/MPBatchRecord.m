//
//  MPBatchRecord.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBatchRecord.h"
#import "MPBucketUtility.h"
#import "MPTimerData.h"
#import "MPNumberDictionary.h"
#import "MPulse.h"
#import "MPulsePrivate.h"

@implementation MPBatchRecord
{
  MPNumberDictionary* _customMetrics;

  NSMutableDictionary* _customTimers;
  NSUInteger _maxCustomTimerIndex;
}

+(id) initWithTimestamp:(int64_t)timestamp pageGroup:(NSString *)pageGroup abTest:(NSString*)abTest url:(NSString*)url networkErrorCode:(short)networkErrorCode
{
  MPBatchRecord *record = [[MPBatchRecord alloc] init];

  if (record)
  {
    record->_timestamp = timestamp;
    record->_pageGroup = pageGroup;
    record->_abTest = abTest;
    record->_url = url;
    record->_networkErrorCode = networkErrorCode;    
    record->_customDimensions = [[MPulse sharedInstance] customDimensions];

    [record generateKey];
  }

  return record;
}

-(void) generateKey
{
  _key = [NSString stringWithFormat:@"%lld:%@:%@:%@:%hd", _timestamp, _pageGroup, _abTest, _url, _networkErrorCode];
}

-(void) addBeacon:(MPBeacon*) beacon
{
  // Increment the total # of beacons no matter what.
  _totalBeacons++;

  // Does this beacon represent the initial installation of the app?
  if (beacon.isFirstInstall)
  {
    // This beacon represents the initial installation.

    // Increment the total # of installs.
    _totalInstalls++;
  }

  // Does this beacon represent a network request?
  if (beacon.requestDuration > 0)
  {
    // This beacon represents a network request.

    // Create the network TimerData object, if we don't already have one.
    if (_networkRequestTimer == nil)
    {
      _networkRequestTimer = [[MPTimerData alloc] init];
    }

    // Update the network timer data.
    [_networkRequestTimer addBeacon:beacon.requestDuration];
    MPLogDebug(@"New timer data: %@", _networkRequestTimer);
  }

  // Does this beacon represent a custom timer?
  if (beacon.timerValue > 0)
  {
    // This beacon represents a custom timer.
    
    // Create the custom metric dictionary, if we don't already have one.
    if (_customTimers == nil)
    {
      _customTimers = [NSMutableDictionary dictionary];
    }

    // Convert the index to a dictionary key (must be an object, not a primitive).
    NSNumber* timerKey = @(beacon.timerIndex);

    // Get the associated TimerData object, or create it if we don't already have one.
    MPTimerData* customTimer = [_customTimers objectForKey:timerKey];
    if (customTimer == nil)
    {
      customTimer = [[MPTimerData alloc] init];
      [_customTimers setObject:customTimer forKey:timerKey];
    }
    
    // Update the custom timer data.
    [customTimer addBeacon:beacon.timerValue];
    MPLogDebug(@"New timer data: %@", customTimer);
    
    // If this index is higher than the previous max, then update it.
    if (beacon.timerIndex > _maxCustomTimerIndex)
    {
      _maxCustomTimerIndex = beacon.timerIndex;
    }
  }

  // Does this beacon represent a custom metric?
  if (beacon.metricValue > 0)
  {
    // This beacon represents a custom metric.
    
    // Create the custom metric dictionary, if we don't already have one.
    if (_customMetrics == nil)
    {
      _customMetrics = [[MPNumberDictionary alloc] init];
    }
    
    [_customMetrics incrementBucket:beacon.metricIndex value:beacon.metricValue];
  }
}

-(BOOL) hasCustomTimers
{
  return _customTimers.count > 0;
}

-(NSArray*) customTimerArray
{
  // Do we have any values?
  if (![self hasCustomTimers])
  {
    // We don't have any values.
    
    // No point in allocating any memory.
    return nil;
  }
  else
  {
    // We have at least one value.

    // Create an array, pre-sized to the number of elements we'll need.
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:(_maxCustomTimerIndex + 1)];

    for (int i = 0; i <= _maxCustomTimerIndex; i++)
    {
      // Ideally we would only occupy a slot in the array for the actual timer values,
      // leaving the rest set to nil.  Unfortunately, NSArray does not allow this.
      //
      // Instead, we fabricate an "empty" MPTimerData object for any array positions
      // that don't correspond to an actual timer value.

      // Convert the index to a dictionary key (must be an object, not a primitive).
      NSNumber* timerKey = @(i);
      
      // Get the TimerData object for this index, if present.
      MPTimerData* customTimer = [_customTimers objectForKey:timerKey];

      // Is there a timer for this index?
      if (customTimer == nil)
      {
        // There is no timer.
        
        // We have to put *something* in the array (nil is not allowed), so create
        // an empty MPTimerData object.
        customTimer = [[MPTimerData alloc] init];
      }

      [array addObject:customTimer];
    }
    
    return array;
  }
}

-(BOOL) hasCustomMetrics
{
  return _customMetrics.count > 0;
}

-(NSArray*) customMetricArray
{
  return [_customMetrics asNSArray];
}

@end
