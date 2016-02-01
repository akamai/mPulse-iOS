//
//  MPConfigPageGroup.m
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPConfigPageGroup.h"

@implementation MPConfigPageGroup

-(id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    _name = [dict objectForKey:@"name"];
    _index = [[dict objectForKey:@"index"] integerValue];
    _type = [dict objectForKey:@"type"];
    _label = [dict objectForKey:@"label"];
  }
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPConfigPageGroup<%p>: pageGroupValue=%@, name=%@, index=%ld, type=%@, label=%@]",
          self, [self pageGroupValue], [self name], (long)[self index], [self type], [self label]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
  [self.type hash] ^
  [self.label hash];
}

- (BOOL) isEqualToPageGroup:(MPConfigPageGroup *)pageGroup
{
  if (!pageGroup) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == pageGroup.index);
  BOOL haveEqualNames = (!self.name && !pageGroup.name) || [self.name isEqualToString:pageGroup.name];
  BOOL haveEqualTypes = (!self.type && !pageGroup.type) || [self.type isEqualToString:pageGroup.type];
  BOOL haveEqualLabels = (!self.label && !pageGroup.label) || [self.label isEqualToString:pageGroup.label];
  
  return haveEqualIndex &&
  haveEqualNames &&
  haveEqualTypes &&
  haveEqualLabels;
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
  
  return [self isEqualToPageGroup:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
