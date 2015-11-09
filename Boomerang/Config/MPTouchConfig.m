//
//  TouchConfig.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchConfig.h"
#import "NSObject+TT_SBJSON.h"
#import "JSON.h"

@implementation MPTouchConfig

/*
 PageParams example:
 
 PageParams:
 {
 pageGroups: [],
 customMetrics: [
 {
 "name": "MetricButton",
 "index": 0,
 "type": "TouchMetric",
 "label": "cmet.MetricButton",
 "action": {
 "name": "Tap",
 "locator": "text=Touch Metric Button[1]"
 },
 "extract": {
 "accessor": "elementText",
 "locator": "classname=UILabel[1]"
 }
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
        [tempPageGroups addObject:[[MPTouchPageGroup alloc] initWithDictionary:pageGroupDict]];
      }
      
      for (NSMutableDictionary *metricDict in [jsonData objectForKey:@"customMetrics"])
      {
        [tempMetrics addObject:[[MPTouchMetric alloc] initWithDictionary:metricDict]];
      }
      
      for (NSMutableDictionary *timerDict in [jsonData objectForKey:@"customTimers"])
      {
        [tempTimers addObject:[[MPTouchTimer alloc] initWithDictionary:timerDict]];
      }
      
      for (NSMutableDictionary *dimensionDict in [jsonData objectForKey:@"customDimensions"])
      {
        [tempDimensions addObject:[[MPTouchDimension alloc] initWithDictionary:dimensionDict]];
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
-(void) deepCopy:(MPTouchConfig *)config
{
  // Add newly introducted pageGroups while persisting the data of any unchanged pageGroups
  NSArray *inputPageGroups = [NSArray arrayWithArray:[config pageGroups]];
  
  for (MPTouchPageGroup *pageGroup in inputPageGroups)
  {
    for (MPTouchPageGroup *oldPageGroup in _pageGroups)
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

  // Add newly introducted metrics while persisting the data of any unchanged metrics
  NSArray *inputMetrics = [NSArray arrayWithArray:[config metrics]];
  
  for (MPTouchMetric *metric in inputMetrics)
  {
    for (MPTouchMetric *oldMetric in _metrics)
    {
      if ([metric isEqualToMetric:oldMetric])
      {
        // If the metric is the same as old metric, update its beaconSent flag values.
        [metric setBeaconSent:[oldMetric beaconSent]];
      }
    }
  }
  
  // Update the metrics
  _metrics = inputMetrics;
  
  //Copy Timers
  
  // Add newly introducted timers while persisting the data of any unchanged timers
  NSArray *inputTimers = [NSArray arrayWithArray:[config timers]];
  
  for (MPTouchTimer *timer in inputTimers)
  {
    for (MPTouchTimer *oldTimer in _timers)
    {
      if ([timer isEqualToTimer:oldTimer])
      {
        // If the timer is the same as old timer, update its beacon.
        if ([oldTimer beacon])
        {
          [timer setBeacon:[oldTimer beacon]];
        }
      }
    }
  }
  
  // Update the timers
  _timers = inputTimers;
  
  // Add newly introducted dimensions while persisting the data of any unchanged dimensions
  NSArray *inputDimensions = [NSArray arrayWithArray:[config dimensions]];
  
  for (MPTouchDimension *dimension in inputDimensions)
  {
    for (MPTouchDimension *oldDimension in _dimensions)
    {
      if ([dimension isEqualToDimension:oldDimension])
      {
        // If the dimension is the same as old dimension, update its beaconSent flag values.
        [dimension setBeaconSent:[oldDimension beaconSent]];
      }
    }
  }
  
  // Update the dimensions
  _dimensions = inputDimensions;
}

// Iterates through all the locators present in PageGroups, Metrics and Timers and insert
// them into TTLocatorCollection. This TTLocatorCollection instance is returned.
- (TTLocatorCollection*) getAllLocators
{
  TTLocatorCollection *locatorCollection = [[TTLocatorCollection alloc] init];
  
  for (MPTouchPageGroup *pageGroup in _pageGroups)
  {
    for (TTLocator *locator in [pageGroup getAllLocators])
    {
      [locatorCollection addLocator:[locator serializeShort]];
    }
  }
  
  for (MPTouchMetric *metric in _metrics)
  {
    for (TTLocator *locator in [metric getAllLocators])
    {
      [locatorCollection addLocator:[locator serializeShort]];
    }
  }
  
  for (MPTouchTimer *timer in _timers)
  {
    for (TTLocator *locator in [timer getAllLocators])
    {
      [locatorCollection addLocator:[locator serializeShort]];
    }
  }
  
  for (MPTouchDimension *dimension in _dimensions)
  {
    for (TTLocator *locator in [dimension getAllLocators])
    {
      [locatorCollection addLocator:[locator serializeShort]];
    }
  }
  
  return locatorCollection;
}

// Iterates through all the locators present in PageGroups, Metrics and Timers and updates the corresponding element
// if found in the provided TTLocatorCollection object. If a matching element is not found, existing element is cleared.
- (void) updateStoredElements:(TTLocatorCollection*) locatorCollection
{
  for (MPTouchPageGroup *pageGroup in _pageGroups)
  {
    [pageGroup updateElements:locatorCollection];
  }
  
  for (MPTouchMetric *metric in _metrics)
  {
    [metric updateElements:locatorCollection];
  }
  
  for (MPTouchTimer *timer in _timers)
  {
    [timer updateElements:locatorCollection];
  }
  
  for (MPTouchDimension *dimension in _dimensions)
  {
    [dimension updateElements:locatorCollection];
  }
}

- (NSString *)description
{
  NSString *pageGroupsString = nil;
  for (NSString *pageGroup in [self pageGroups])
  {
    pageGroupsString = [NSString stringWithFormat:@"%@%@", (pageGroupsString ? ([NSString stringWithFormat:@"%@,", pageGroupsString]) : @""), pageGroup];
  }
  NSString *metricsString = nil;
  for (MPTouchMetric *metric in [self metrics])
  {
    metricsString = [NSString stringWithFormat:@"%@%@", (metricsString ? ([NSString stringWithFormat:@"%@,", metricsString]) : @""), [metric description]];
  }
  NSString *timersString = nil;
  for (MPTouchTimer *timer in [self timers])
  {
    timersString = [NSString stringWithFormat:@"%@%@", (timersString ? ([NSString stringWithFormat:@"%@,", timersString]) : @""), [timer description]];
  }
  return [NSString stringWithFormat:@"[MPTouchConfig: pageGroups=(%@), metrics=(%@), timers=(%@)]", pageGroupsString, metricsString, timersString];
  NSString *dimensionString = nil;
  for (MPTouchDimension *dimension in [self dimensions])
  {
    dimensionString = [NSString stringWithFormat:@"%@%@", (dimensionString ? ([NSString stringWithFormat:@"%@,", dimensionString]) : @""), [dimension description]];
  }
}

@end
