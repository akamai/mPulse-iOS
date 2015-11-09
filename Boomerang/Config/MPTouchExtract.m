//
//  MPTouchExtract.m
//  Boomerang
//
//  Created by Giri Senji on 6/5/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchExtract.h"

@implementation MPTouchExtract

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
      _fixedValue = [dict objectForKey:@"fixedValue"];
    }
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchExtract<%p>: accessor=%@, locator=%@, propertyName=%@, fixedValue=%@]", self, [self accessor], [[self locator] serializeShort], [self propertyName], [self fixedValue]];
}

- (NSUInteger)hash
{
  return [self.accessor hash] ^ [[self.locator serializeShort] hash] ^ [self.propertyName hash] ^ [self.fixedValue hash];
}

- (BOOL) isEqualToExtract:(MPTouchExtract *)extract
{
  if (!extract) {
    return NO;
  }
  
  BOOL haveEqualAccessors = (!self.accessor && !extract.accessor) || [self.accessor isEqualToString:extract.accessor];
  BOOL haveEqualLocators = (!self.locator && !extract.locator) || [[self.locator serializeShort] isEqualToString:[extract.locator serializeShort]];
  BOOL haveEqualPropertyNames = (!self.propertyName && !extract.propertyName) || [self.propertyName isEqualToString:extract.propertyName];
  BOOL haveEqualFixedValues = (!self.fixedValue && !extract.fixedValue) || [self.fixedValue isEqualToString:extract.fixedValue];
  
  return haveEqualAccessors &&
  haveEqualLocators &&
  haveEqualPropertyNames &&
  haveEqualFixedValues;
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
  
  return [self isEqualToExtract:object];
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
