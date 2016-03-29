//
//  MPBeacon.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPBeacon.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPBeacon

/**
 * Initializes the beacon
 */
-(id) init
{
  self = [super init];

  if (self)
  {
    // set the timestamp to now
    _timestamp = [NSDate date];
    
    // grab a copy of page groups as of right now
    _pageGroup = [[MPulse sharedInstance] getViewGroup];
    
    // grab a copy of the A/B test as of right now
    _abTest = [[MPulse sharedInstance] getABTest];
    
    // grab a copy of dimensions as of right now
    _customDimensions = [[[MPulse sharedInstance] customDimensions] copy];
    
    // we havne't send the beacon yet
    _addedToCollector = false;
  }
  
  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return BATCH;
}

/**
 * Serializes the beacon for the Protobuf record
 */
-(void) serialize:(void *)recordPtr
{
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  // timestamp - convert to milliseconds
  int64_t msTimestamp = [_timestamp timeIntervalSince1970] * 1000;
  record->set_timestamp(msTimestamp);
  
  // beacon type
  record->set_beacon_type((::client_beacon_batch::ClientBeaconBatch_BeaconType)[self getBeaconType]);
  
  // A/B test
  if (_abTest != nil && _abTest.length != 0)
  {
    record->set_ab_test([_abTest UTF8String]);
  }
  
  // Page Group
  if (_pageGroup != nil && _pageGroup.length != 0)
  {
    record->set_page_group([_pageGroup UTF8String]);
  }
  
  // Custom Dimensions
  if (_customDimensions != nil)
  {
    NSArray *customDimensions = _customDimensions;
    for (int d = 0; d < 10; d++)
    {
      NSString *dimensionValue = @"";
      if ([customDimensions objectAtIndex:d] != nil)
      {
        dimensionValue = [customDimensions objectAtIndex:d];
      }
      
      record->add_custom_dimensions([dimensionValue UTF8String]);
    }
  }

}

/**
 * Clears page dimensions such as A/B test, Page Group and Custom Dimensions
 */
-(void) clearPageDimensions
{
  _pageGroup = @"";
  _abTest = @"";
  _customDimensions = nil;
}

@end
