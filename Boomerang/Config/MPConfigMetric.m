//
//  MPConfigMetric.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPConfigMetric.h"

@implementation MPConfigMetric

-(id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    _name = [dict objectForKey:@"name"];
    _index = [[dict objectForKey:@"index"] integerValue];
    _type = [dict objectForKey:@"type"];
    _label = [dict objectForKey:@"label"];
    _dataType = [dict objectForKey:@"dataType"];
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPConfigMetric<%p>: name=%@, index=%ld, type=%@, label=%@, dataType=%@]", self, [self name], (long)[self index], [self type], [self label], [self dataType]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
         [self.type hash] ^
         [self.label hash] ^
         [self.dataType hash];
}

- (BOOL) isEqualToMetric:(MPConfigMetric *)metric
{
  if (!metric) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == metric.index);
  BOOL haveEqualNames = (!self.name && !metric.name) || [self.name isEqualToString:metric.name];
  BOOL haveEqualTypes = (!self.type && !metric.type) || [self.type isEqualToString:metric.type];
  BOOL haveEqualLabels = (!self.label && !metric.label) || [self.label isEqualToString:metric.label];
  BOOL haveEqualDataTypes = (!self.dataType && !metric.dataType) || [self.dataType isEqualToString:metric.dataType];
  
  return haveEqualIndex &&
         haveEqualNames &&
         haveEqualTypes &&
         haveEqualLabels &&
         haveEqualDataTypes;
}

- (BOOL)isEqual:(id)object
{
  if (object == nil || [self class] != [object class])
  {
    return NO;
  }
  
  if (self == object )
  {
    return YES;
  }

  return [self isEqualToMetric:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
