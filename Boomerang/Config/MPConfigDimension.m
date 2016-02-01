//
//  MPConfigDimension.m
//  Boomerang
//
//  Created by Giri Senji on 3/2/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import "MPConfigDimension.h"

@implementation MPConfigDimension

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
  return [NSString stringWithFormat:@"[MPConfigDimension<%p>: name=%@, index=%ld, type=%@, label=%@, dataType=%@]", self, [self name], (long)[self index], [self type], [self label], [self dataType]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
  [self.type hash] ^
  [self.label hash] ^
  [self.dataType hash];
}

- (BOOL) isEqualToDimension:(MPConfigDimension *)dimension
{
  if (!dimension) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == dimension.index);
  BOOL haveEqualNames = (!self.name && !dimension.name) || [self.name isEqualToString:dimension.name];
  BOOL haveEqualTypes = (!self.type && !dimension.type) || [self.type isEqualToString:dimension.type];
  BOOL haveEqualLabels = (!self.label && !dimension.label) || [self.label isEqualToString:dimension.label];
  BOOL haveEqualDataTypes = (!self.dataType && !dimension.dataType) || [self.dataType isEqualToString:dimension.dataType];
  
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
  
  return [self isEqualToDimension:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
