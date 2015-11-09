//
//  MPUtilities.m
//  Boomerang
//
//  Created by Giri Senji on 3/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPUtilities.h"
#import <objc/runtime.h>

@implementation MPUtilities

NSString* const BOOMERANG_INSTALL_BEACON_SENT = @"boomerang-install-beacon-sent";
NSString* const BOOMERANG_DATA_PLIST = @"BoomerangData.plist";

/**
 * Check if the class have the class method
 * It won't check the superclasses
 */
+(BOOL)class:(Class)klass containsDeclaredClassMethod:(SEL)methodSelector
{
  // Notice the object_getClass(klass)
  return [MPUtilities class:object_getClass(klass) containsDeclaredMethod:methodSelector];
}


/**
 * Check if the class have the instance method
 * It won't check the superclasses
 */
+(BOOL)class:(Class)klass containsDeclaredMethod:(SEL)methodSelector
{
  BOOL contains = NO;
  unsigned int numMethods = 0;
  Method * methods = class_copyMethodList(klass, &numMethods);
  for(int i=0;i<numMethods;i++)
  {
    if(method_getName(methods[i]) == methodSelector)
    {
      contains = YES;
      break;
    }
  }
  free(methods);
  return contains;
}

/**
 * Check if the class have the instance method
 * set checkSuperclasses to YES to check the superclasses
 */
+(BOOL)class:(Class)klass containsDeclaredMethod:(SEL)methodSelector checkSuperclasses:(BOOL)checkSuperclasses
{
  if(checkSuperclasses)
  {
    // This code will check the class and the superclasses
    return class_getInstanceMethod(klass, methodSelector);
  }
  else
  {
    // This will only check the class
    return [MPUtilities class:klass containsDeclaredMethod:methodSelector];
  }
}

/**
 * The idea behind this method is to check if the class and superclasses are conform to protocol
 * without initializing the class !
 * [class conformsToProtocol:] is not an option
 */
+(BOOL)class:(Class)klass isConformsToProtocol:(Protocol*)protocol;
{
  if(class_respondsToSelector(klass, @selector(conformsToProtocol:)))
  {
    // We CANNOT call any method on the class, let's use the objc function
    Class c = klass;
    while(c)
    {
      if(class_conformsToProtocol(c, protocol))
      {
        return YES;
      }
      Class superclass = class_getSuperclass(c);
      c = superclass != c ? superclass : nil;
    }
  }
  return NO;
}

+ (NSString*) getBoomerangDataFile
{
  // Get documents directory's location
  // Example: /var/mobile/Applications/0793B51A-832A-49B2-8A5C-383A51F9ACEF/Documents
  NSArray *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
  NSString *filePath = [docDir objectAtIndex:0];
  NSString *plistPath = [filePath stringByAppendingPathComponent:BOOMERANG_DATA_PLIST];
  MPLogDebug(@"Boomerang Data Plist file path: %@", plistPath);
  
  // If the first doesn't exist, create it and send the first install beacon.
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:plistPath])
  {
    // Create a new dictionary to write to BoomerangData.plist file
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"NO", BOOMERANG_INSTALL_BEACON_SENT, nil];
    
    // Save the file
    [plistDict writeToFile:plistPath atomically:YES];
    
    if([fileManager fileExistsAtPath:plistPath])
    {
      MPLogDebug(@"BoomerangData.plist file write succeeded.");
    }
    else
    {
      MPLogDebug(@"BoomerangData.plist file write failed.");
      return nil;
    }
  }
  
  return plistPath;
}

+(void) base36:(int)value andInjectInto:(NSMutableString *) resultString
{
	NSString *base36 = @"0123456789abcdefghijklmnopqrstuvwxyz";
  
  while (value != 0)
  {
    int x;
    x = value % 36;
    
    NSRange range;
    range.length = 1;
    range.location = x;
    
    NSString *digitString  = [base36 substringWithRange: range];
    [resultString insertString: digitString atIndex: 0];
    
    value = value / 36;
  }
}

// Returns a UUID
+(NSString *) getUUID
{
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  
  return uuidString;
}

@end
