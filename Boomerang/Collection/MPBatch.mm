//
//  MPBatch.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBatch.h"
#import "MPConfig.h"
#import "MPDemographics.h"
#import "MPSession.h"
#import "NSString+MPExtensions.h"
#import "MPulse.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPBatch
{
  /**
   * Beacons
   */
  NSArray* beacons;
}

//
// Constants
//
static NSString* MANUFACTURER = @"Apple";

//
// Methods
//

/**
 * Initializes the batch with the specified beacons
 * @param beacons Beacons
 */
+(id) initWithBeacons:(NSArray*)beacons
{
  MPBatch* batch = [[MPBatch alloc] init];
  
  if (batch != nil)
  {
    batch->beacons = beacons;
  }
  
  return batch;
}

/**
 * Serialize the batch to Protobuf
 */
-(NSData*) serialize
{
  client_beacon_batch::ClientBeaconBatch protobufBatch;

  // These should all come from config.
  MPConfig *config = [MPConfig sharedInstance];
  protobufBatch.set_boomerang_version([MPULSE_BUILD_VERSION_NUMBER UTF8String]);
  protobufBatch.set_api_key([[config APIKey] UTF8String]);

  MPDemographics* demographics = [MPDemographics sharedInstance];
  
  // These should all come from demographics.
  protobufBatch.set_manufacturer([MANUFACTURER UTF8String]);
  protobufBatch.set_device([[demographics getDeviceModel] UTF8String]);
  protobufBatch.set_type([[demographics getDeviceType] UTF8String]);
  protobufBatch.set_os([[demographics getOSVersion] UTF8String]);
  
  // Set ISP/Carrier Name only if its available
  NSString *carrierName = [demographics getCarrierName];
  if (carrierName != nil)
  {
    protobufBatch.set_isp([carrierName UTF8String]);
  }
  
  protobufBatch.set_connection_type([[demographics getConnectionType] UTF8String]);
    
  const char* siteVersion = [[demographics getApplicationVersion] UTF8String];
  if (siteVersion != nil)
  {
    protobufBatch.set_site_version(siteVersion);
  }
  
  // Only set latitude and longitude if the values are available
  float latitude = [demographics getLatitude];
  float longitude = [demographics getLongitude];
  if (latitude != 0 && longitude != 0)
  {
    protobufBatch.set_latitude(latitude);
    protobufBatch.set_longitude(longitude);
  }

  // add session info
  client_beacon_batch::ClientBeaconBatch_SessionInfo* protobufSession = [self serializeSession];
  protobufBatch.set_allocated_session(protobufSession);

  // add all of the raw beacons
  for (int i = 0; i < beacons.count; i++)
  {
    MPBeacon* beacon = [beacons objectAtIndex:i];

    ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* protobufRecord;

    // add a new record to Protobuf
    protobufRecord = protobufBatch.add_beacon_records();
    
    // have the beacon serialize itself
    [beacon serialize:protobufRecord];
  }

  // Serialize the batch object to binary (Protocol Buffers format).
  std::string serializedBytes = protobufBatch.SerializeAsString();

  NSMutableData* data = [NSMutableData dataWithBytes:serializedBytes.c_str() length:serializedBytes.size()];

  return data;
}

/**
 * Serialize session data
 */
-(::client_beacon_batch::ClientBeaconBatch_SessionInfo*) serializeSession
{
  MPSession* session = [MPSession sharedInstance];
  
  if (session.ID == nil || !session.started)
  {
    MPLogDebug(@"No session (ID: %@, started: %d)", session.ID, session.started);

    return NULL;
  }
  else
  {
    MPLogDebug(@"Serializing session (ID: %@, started: %d)", session.ID, session.started);

    ::client_beacon_batch::ClientBeaconBatch_SessionInfo* protobufSession = new ::client_beacon_batch::ClientBeaconBatch_SessionInfo();

    protobufSession->set_id([session.ID UTF8String]);
    protobufSession->set_start_time([session.startTime timeIntervalSince1970] * 1000);
    protobufSession->set_end_time([session.lastBeaconTime timeIntervalSince1970] * 1000);
    protobufSession->set_network_request_count_total(session.totalNetworkRequestCount);
    protobufSession->set_network_request_duration_total(session.totalNetworkRequestDuration);
  
    return protobufSession;
  }
}

@end
