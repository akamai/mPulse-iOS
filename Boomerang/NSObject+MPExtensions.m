//
//  NSObject+MPExtensions.m
//  Boomerang
//
//  Created by Giri Senji on 4/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "NSObject+MPExtensions.h"
#import <objc/runtime.h>

static NSString* const MPSelectorKey = @"aSelector";
static NSString* const MPArgKey = @"arg";
static NSString* const MPExceptionKey = @"exception";

@implementation NSObject (MPExtensions)

- (void)mp_safePerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg
{
  // Wrap the parameters into a single dictionary.
  NSDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                        NSStringFromSelector(aSelector), MPSelectorKey,
                        arg, MPArgKey,
                        nil];
  
  // Call our safe "wrapper" method on the main thread.
  [self performSelectorOnMainThread:@selector(mp_safeSelector:) withObject:dict waitUntilDone:YES];
  
  // Did the call fail?
  NSException *e = [dict objectForKey:MPExceptionKey];
  if (e != nil)
  {
    // Call failed.
    // Re-throw in this thread.
    @throw e;
  }
}

- (void)mp_safeSelector:(NSDictionary*)dict
{
  // Extract the original parameter values.
  SEL aSelector = NSSelectorFromString([dict objectForKey:MPSelectorKey]);
  id arg = [dict objectForKey:MPArgKey];
  
  @try
  {
    // Call the original selector.
    [self performSelector:aSelector onThread:[NSThread currentThread] withObject:arg waitUntilDone:YES];
  }
  @catch (NSException *exception)
  {
    // Exception occurred.
    // Store it in the dictionary so that [safePerformSelectorOnMainThread] can pick it up.
    [dict setValue:exception forKey:MPExceptionKey];
  }
}

@end

@implementation NSObject (MPLogging)

-(NSString *) mp_autoDescribe:(id)instance classType:(Class)classType
{
  NSMutableString *propPrint = [NSMutableString string];
  NSArray *props = [self mp_getPropertyArray:nil];
  
  for (NSDictionary *propDict in props)
  {
    [propPrint appendString:[NSString stringWithFormat:@"%@=%@\n", [propDict objectForKey:@"name"], [propDict objectForKey:@"value"]]];
  }
  
  return propPrint;
}

//Returns true if the object has the given property
-(BOOL)mp_hasPropertyNamed:(NSString *)propName
{
  NSMutableArray *props = [NSMutableArray arrayWithArray:[self mp_getPropertyArrayForClassType:[self class] :nil]];
  for (NSDictionary *prop in props)
  {
    if ([[prop objectForKey:@"name"] isEqualToString:propName])
      return YES;
  }
  return NO;
}


//Returns the full property array for this instance
-(NSArray *)mp_getPropertyArray:(NSArray *)includeList
{
  if (includeList.count == 1 && [[includeList objectAtIndex:0] isEqualToString:@"all"])
    includeList = nil;
  
  NSMutableArray *props = [NSMutableArray arrayWithArray:[self mp_getPropertyArrayForClassType:[self class] :includeList]];
  
  Class superClass = class_getSuperclass([self class]);
  while (superClass != nil && ![superClass isEqual:[NSObject class]])
  {
    NSArray *superProperties = [self mp_getPropertyArrayForClassType:superClass :includeList];
    for (NSString *property in superProperties)
    {
      // Remove duplicates
      if (![props containsObject:property])
        [props addObject:property];
    }
    superClass = class_getSuperclass(superClass);
  }
  return [NSArray arrayWithArray:props];
}

//Returns the property array for the specified base class of this instance
-(NSArray *)mp_getPropertyArrayForClassType:(Class)classType :(NSArray *)includeList
{
  unsigned int count;
  objc_property_t *propList = class_copyPropertyList(classType, &count);
  NSMutableArray *props = [[NSMutableArray alloc] init];
  
  for (int i = 0; i < count; i++)
  {
    objc_property_t property = propList[i];
    
    const char *propName = property_getName(property);
    NSString *propNameString =[NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
    
    // Don't output the internalId unless we are locating.
    if (!((includeList == nil) && [propNameString isEqualToString:@"_internal_mpId"]))
    {
      if(propName && (includeList == nil || [includeList containsObject:propNameString]) &&
         ![propNameString isEqualToString:@"typingAttributes"]) // This property crashes the app.  This can be seen in Stockfish.
      {
        @try
        {
          NSString *propValueString = @"(null)";
          id value = [self valueForKey:propNameString];
          if (value)
          {
            propValueString = [NSString stringWithFormat:@"%@",value];
          }
          [props addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:propNameString, propValueString, nil] forKeys:[NSArray arrayWithObjects:@"name", @"value", nil]]];
        }
        @catch (NSException *exception)
        {
          //MPLogDebug(@"Can't get value for property %@ through KVO\n", propNameString);
          //[propPrint appendString:[NSString stringWithFormat:@"Can't get value for property %@ through KVO\n", propNameString]];
        }
      }
    }
  }
  free(propList);
  
  return [NSArray arrayWithArray:props];
}

@end
