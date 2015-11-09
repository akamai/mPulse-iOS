//
//  MPTouchAction.m
//  Boomerang
//
//  Created by Giri Senji on 5/27/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchAction.h"

@implementation MPTouchAction

- (id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    if (dict)
    {
      _name = [dict objectForKey:@"name"];
      _locator = [TTLocator initWithLocatorString:[dict objectForKey:@"locator"]];
    }
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchAction<%p>: name=%@, locator=%@]", self, [self name], [[self locator] serializeShort]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^ [[self.locator serializeShort] hash];
}

- (BOOL) isEqualToAction:(MPTouchAction *)action
{
  if (!action) {
    return NO;
  }

  BOOL haveEqualNames = (!self.name && !action.name) || [self.name isEqualToString:action.name];
  BOOL haveEqualLocators = (!self.locator && !action.locator) || [[self.locator serializeShort] isEqualToString:[action.locator serializeShort]];
  
  return haveEqualNames && haveEqualLocators;
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
  
  return [self isEqualToAction:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
