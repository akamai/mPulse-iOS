//
//  MPTouchMetric.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchMetric.h"
#import "TTLocator.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"

@implementation MPTouchMetric

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
    _pageGroup = [dict objectForKey:@"pageGroup"];
    _beaconSent = NO;
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchMetric<%p>: beaconSent=%@, name=%@, index=%ld, type=%@, label=%@, dataType=%@, condition=%@, action=%@, extract=%@, pageGroup=%@]", self, _beaconSent?@"YES":@"NO", [self name], (long)[self index], [self type], [self label], [self dataType], [self condition], [self action], [self extract], [self pageGroup]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
         [self.type hash] ^
         [self.label hash] ^
         [self.dataType hash] ^
         [self.action hash] ^
         [self.condition hash] ^
         [self.extract hash] ^
         [self.pageGroup hash];
}

- (BOOL) isEqualToMetric:(MPTouchMetric *)metric
{
  if (!metric) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == metric.index);
  BOOL haveEqualNames = (!self.name && !metric.name) || [self.name isEqualToString:metric.name];
  BOOL haveEqualTypes = (!self.type && !metric.type) || [self.type isEqualToString:metric.type];
  BOOL haveEqualLabels = (!self.label && !metric.label) || [self.label isEqualToString:metric.label];
  BOOL haveEqualDataTypes = (!self.dataType && !metric.dataType) || [self.dataType isEqualToString:metric.dataType];
  BOOL haveEqualActions = (!self.action && !metric.action) || [self.action isEqualToAction:metric.action];
  BOOL haveEqualConditions = (!self.condition && !metric.condition) || [self.condition isEqualToCondition:metric.condition];
  BOOL haveEqualExtracts = (!self.extract && !metric.extract) || [self.extract isEqualToExtract:metric.extract];
  BOOL haveEqualPageGroups = (!self.pageGroup && !metric.pageGroup) || [self.pageGroup isEqualToString:metric.pageGroup];
  
  return haveEqualIndex &&
         haveEqualNames &&
         haveEqualTypes &&
         haveEqualLabels &&
         haveEqualDataTypes &&
         haveEqualActions &&
         haveEqualConditions &&
         haveEqualExtracts &&
         haveEqualPageGroups;
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
