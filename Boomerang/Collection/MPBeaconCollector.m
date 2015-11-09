//
//  MPBeaconCollector.m
//  Boomerang
//
//  Created by Tana Jackson on 4/9/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <dispatch/dispatch.h>

#import "MPBeaconCollector.h"
#import "MPBatchRecord.h"
#import "MPBatchTransport.h"
#import "MPBeacon.h"
#import "MPBeaconURLProcessor.h"
#import "MPConfig.h"
#import "MPNetworkCallBeacon.h"
#import "MPSession.h"
#import "NSString+MPExtensions.h"

@implementation MPBeaconCollector
{
  dispatch_queue_t _dispatchQueue;
  NSMutableDictionary* _records;
  //This flag is only used by Unit Tests
  BOOL _disableBatchSending;
}

// Singleton BeaconCollector object
static MPBeaconCollector *sharedObject = nil;

/**
 * Singleton access
 */
+(MPBeaconCollector*) sharedInstance
{
  static dispatch_once_t _singletonPredicate;
  
  dispatch_once(&_singletonPredicate, ^{
    sharedObject = [[super allocWithZone:nil] init];
  });
  
  return sharedObject;
}

-(id) init
{
  // Create the Grand Central Dispatch queue that will be used for all beacon processing.
  _dispatchQueue = dispatch_queue_create("com.soasta.mpulse.boomerang.MPBeaconCollector", NULL);
  
  // Create the internal dictionary that will be used to store aggregated records.
  _records = [[NSMutableDictionary alloc] init];
  
  // Create a scheduled task to flush all records on a regular basis (the first execution will re-schedule itself when finished).
  // NOTE: We cannot obtain the beaconInterval value from a MPConfig instance because calling sharedInstance
  // method of MPConfig inside the dispatch will cause a deadlock and hang the app.
  // Thats why we start the thread with a 5 second interval which will be updated using the config
  // during next iteration.
  _disableBatchSending = NO; // By default, we should be sending batch records to server.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                 _dispatchQueue, ^{ [self sendBatch]; });
  
  return self;
}

-(void) addBeacon:(MPBeacon*)beacon
{
  // All beacon processing is done on a dedicated Grand Central Dispatch queue,
  // to avoid blocking the calling thread, and also to single-thread access to the
  // record dictionary.
  //
  // Dispatch a task to do the "real" work.
  dispatch_async(_dispatchQueue, ^{
    [self addBeaconInternal:beacon ]; });
}

// Impl note:  this method must not throw!  GCD will cause the app to crash.
-(void) addBeaconInternal:(MPBeacon*)beacon
{
  @try
  {
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
    
    // Convert NSDate to Unix timestamp (in milliseconds).
    int64_t timestamp = (int64_t)[beacon.timestamp timeIntervalSince1970] * 1000;
    
    // Round to the nearest minute.
    timestamp = timestamp - (timestamp % 60000);

    // Extract the URL, if any, from this beacon (including
    // processing it via URL patterns in the config).
    NSString* url = [MPBeaconURLProcessor extractURL:beacon urlPatterns:[MPConfig sharedInstance].urlPatterns];

    // Create the "stub" record for this timestamp, A/B test, etc.
    // We may or may not actually use this (see below).
    MPBatchRecord* record = [MPBatchRecord initWithTimestamp:timestamp
                                                   pageGroup:beacon.pageGroup
                                                      abTest:beacon.abTest
                                                         url:url
                                            networkErrorCode:beacon.networkErrorCode];
    
    // Check for a previously-existing record.
    MPBatchRecord* prevRecord = [_records objectForKey:record.key];
    if (prevRecord == nil)
    {
      // There's no previously-existing record
      // for this key combination.  The "stub"
      // will become the real record.
      MPLogDebug(@"Record key %@ being used for the first time.", record.key);
      [_records setObject:record forKey:record.key];
    }
    else
    {
      // There's already a record for this key combination.
      // We'll use that instead.
      MPLogDebug(@"Updating existing record with key %@", record.key);
      record = prevRecord;
    }
    
    // Let the record itself do the "real" beacon processing.
    [record addBeacon:beacon];
    
    // This beacon has been added to Collector, set the flag so that it's not added twice.
    [beacon setAddedToCollector:true];
  }
  @catch (NSException* e)
  {
    // TODO: ??
    MPLogDebug(@"Failed to process incoming beacon. %@", e);
  }
}

// Impl note:  this method must not throw!  GCD will cause the app to crash.
-(void) sendBatch
{
  // Do not try to send a batch if batch sending has been disabled.
  //This flag is only used by Unit Tests
  if (_disableBatchSending)
  {
    return;
  }
  
  @try
  {
    if ([_records count] == 0)
    {
      MPLogDebug(@"No records to send.");
    }
    else
    {
      // Swap the existing dictionary for a new one.
      NSDictionary* batchedRecords = _records;
      _records = [[NSMutableDictionary alloc] init];

      // Send it!
      MPBatchTransport* transport = [[MPBatchTransport alloc] init];
      [transport sendBatch:batchedRecords];
    }

    // Run again after n seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [[MPConfig sharedInstance] beaconInterval] * NSEC_PER_SEC),
                   _dispatchQueue, ^{ [self sendBatch]; });
  }
  @catch (NSException* e)
  {
    // TODO: ??
    MPLogDebug(@"Failed to send batch. %@", e);
  }
}

-(void) clearBatch
{
    [_records removeAllObjects];
}

@end
