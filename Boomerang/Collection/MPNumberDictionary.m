//
//  MPNumberDictionary.m
//  Boomerang
//
//  Created by Matthew Solnit on 5/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPNumberDictionary.h"
#import "NSNumber+MPExtensions.h"

@implementation MPNumberDictionary
{
  NSMutableDictionary* _values;
  NSInteger _maxIndex;
}

-(id) init
{
  MPNumberDictionary* dict = [super init];
  
  if (dict)
  {
    dict->_values = [NSMutableDictionary dictionary];
    dict->_maxIndex = -1;
  }
  
  return dict;
}

-(NSUInteger) count
{
  return [_values count];
}

-(void) incrementBucket:(NSInteger)index value:(int)value
{
  // Convert the index to a dictionary key (must be an object, not a primitive).
  NSNumber* key = @(index);
  
  // Get the current value (if any) and increment it.
  NSNumber* currentValue = [_values objectForKey:key];
  NSNumber* newValue;
  if (currentValue == nil)
  {
    newValue = @(value);
  }
  else
  {
    newValue = [currentValue mp_incrementBy:value];
  }
  
  // Update the dictionary.
  [_values setObject:newValue forKey:key];
  
  // If this index is higher than the previous max, then update it.
  if (index > _maxIndex)
  {
    _maxIndex = index;
  }
}

-(NSArray*) asNSArray
{
  // Do we have any values?
  if (_values.count == 0)
  {
    // We don't have any values.
    
    // No point in allocating any memory.
    return nil;
  }
  else
  {
    // We have at least one value.

    // Allocate an array with the required number of elements, initialized to 0's.
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:(_maxIndex + 1)];
    for (int i = 0; i <= _maxIndex; i++)
    {
      [array addObject:@(0)];
    }

    NSEnumerator* enumerator = [_values keyEnumerator];
    NSNumber* index;

    while ((index = [enumerator nextObject]) != nil)
    {
      // Extract the value, and store it in the array
      // at the appropriate position.
      NSNumber* value = [_values objectForKey:index];
      [array replaceObjectAtIndex:index.intValue withObject:value];
    }

    return array;
  }
}

-(int*) asCArray:(int)length
{
  // Do we have any values?
  if (_values.count == 0)
  {
    // We don't have any values.
    
    // No point in allocating any memory.
    return NULL;
  }
  else
  {
    // Allocate an array with the requested number of elements.
    int* array = calloc(length, sizeof(int));

    NSEnumerator* enumerator = [_values keyEnumerator];
    NSNumber* index;
    
    while ((index = [enumerator nextObject]) != nil)
    {
      // As a sanity check, make sure the index
      // fits within the array size.
      if (index.intValue < length)
      {
        // Extract the value, and store it in the array
        // at the appropriate position.
        NSNumber* value = [_values objectForKey:index];
        array[index.intValue] = value.intValue;
      }
    }
    
    return array;
  }
}

@end
