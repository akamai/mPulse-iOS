//
//  MPAppCrashBeacon.m
//  Boomerang
//
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import "MPAppCrashBeacon.h"
#import "MPBeaconCollector.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPAppCrashBeacon

/**
 * Initialize a crash beacon
 */
-(id) init
{
  self = [super init];
  
  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return APP_CRASH;
}

/**
 * Sends the beacon
 */
+(void) sendBeacon
{
  // create a beacon
  MPAppCrashBeacon *beacon = [[MPAppCrashBeacon alloc] init];

  // add it to the batch
  [[MPBeaconCollector sharedInstance] addBeacon:beacon];
  
  // Flush and send all beacons as the app has crashed
  [[MPBeaconCollector sharedInstance] sendBatch];
}

/**
 * Serializes the beacon for the Protobuf record
 */
-(void) serialize:(void*)recordPtr
{
  //
  //  message AppCrashData {
  //    optional int32 code = 1;
  //    optional string message = 2;
  //    optional string function = 3;
  //    optional string file = 4;
  //    optional int32 line = 5;
  //    optional int32 character = 6;
  //    optional string stack = 7;
  //  }
  //

  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  //
  // Crash data
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_AppCrashData* data
    = record->mutable_app_crash_data();
  
  if (_code != nil)
  {
    data->set_code([_code intValue]);
  }

  if (_message != nil)
  {
    data->set_message([_message UTF8String]);
  }
  
  if (_function != nil)
  {
    data->set_function([_function UTF8String]);
  }
  
  if (_file != nil)
  {
    data->set_file([_file UTF8String]);
  }
  
  if (_line != nil)
  {
    data->set_line([_line intValue]);
  }
  
  if (_character != nil)
  {
    data->set_character([_character intValue]);
  }
  
  if (_stack != nil)
  {
    data->set_stack([_stack UTF8String]);
  }
}

@end
