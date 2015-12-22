//
//  MPBeaconCollector.m
//  Boomerang
//
//  Created by Tana Jackson on 4/9/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <dispatch/dispatch.h>

#import "MPBeaconCollector.h"
#import "MPBatchTransport.h"
#import "MPBeacon.h"
#import "MPConfig.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPSession.h"
#import "NSString+MPExtensions.h"

@implementation MPBeaconCollector
{
  /**
   * Dispatch queue
   */
  dispatch_queue_t _dispatchQueue;
  
  /**
   * Array of beacons
   */
  NSMutableArray *_beacons;
}

// Singleton BeaconCollector object
static MPBeaconCollector *sharedObject = nil;

/**
 * Singleton access
 */
+(MPBeaconCollector *) sharedInstance
{
  static dispatch_once_t _singletonPredicate;
  
  dispatch_once(&_singletonPredicate, ^{
    sharedObject = [[super allocWithZone:nil] init];
  });
  
  return sharedObject;
}

/**
 * Initializes the beacon collector
 */
-(id) init
{
  // Create the Grand Central Dispatch queue that will be used for all beacon processing.
  _dispatchQueue = dispatch_queue_create("com.soasta.mpulse.boomerang.MPBeaconCollector", NULL);
  
  // Create the internal array that will be used to store beacons
  _beacons = [[NSMutableArray alloc] init];
  
  // Create a scheduled task to flush all beacons on a regular basis (the first execution will re-schedule itself when finished).
  // NOTE: We cannot obtain the beaconInterval value from a MPConfig instance because calling sharedInstance
  // method of MPConfig inside the dispatch will cause a deadlock and hang the app.
  // Thats why we start the thread with a 5 second interval which will be updated using the config
  // during next iteration.
  _disableBatchSending = NO; // By default, we should be sending batch beacons to server.

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                 _dispatchQueue, ^{
                   [self sendBatch];
                 });
  
  return self;
}

/**
 * Adds a beacon to the collector
 * @param beacon Beacon
 */
-(void) addBeacon:(MPBeacon *)beacon
{
  // All beacon processing is done on a dedicated Grand Central Dispatch queue,
  // to avoid blocking the calling thread, and also to single-thread access to the
  // beacon array.
  //
  // Dispatch a task to do the "real" work.
  dispatch_async(_dispatchQueue, ^{
    [self addBeaconInternal:beacon];
  });
}

/**
 * Adds the beacon
 *
 * Implementation note: This method must not throw!  GCD will cause the app to crash.
 */
-(void) addBeaconInternal:(MPBeacon *)beacon
{
  @try
  {
    MPLogDebug(@"MPBeaconCollector: Adding beacon (type #%lu)", (unsigned long)[beacon getBeaconType]);
    
    // If we are cannot send beacons, return.
    if (![[MPConfig sharedInstance] beaconsEnabled])
    {
      MPLogDebug(@"Beacons are disabled; ignoring incoming %@.", [beacon class]);
      return;
    }
    
    // If this beacon has already been added to Collector, return. No need to add twice.
    if (beacon.addedToCollector)
    {
        return;
    }
    
    // Update Session data
    [[MPSession sharedInstance] addBeacon:beacon];
    
    // Add beacon to our list
    [_beacons addObject:beacon];
    
    // This beacon has been added to Collector, set the flag so that it's not added twice.
    [beacon setAddedToCollector:true];
  }
  @catch (NSException *e)
  {
    MPLogDebug(@"Failed to process incoming beacon. %@", e);
  }
}

/**
 * Sends the batch of beacons
 *
 * Implementation note: This method must not throw!  GCD will cause the app to crash.
 */
-(void) sendBatch
{
  // Do not try to send a batch if batch sending has been disabled.
  // This flag is only used by Unit Tests
  if (_disableBatchSending)
  {
    return;
  }
  
  MPLogDebug(@"MPBeaconCollector: Sending batch");
  
  @try
  {
    // determine if we actually have to do anything
    if ([_beacons count] == 0)
    {
      MPLogDebug(@"No beacons to send.");
    }
    else
    {
      // Swap the existing dictionary for a new one.
      NSArray *beacons = _beacons;
      _beacons = [[NSMutableArray alloc] init];

      // Send it!
      MPBatchTransport *transport = [[MPBatchTransport alloc] init];
      [transport sendBatch:beacons];
    }

    // Run again after n seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [[MPConfig sharedInstance] beaconInterval] * NSEC_PER_SEC),
                   _dispatchQueue, ^{
                     [self sendBatch];
                   });
  }
  @catch (NSException *e)
  {
    MPLogDebug(@"Failed to send batch. %@", e);
  }
}

/**
 * Clears the batch of beacons
 */
-(void) clearBatch
{
  MPLogDebug(@"MPBeaconCollector: Clearing batch");

  [_beacons removeAllObjects];
}

/**
 * Gets all of the collected beacons
 */
-(NSMutableArray *) getBeacons
{
  return _beacons;
}

@end
