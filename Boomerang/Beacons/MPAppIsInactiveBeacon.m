//
//  MPAppIsInactiveBeacon.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPAppIsInactiveBeacon.h"
#import "MPBeaconCollector.h"

@implementation MPAppIsInactiveBeacon

-(id) init
{
  self = [super init];
  if (self)
  {
    // We overwrite the PageGroup value for AppIsInactiveBeacon as it is a standalone beacon
    // and cannot belong to any page group in the app.
    self.pageGroup = @"";
  }
  return self;
}

+(void) sendBeacon
{
  MPAppIsInactiveBeacon *beacon = [[MPAppIsInactiveBeacon alloc] init];
  [[MPBeaconCollector sharedInstance] addBeacon:beacon];
  
  // Flush and send all beacons as the app is going into background or terminating.
  [[MPBeaconCollector sharedInstance] sendBatch];
}

@end
