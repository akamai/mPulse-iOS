//
//  MPTouchPageGroup.m
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchPageGroup.h"

@implementation MPTouchPageGroup

-(id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    _name = [dict objectForKey:@"name"];
    _index = [[dict objectForKey:@"index"] integerValue];
    _type = [dict objectForKey:@"type"];
    _label = [dict objectForKey:@"label"];
    
    NSMutableDictionary *conditionDict = [dict objectForKey:@"condition"];
    if (conditionDict)
    {
      _condition = [[MPTouchCondition alloc] initWithDictionary:conditionDict];
    }
    NSMutableDictionary *actionDict = [dict objectForKey:@"action"];
    if (actionDict)
    {
      _action = [[MPTouchAction alloc] initWithDictionary:actionDict];
    }
    NSMutableDictionary *extractDict = [dict objectForKey:@"extract"];
    if (extractDict)
    {
      _extract = [[MPTouchExtract alloc] initWithDictionary:extractDict];
    }
  }
  
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchPageGroup<%p>: pageGroupValue=%@, name=%@, index=%ld, type=%@, label=%@, condition=%@, action=%@, extract=%@]",
          self, [self pageGroupValue], [self name], (long)[self index], [self type], [self label], [self condition], [self action], [self extract]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
  [self.type hash] ^
  [self.label hash] ^
  [self.action hash] ^
  [self.condition hash] ^
  [self.extract hash];
}

- (BOOL) isEqualToPageGroup:(MPTouchPageGroup *)pageGroup
{
  if (!pageGroup) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == pageGroup.index);
  BOOL haveEqualNames = (!self.name && !pageGroup.name) || [self.name isEqualToString:pageGroup.name];
  BOOL haveEqualTypes = (!self.type && !pageGroup.type) || [self.type isEqualToString:pageGroup.type];
  BOOL haveEqualLabels = (!self.label && !pageGroup.label) || [self.label isEqualToString:pageGroup.label];
  BOOL haveEqualActions = (!self.action && !pageGroup.action) || [self.action isEqualToAction:pageGroup.action];
  BOOL haveEqualConditions = (!self.condition && !pageGroup.condition) || [self.condition isEqualToCondition:pageGroup.condition];
  BOOL haveEqualExtracts = (!self.extract && !pageGroup.extract) || [self.extract isEqualToExtract:pageGroup.extract];
  
  return haveEqualIndex &&
  haveEqualNames &&
  haveEqualTypes &&
  haveEqualLabels &&
  haveEqualActions &&
  haveEqualConditions &&
  haveEqualExtracts;
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

- (NSArray*) getAllLocators
{
  NSMutableArray* array = [NSMutableArray new];
  // Action
  if (_action.name != nil && _action.locator != nil)
  {
    [array addObject:_action.locator];
  }
  
  // Condition
  if (_condition.accessor != nil && _condition.locator != nil)
  {
    [array addObject:_condition.locator];
  }
  
  // Extract
  if (_extract.accessor != nil && _extract.locator != nil)
  {
    [array addObject:_extract.locator];
  }
  
  return array;
}

- (void) updateElements:(TTLocatorCollection*) locatorCollection
{
  // Action
  if (_action.name != nil && _action.locator != nil)
  {
    if ([locatorCollection getChosenElementforLocator:[_action.locator serializeShort]] != nil)
    {
      _action.element = [locatorCollection getChosenElementforLocator:[_action.locator serializeShort]];
    }
    else
    {
      _action.element = nil;
    }
  }
  
  // Condition
  if (_condition.accessor != nil && _condition.locator != nil)
  {
    if ([locatorCollection getChosenElementforLocator:[_condition.locator serializeShort]] != nil)
    {
      _condition.element = [locatorCollection getChosenElementforLocator:[_condition.locator serializeShort]];
    }
    else
    {
      _condition.element = nil;
    }
  }
  
  // Extract
  if (_extract.accessor != nil && _extract.locator != nil)
  {
    if ([locatorCollection getChosenElementforLocator:[_extract.locator serializeShort]] != nil)
    {
      _extract.element = [locatorCollection getChosenElementforLocator:[_extract.locator serializeShort]];
    }
    else
    {
      _extract.element = nil;
    }
  }
}

-(id) copyWithZone:(NSZone *)zone
{
  return self;
}

@end
