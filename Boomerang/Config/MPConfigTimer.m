//
//  MPConfigTimer.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPConfigTimer.h"

@implementation MPConfigTimer

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
  return [NSString stringWithFormat:@"[MPConfigTimer<%p>: name=%@, index=%ld, type=%@, label=%@", self, [self name], (long)[self index], [self type], [self label]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
  [self.type hash] ^
  [self.label hash];
}

- (BOOL) isEqualToTimer:(MPConfigTimer *)timer
{
  if (!timer) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == timer.index);
  BOOL haveEqualNames = (!self.name && !timer.name) || [self.name isEqualToString:timer.name];
  BOOL haveEqualTypes = (!self.type && !timer.type) || [self.type isEqualToString:timer.type];
  BOOL haveEqualLabels = (!self.label && !timer.label) || [self.label isEqualToString:timer.label];
  
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
  
  return [self isEqualToTimer:object];
}

@end
