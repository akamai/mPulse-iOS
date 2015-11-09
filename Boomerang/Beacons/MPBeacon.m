//
//  MPBeacon.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBeacon.h"
#import "MPulse.h"

@implementation MPBeacon

-(id) init
{
  self = [super init];
  if (self)
  {
    _timestamp = [NSDate date];
    _addedToCollector = false;
    _pageGroup = [[MPulse sharedInstance] getViewGroup];
  }
  
  return self;
}

@end
