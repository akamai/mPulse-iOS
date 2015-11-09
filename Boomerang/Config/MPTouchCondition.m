//
//  MPTouchCondition.m
//  Boomerang
//
//  Created by Giri Senji on 5/27/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchCondition.h"

@implementation MPTouchCondition

- (id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    if (dict)
    {
      _accessor = [dict objectForKey:@"accessor"];
      _locator = [TTLocator initWithLocatorString:[dict objectForKey:@"locator"]];
      _propertyName = [dict objectForKey:@"propertyName"];
      _value = [dict objectForKey:@"value"];
    }
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchCondition<%p>: accessor=%@, locator=%@, propertyName=%@, value=%@]", self, [self accessor], [[self locator] serializeShort], [self propertyName], [self value]];
}

- (NSUInteger)hash
{
  return [self.accessor hash] ^ [[self.locator serializeShort] hash] ^ [self.propertyName hash] ^ [self.value hash];
}

- (BOOL) isEqualToCondition:(MPTouchCondition *)condition
{
  if (!condition) {
    return NO;
  }
  
  BOOL haveEqualAccessors = (!self.accessor && !condition.accessor) || [self.accessor isEqualToString:condition.accessor];
  BOOL haveEqualLocators = (!self.locator && !condition.locator) || [[self.locator serializeShort] isEqualToString:[condition.locator serializeShort]];
  BOOL haveEqualPropertyNames = (!self.propertyName && !condition.propertyName) || [self.propertyName isEqualToString:condition.propertyName];
  BOOL haveEqualValues = (!self.value && !condition.value) || [self.value isEqualToString:condition.value];
  
  return haveEqualAccessors &&
  haveEqualLocators &&
  haveEqualPropertyNames &&
  haveEqualValues;
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
  
  return [self isEqualToCondition:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
