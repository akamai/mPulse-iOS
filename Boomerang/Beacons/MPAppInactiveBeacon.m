//
//  MPAppInactiveBeacon.m
//  Boomerang
//
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPAppInactiveBeacon.h"
#import "MPBeaconCollector.h"

@implementation MPAppInactiveBeacon

/**
 * Intializes the inactive beacon
 */
-(id) init
{
  self = [super init];

  if (self)
  {
    // Clear Page Dimensions as an inactive isn't associated with a page
    [self clearPageDimensions];
  }

  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return APP_INACTIVE;
}

/**
 * Sends the beacon
 */
+(void) sendBeacon
{
  MPAppInactiveBeacon *beacon = [[MPAppInactiveBeacon alloc] init];

  [[MPBeaconCollector sharedInstance] addBeacon:beacon];
  
  // Flush and send all beacons as the app is going into background or terminating.
  [[MPBeaconCollector sharedInstance] sendBatch];
}

@end
