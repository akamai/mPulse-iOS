//
//  MPTouchMetricValue.m
//  Boomerang
//
//  Created by Giri Senji on 5/5/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchMetricValue.h"

@implementation MPTouchMetricValue

- (id) initWithName:(NSString *)aName index:(NSInteger)anIndex value:(NSNumber *)aValue
{
  MPTouchMetricValue *metricValue = [[MPTouchMetricValue alloc] init];
  if (metricValue)
  {
    metricValue.name = aName;
    metricValue.index = anIndex;
    metricValue.value = aValue;
  }
  return metricValue;
}

- (id) initWithName:(NSString *)aName index:(NSInteger)anIndex value:(NSNumber *)aValue pageGroup:(NSString *)aPageGroup
{
  MPTouchMetricValue *metricValue = [[MPTouchMetricValue alloc] initWithName:aName index:anIndex value:aValue];
  if (metricValue)
  {
    metricValue.pageGroup = aPageGroup;
  }
  return metricValue;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchMetricValue: name=%@, index=%ld, value=%@, pageGroup=%@]", [self name], (long)[self index], [self value], [self pageGroup]];
}

@end
