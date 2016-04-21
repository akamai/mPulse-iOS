//
//  MPBatchTests.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/26/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MPBatch.h"
#import "MPBeacon.h"
#import "MPApiCustomMetricBeacon.h"
#import "MPApiCustomTimerBeacon.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPBeaconTestBase.h"
#import "ClientBeaconBatch.pb.h"
#import "MPConfig.h"
#import "MPDemographics.h"

@interface MPBatchTests : MPBeaconTestBase

@end

@implementation MPBatchTests
{
  MPBatch *_batch;
}

-(void) setUp
{
  [super setUp];
  //
  // Create a timer, metric and network request beacons
  //
  MPApiCustomMetricBeacon *metricBeacon = [[MPApiCustomMetricBeacon alloc] initWithMetricName:@"Metric1" andValue:@1];
  
  MPApiCustomTimerBeacon *timerBeacon = [[MPApiCustomTimerBeacon alloc] initWithName:@"Code Timer" andValue:1.0f];
  
  NSURL *url = [[NSURL alloc] initWithString:@"http://foo.com"];
  MPApiNetworkRequestBeacon *networkBeacon = [MPApiNetworkRequestBeacon initWithURL:url];
  [networkBeacon endRequestWithBytes:1];
  
  //
  // Create a batch
  //
  _batch = [MPBatch initWithBeacons:@[metricBeacon, timerBeacon, networkBeacon]];
}

-(void) testSerialize
{
  NSData *data = [_batch serialize];

  // The output depends on where it's being run.  It should be at least 259 bytes, but less than 300.
  // It's generally around 271 bytes on the server.
  XCTAssertTrue([data length] >= 259);
  XCTAssertTrue([data length] <= 300);
}

-(void) testProtobuf
{
  MPConfig *config = [MPConfig sharedInstance];
  NSData *data = [_batch serialize];
  
  // convert data back to a std::string, which Protobuf uses
  const char *bytes = (const char *)[data bytes];
  std::string dataString = std::string(bytes, [data length]);
  
  // have Protobuf parse the std::string
  client_beacon_batch::ClientBeaconBatch protobufBatch;
  protobufBatch.ParseFromString(dataString);
  
  MPDemographics* demographics = [MPDemographics sharedInstance];
  
  //
  // Test some expected fields of the Protobuf
  //
  XCTAssertEqual(protobufBatch.api_key(), [config.APIKey UTF8String]);
  XCTAssertEqual(protobufBatch.device(), [[demographics getDeviceModel] UTF8String]);
  XCTAssertEqual(protobufBatch.manufacturer(), [@"Apple" UTF8String]);
  XCTAssertEqual(protobufBatch.type(), [[demographics getDeviceType] UTF8String]);
  XCTAssertEqual(protobufBatch.os(), [[demographics getOSVersion] UTF8String]);
  
  // peek at the session
  const ::client_beacon_batch::ClientBeaconBatch_SessionInfo protobufSession = protobufBatch.session();
  XCTAssertTrue(protobufSession.has_id());
  
  // ensure we have 3 records
  XCTAssertEqual(3, protobufBatch.beacon_records_size());
  
  // Custom Metric Beacon
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord record = protobufBatch.beacon_records(0);
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiCustomMetricData metricData
    = record.api_custom_metric_data();
  XCTAssertEqual(1, metricData.metric_value());
  XCTAssertEqual(0, metricData.metric_index());
  
  // Custom Timer Beacon
  record = protobufBatch.beacon_records(1);
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiCustomTimerData timerData
    = record.api_custom_timer_data();
  XCTAssertEqual(1000, timerData.timer_value());
  XCTAssertEqual(1, timerData.timer_index());
  
  // Network Beacon
  record = protobufBatch.beacon_records(2);
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiNetworkRequestData networkData
    = record.api_network_request_data();
  XCTAssertEqual([@"http://foo.com" UTF8String], networkData.url());
}

@end
