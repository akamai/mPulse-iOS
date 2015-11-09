//
//  MPMetricBeacon.m
//  Boomerang
//
//  Created by Tana Jackson on 4/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPMetricBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"

@implementation MPMetricBeacon
{
}

-(id) initWithMetricName:(NSString *)metricName andValue:(NSNumber *)value
{
  MPConfig *config = [MPConfig sharedInstance];
  for (MPTouchMetric *metric in [[config touchConfig] metrics])
  {
    if ([metric.name isEqualToString:metricName])
    {
      return [self initWithMetricIndex:metric.index andValue:value];
    }
  }
      
  // If we reach this point, there was no match.
  return nil;
}

-(id) initWithMetricIndex:(NSInteger)metricIndex andValue:(NSNumber*)metricValue
{
  if (metricValue == nil)
  {
    return nil;
  }
  else
  {
    self = [super init];
    if (self)
    {
      self.metricIndex = metricIndex;
      self.metricValue = metricValue.integerValue;

      MPLogDebug(@"Initialized metric beacon: index=%d, value=%d", self.metricIndex, self.metricValue);

      [[MPBeaconCollector sharedInstance] addBeacon:self];
    }
    return self;
  }
}

@end
