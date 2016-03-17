//
//  MPAppErrorBeacon.m
//  Boomerang
//
//  Copyright © 2015 SOASTA. All rights reserved.
//

#import "MPAppErrorBeacon.h"
#import "MPBeaconCollector.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPAppErrorBeacon

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
  MPAppErrorBeacon *beacon = [[MPAppErrorBeacon alloc] init];

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
  //  message AppErrorData {
  //    optional int32 count = 1;
  //    optional int64 timestamp = 2;
  //    optional int32 code = 3;
  //    optional string message = 4;
  //    optional string functionName = 5;
  //    optional string fileName = 6;
  //    optional int32 lineNumber = 7;
  //    optional int32 columnNumber = 8;
  //    optional string className = 9;
  //    optional string stack = 10;
  //    optional string type = 11;
  //    optional string extra = 12;
  //    optional AppErrorSourceType source = 13;
  //    optional AppErrorViaType via = 14;
  //    repeated AppEventData events = 15;
  //    repeated AppErrorFrameData frames = 16;
  //  }

  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  //
  // Crash data
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_AppErrorData* data
    = record->mutable_app_error_data();
  
  if (_count != nil && [_count intValue] > 1)
  {
    data->set_count([_count intValue]);
  }
  
  // timestamp - convert to milliseconds
  long msTimestamp = [[self timestamp] timeIntervalSince1970] * 1000;
  data->set_timestamp(msTimestamp);

  if (_code != nil)
  {
    data->set_code([_code intValue]);
  }

  if (_message != nil)
  {
    data->set_message([_message UTF8String]);
  }

  if (_functionName != nil)
  {
    data->set_functionname([_functionName UTF8String]);
  }

  if (_fileName != nil)
  {
    data->set_filename([_fileName UTF8String]);
  }

  if (_lineNumber != nil)
  {
    data->set_linenumber([_lineNumber intValue]);
  }

  if (_columnNumber != nil)
  {
    data->set_columnnumber([_columnNumber intValue]);
  }

  if (_className != nil)
  {
    data->set_classname([_className UTF8String]);
  }

  if (_stack != nil)
  {
    data->set_stack([_stack UTF8String]);
  }

  if (_type != nil)
  {
    data->set_type([_type UTF8String]);
  }

  if (_extra != nil)
  {
    data->set_extra([_extra UTF8String]);
  }

  data->set_source((::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_AppErrorSourceType)_source);
  data->set_via((::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_AppErrorViaType)_via);
}

@end
