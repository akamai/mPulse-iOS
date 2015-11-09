//
//  MPTouchTimer.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchTimer.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"
#import "NSString+TTExtensions.h"

@implementation MPTouchTimer

-(id) initWithDictionary:(NSMutableDictionary *)dict
{
  self = [super init];
  if (self)
  {
    _name = [dict objectForKey:@"name"];
    _index = [[dict objectForKey:@"index"] integerValue];
    _type = [dict objectForKey:@"type"];
    _label = [dict objectForKey:@"label"];

    NSMutableDictionary *startDict = [dict objectForKey:@"start"];
    NSMutableDictionary *endDict = [dict objectForKey:@"end"];
    
    if (startDict && endDict)
    {
      NSMutableDictionary *startActionDict = [startDict objectForKey:@"action"];
      if (startActionDict)
      {
        _startAction = [[MPTouchAction alloc] initWithDictionary:startActionDict];
      }
      
      NSMutableDictionary *startConditionDict = [startDict objectForKey:@"condition"];
      if (startConditionDict)
      {
        _startCondition = [[MPTouchCondition alloc] initWithDictionary:startConditionDict];
      }

      NSMutableDictionary *endActionDict = [endDict objectForKey:@"action"];
      if (endActionDict)
      {
        _endAction = [[MPTouchAction alloc] initWithDictionary:endActionDict];
      }
      
      NSMutableDictionary *endConditionDict = [endDict objectForKey:@"condition"];
      if (endConditionDict)
      {
        _endCondition = [[MPTouchCondition alloc] initWithDictionary:endConditionDict];
      }
    }
  }
  _pageGroup = [dict objectForKey:@"pageGroup"];
  return self;
}

-(BOOL) isStartAction
{
  return _startAction && _startAction.name && ![_startAction.name tt_isEmpty];
}

-(BOOL) isStartCondition
{
  return _startCondition && _startCondition.accessor && ![_startCondition.accessor tt_isEmpty];
}

-(BOOL) isEndAction
{
  return _endAction && _endAction.name && ![_endAction.name tt_isEmpty];
}

-(BOOL) isEndCondition
{
  return _endCondition && _endCondition.accessor && ![_endCondition.accessor tt_isEmpty];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"[MPTouchTimer<%p>: beacon=%p, name=%@, index=%ld, type=%@, label=%@, startAction=%@, startCondition=%@, endAction=%@, endCondition=%@, pageGroup=%@]", self, [self beacon], [self name], (long)[self index], [self type], [self label], [self startAction], [self startCondition], [self endAction], [self endCondition], [self pageGroup]];
}

- (NSUInteger)hash
{
  return [self.name hash] ^
  [self.type hash] ^
  [self.label hash] ^
  [self.startAction hash] ^
  [self.startCondition hash] ^
  [self.endAction hash] ^
  [self.endCondition hash] ^
  [self.pageGroup hash];
}

- (BOOL) isEqualToTimer:(MPTouchTimer *)timer
{
  if (!timer) {
    return NO;
  }
  
  BOOL haveEqualIndex = (self.index == timer.index);
  BOOL haveEqualNames = (!self.name && !timer.name) || [self.name isEqualToString:timer.name];
  BOOL haveEqualTypes = (!self.type && !timer.type) || [self.type isEqualToString:timer.type];
  BOOL haveEqualLabels = (!self.label && !timer.label) || [self.label isEqualToString:timer.label];
  BOOL haveEqualStartActions = (!self.startAction && !timer.startAction) || [self.startAction isEqualToAction:timer.startAction];
  BOOL haveEqualStartConditions = (!self.startCondition && !timer.startCondition) || [self.startCondition isEqualToCondition:timer.startCondition];
  BOOL haveEqualEndActions = (!self.endAction && !timer.endAction) || [self.endAction isEqualToAction:timer.endAction];
  BOOL haveEqualEndConditions = (!self.endCondition && !timer.endCondition) || [self.endCondition isEqualToCondition:timer.endCondition];
  BOOL haveEqualPageGroups = (!self.pageGroup && !timer.pageGroup) || [self.pageGroup isEqualToString:timer.pageGroup];
  
  return haveEqualIndex &&
  haveEqualNames &&
  haveEqualTypes &&
  haveEqualLabels &&
  haveEqualStartActions &&
  haveEqualStartConditions &&
  haveEqualEndActions &&
  haveEqualEndConditions &&
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
  
  return [self isEqualToTimer:object];
}

- (NSArray*) getAllLocators
{
  NSMutableArray *array = [NSMutableArray new];

  if ([self isStartAction])
  {
    // If the Start condition is an Action
    [array addObject:_startAction.locator];
  }
  else if ([self isStartCondition])
  {
    // If the Start condition is a Condition
    [array addObject:_startCondition.locator];
  }

  if ([self isEndAction])
  {
    // If the End condition is an Action
    [array addObject:_endAction.locator];
  }
  else if ([self isEndCondition])
  {
    // If the End condition is a Condition
    [array addObject:_endCondition.locator];
  }
  
  return array;
}

- (void) updateElements:(TTLocatorCollection *)locatorCollection
{
  if ([self isStartAction])
  {
    // If the Start condition is an Action
    if ([locatorCollection getChosenElementforLocator:[_startAction.locator serializeShort]] != nil)
    {
      _startAction.element = [locatorCollection getChosenElementforLocator:[_startAction.locator serializeShort]];
    }
    else
    {
      _startAction.element = nil;
    }
  }
  else if ([self isStartCondition])
  {
    // If the Start condition is a Condition
    if ([locatorCollection getChosenElementforLocator:[_startCondition.locator serializeShort]] != nil)
    {
      _startCondition.element = [locatorCollection getChosenElementforLocator:[_startCondition.locator serializeShort]];
    }
    else
    {
      _startCondition.element = nil;
    }
  }

  if ([self isEndAction])
  {
    // If the End condition is an Action
    if ([locatorCollection getChosenElementforLocator:[_endAction.locator serializeShort]] != nil)
    {
      _endAction.element = [locatorCollection getChosenElementforLocator:[_endAction.locator serializeShort]];
    }
    else
    {
      _endAction.element = nil;
    }
  }
  else if ([self isEndCondition])
  {
    // If the End condition is a Condition
    if ([locatorCollection getChosenElementforLocator:[_endCondition.locator serializeShort]] != nil)
    {
      _endCondition.element = [locatorCollection getChosenElementforLocator:[_endCondition.locator serializeShort]];
    }
    else
    {
      _endCondition.element = nil;
    }
  }
}

@end
