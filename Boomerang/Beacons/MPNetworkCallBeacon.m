//
//  MPNetworkCallBeacon.m
//  Boomerang
//
//  Created by Tana Jackson on 4/8/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPNetworkCallBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"

@implementation MPNetworkCallBeacon
{
  NSDate *_endTime;
  NSUInteger _contentSize;
}


// TODO: Values being put in the histogram must always be 32 bit.

// Java classes for reference -
//RumBucketUtilityBelt
//RumHistogramUserType

+(id) initWithURL:(NSURL *)url
{
  MPNetworkCallBeacon *beacon = [[MPNetworkCallBeacon alloc] init];

  if (beacon)
  {
    beacon.url = [[url absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    beacon.networkErrorCode = 0;
    beacon.errorMessage = @"";

    // save the session ID so we know if it's reset later
    beacon.sessionToken = [MPSession sharedInstance].token;

    MPLogDebug(@"Initialized network beacon: %@", beacon);
  }

  return beacon;
}

-(void) endRequestWithBytes:(NSUInteger)bytes
{
  _endTime = [NSDate date];
  _contentSize = bytes;

  self.requestDuration = [_endTime timeIntervalSinceDate:self.timestamp];

  if (_sessionToken != [MPSession sharedInstance].token)
  {
    MPLogDebug(@"Skipping \"success\" network beacon (old session token %d)", _sessionToken);
    return;
  }

  MPLogDebug(@"Adding \"success\" network beacon to BatchRecord: [URL=%@, contentSize=%lu, requestDuration=%f]", self.url, (unsigned long)_contentSize, self.requestDuration);

  [[MPBeaconCollector sharedInstance] addBeacon:self];
}

-(void) setNetworkError:(NSInteger)errorCode :(NSString *)errorMessage
{
  _endTime = [NSDate date];
  self.networkErrorCode = errorCode;
  self.errorMessage = errorMessage;

  self.requestDuration = [_endTime timeIntervalSinceDate:self.timestamp];

  if (_sessionToken != [MPSession sharedInstance].token)
  {
    MPLogDebug(@"Skipping \"success\" network beacon (old session token %d)", _sessionToken);
    return;
  }

  MPLogDebug(@"Adding \"failure\" network beacon to BatchRecord: [URL=%@, networkErrorCode=%d, errorMessage=%@]", self.url, self.networkErrorCode, self.errorMessage);

  [[MPBeaconCollector sharedInstance] addBeacon:self];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[NetworkCallBeacon: URL=%@", self.url];
}

@end
