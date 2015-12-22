//
//  MPApiNetworkRequestBeacon.m
//  Boomerang
//
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPApiNetworkRequestBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "ClientBeaconBatch.pb.h"
#import "MPSession.h"

@implementation MPApiNetworkRequestBeacon
{
  /**
   * End time
   */
  NSDate *_endTime;
  
  /**
   * Content size
   */
  NSUInteger _contentSize;
}

//
// Methods
//

/**
 * Initializes a network request with the specified URL
 * @param url URL
 */
+(id) initWithURL:(NSURL *)url
{
  MPApiNetworkRequestBeacon *beacon = [[MPApiNetworkRequestBeacon alloc] init];

  if (beacon)
  {
    // determine if we need to strip the QueryString
    if ([MPConfig sharedInstance].stripQueryStrings)
    {
      // keep everything but the query string
      url = [[NSURL alloc] initWithScheme:[url scheme]
                                     host:[url host]
                                     path:[url path]];
    }
    
    // absolutize and escape
    beacon.url = [[url absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    beacon.networkErrorCode = 0;
    beacon.errorMessage = @"";

    // save the session ID so we know if it's reset later
    beacon.sessionToken = [MPSession sharedInstance].token;
    
    MPLogDebug(@"Initialized network beacon: %@ for session token %d", beacon, beacon.sessionToken);
  }

  return beacon;
}

/**
 * Ends a successful network request
 * @param bytes Bytes recieved
 */
-(void) endRequestWithBytes:(NSUInteger)bytes
{
  _endTime = [NSDate date];

  _contentSize = bytes;

  // convert duration to milliseconds
  NSTimeInterval dur = [_endTime timeIntervalSinceDate:self.timestamp];
  _duration = dur * 1000;

  if (_sessionToken != [MPSession sharedInstance].token)
  {
    MPLogDebug(@"Skipping \"success\" network beacon (old session token %d): %@", _sessionToken, _url);
    return;
  }

  MPLogDebug(@"Adding \"success\" network beacon to BatchRecord: [URL=%@, contentSize=%lu, requestDuration=%d]",
             _url,
             (unsigned long)_contentSize,
             _duration);

  [[MPBeaconCollector sharedInstance] addBeacon:self];
}

/**
 * Ends an unsuccessful network request with an error
 * @param error Error code
 * @param errorMessage Error message
 */
-(void) setNetworkError:(NSInteger)errorCode errorMessage:(NSString *)errorMessage
{
  _endTime = [NSDate date];

  _networkErrorCode = errorCode;
  _errorMessage = errorMessage;
  
  // convert duration to milliseconds
  NSTimeInterval dur = [_endTime timeIntervalSinceDate:self.timestamp];
  _duration = dur * 1000;
  
  if (_sessionToken != [MPSession sharedInstance].token)
  {
    MPLogDebug(@"Skipping \"failure\" network beacon (old session token %d): %@", _sessionToken, _url);
    return;
  }

  MPLogDebug(@"Adding \"failure\" network beacon to BatchRecord: [URL=%@, networkErrorCode=%d, errorMessage=%@]",
             _url,
             _networkErrorCode,
             _errorMessage);
  
  [[MPBeaconCollector sharedInstance] addBeacon:self];
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return API_NETWORK_REQUEST;
}

/**
 * Serializes the beacon for the Protobuf record
 */
-(void) serialize:(void*)recordPtr
{
  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  //
  // Api Network Request data
  //
  //  message ApiNetworkRequestData {
  //    // request duration (ms)
  //    optional int32 duration = 1;
  //    
  //    // request URL
  //    optional string url = 2;
  //    
  //    // network error code
  //    optional int32 network_error_code = 3;
  //    
  //    // request duration breakdowns (ms)
  //    optional int32 dns = 4;
  //    optional int32 tcp = 5;
  //    optional int32 ssl = 6;
  //    optional int32 ttfb = 7;
  //  }
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiNetworkRequestData* data
    = record->mutable_api_network_request_data();
  
  // duration
  data->set_duration(_duration);
  
  // URL
  if (_url != nil)
  {
    data->set_url([_url UTF8String]);
  }

  // network error code
  if (_networkErrorCode != 0)
  {
    data->set_network_error_code(_networkErrorCode);
  }
  
  // optional network timings
  if (_dns != 0)
  {
    data->set_dns(_dns);
  }

  if (_tcp != 0)
  {
    data->set_tcp(_tcp);
  }

  if (_ssl != 0)
  {
    data->set_ssl(_ssl);
  }

  if (_ttfb != 0)
  {
    data->set_ttfb(_ttfb);
  }
}

/**
 * Gets the beacon's description
 */
- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPApiNetworkRequestBeacon: URL=%@", _url];
}

@end
