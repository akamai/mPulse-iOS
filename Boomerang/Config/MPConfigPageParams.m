//
//  MPConfigPageParams.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPConfigPageParams.h"
#import "NSObject+TT_SBJSON.h"
#import "JSON.h"

@implementation MPConfigPageParams

/*
 PageParams example:
 
 PageParams:
 {
  pageGroups: [],
  customMetrics: [
    {
      "name": "MetricButton",
      "index": 0,
      "type": "Number",
      "label": "cmet.MetricButton"
    }
  ],
  customTimers: [],
  urlPatterns: [],
  params: true
 }
 */
-(id) initWithJson:(NSDictionary *)jsonData
{
  self = [super init];
  if (self)
  {
    if (jsonData != nil)
    {
      NSMutableArray *tempPageGroups = [NSMutableArray new];
      NSMutableArray *tempMetrics = [NSMutableArray new];
      NSMutableArray *tempTimers = [NSMutableArray new];
      NSMutableArray *tempDimensions = [NSMutableArray new];
      
      for (NSMutableDictionary *pageGroupDict in [jsonData objectForKey:@"pageGroups"])
      {
        [tempPageGroups addObject:[[MPConfigPageGroup alloc] initWithDictionary:pageGroupDict]];
      }
      
      for (NSMutableDictionary *metricDict in [jsonData objectForKey:@"customMetrics"])
      {
        [tempMetrics addObject:[[MPConfigMetric alloc] initWithDictionary:metricDict]];
      }
      
      for (NSMutableDictionary *timerDict in [jsonData objectForKey:@"customTimers"])
      {
        [tempTimers addObject:[[MPConfigTimer alloc] initWithDictionary:timerDict]];
      }
      
      for (NSMutableDictionary *dimensionDict in [jsonData objectForKey:@"customDimensions"])
      {
        [tempDimensions addObject:[[MPConfigDimension alloc] initWithDictionary:dimensionDict]];
      }
      
      _pageGroups = tempPageGroups;
      _metrics = tempMetrics;
      _timers = tempTimers;
      _dimensions = tempDimensions;
    }
  }
  
  return self;
}

/*
 * Performs a deep copy of the object data while maintaining data from the original which is not present in the input object.
 * Example: beaconSent flag status.
 */
-(void) deepCopy:(MPConfigPageParams *)config
{
  // Add newly introducted pageGroups while persisting the data of any unchanged pageGroups
  NSArray *inputPageGroups = [NSArray arrayWithArray:[config pageGroups]];
  
  for (MPConfigPageGroup *pageGroup in inputPageGroups)
  {
    for (MPConfigPageGroup *oldPageGroup in _pageGroups)
    {
      if ([pageGroup isEqualToPageGroup:oldPageGroup])
      {
        // If the pageGroup is the same as old pageGroup, update its pageGroupSet flag values.
        [pageGroup setPageGroupValue:[oldPageGroup pageGroupValue]];
      }
    }
  }
  
  // Update the pageGroups
  _pageGroups = inputPageGroups;

  // Copy the Metrics, Dimensions and Timers
  _metrics = [NSArray arrayWithArray:[config metrics]];
  _timers = [NSArray arrayWithArray:[config timers]];
  _dimensions = [NSArray arrayWithArray:[config dimensions]];
}

- (NSString *)description
{
  NSString *pageGroupsString = nil;
  for (NSString *pageGroup in [self pageGroups])
  {
    pageGroupsString = [NSString stringWithFormat:@"%@%@", (pageGroupsString ? ([NSString stringWithFormat:@"%@,", pageGroupsString]) : @""), pageGroup];
  }
  NSString *metricsString = nil;
  for (MPConfigMetric *metric in [self metrics])
  {
    metricsString = [NSString stringWithFormat:@"%@%@", (metricsString ? ([NSString stringWithFormat:@"%@,", metricsString]) : @""), [metric description]];
  }
  NSString *timersString = nil;
  for (MPConfigTimer *timer in [self timers])
  {
    timersString = [NSString stringWithFormat:@"%@%@", (timersString ? ([NSString stringWithFormat:@"%@,", timersString]) : @""), [timer description]];
  }
  return [NSString stringWithFormat:@"[MPConfigPageParams: pageGroups=(%@), metrics=(%@), timers=(%@)]", pageGroupsString, metricsString, timersString];
  NSString *dimensionString = nil;
  for (MPConfigDimension *dimension in [self dimensions])
  {
    dimensionString = [NSString stringWithFormat:@"%@%@", (dimensionString ? ([NSString stringWithFormat:@"%@,", dimensionString]) : @""), [dimension description]];
  }
}

@end
