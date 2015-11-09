//
//  MPUIApplicationDelegateHelper.m
//  Boomerang
//
//  Created by Giri Senji on 3/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <objc/runtime.h>
#import "TTMethodSwizzle.h"
#import "MPUIApplicationDelegateHelper.h"
#import "MPUtilities.h"

@implementation MPUIApplicationDelegateHelper
/*
+ (void)processApplicationDelegate:(Class)klass
{
  NSLog(@"BoomerangUIApplicationDelegateHelper processing %@", [klass description]);
  
  if (![MPUtilities class:klass containsDeclaredMethod:@selector(ctApplication:didFinishLaunchingWithOptions:)])
  {
    // Does the class have a application:didFinishLaunchingWithOptions: ?
    BOOL classHasApplication_didFinishLaunchingWithOptions = [MPUtilities class:klass containsDeclaredMethod:@selector(application:didFinishLaunchingWithOptions:)];
    BOOL superclassesHasApplication_didFinishLaunchingWithOptions = [MPUtilities class:class_getSuperclass(klass) containsDeclaredMethod:@selector(application:didFinishLaunchingWithOptions:) checkSuperclasses:YES];
    
    if(classHasApplication_didFinishLaunchingWithOptions && !superclassesHasApplication_didFinishLaunchingWithOptions)
    {
      // Explanation : The method application:didFinishLaunchingWithOptions: is defined on class and not on superclasses
      // The customer's AppDelegate application:didFinishLaunchingWithOptions: may return NO so we will make sure it return YES
      // by swizzling it with ctApplication:didFinishLaunchingWithOptions
      
      // #1 - Add our ctDidFinishLaunchingWithOptions:
      class_addMethod(klass, @selector(ctApplication:didFinishLaunchingWithOptions:), (IMP) mp_application_didFinishLaunchingWithOptions, "v@::");
      NSLog(@"  added ctApplication:didFinishLaunchingWithOptions");
      
      // #2 - And swizzle
      BOOL success = TTMethodSwizzle(klass,
                                     @selector(application:didFinishLaunchingWithOptions:),
                                     @selector(ctApplication:didFinishLaunchingWithOptions:));
      NSLog(@"  watching application:didFinishLaunchingWithOptions: : %@", success?@"success":@"failed");
    }
  }
}

// ---------------- Blank impl. Should no be called, it is here to make the compiler happy
- (BOOL)ctApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  return YES;
}

BOOL application_didFinishLaunchingWithOptions(id self, SEL _cmd, UIApplication *uiApplication, NSDictionary *launchOptions)
{
  return YES;
}

BOOL mp_application_didFinishLaunchingWithOptions(id self, SEL _cmd, UIApplication *uiApplication, NSDictionary *launchOptions)
{
  [self ctApplication:uiApplication didFinishLaunchingWithOptions:launchOptions];
  return YES;
}
*/
@end
