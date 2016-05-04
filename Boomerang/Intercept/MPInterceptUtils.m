//
//  MPInterceptUtils.m
//  Boomerang
//
//  Created by Nicholas Jansma on 8/21/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//
#import <objc/runtime.h>
#import "MPInterceptUtils.h"
#import "MPConfig.h"
#import "MPApiNetworkRequestBeacon.h"

@implementation MPInterceptUtils

/*
 * Swizzle the requested method with a custom version of our own. If the method doesn't already exists, add the method first.
 */
void swizzleDelegate(Class klass, SEL methodName, SEL boomerangMethod, IMP swizzleMethod, IMP boomerangMethodSwizzle)
{
  // see if this class responds to the base selector first or not
  if (!class_respondsToSelector(klass, methodName))
  {
    // see if any of its parents respond to the selector
    Class superClass = class_getSuperclass(klass);

    while (superClass != nil && !class_respondsToSelector(superClass, methodName))
    {
      superClass = class_getSuperclass(superClass);
    }
    
    if (superClass == nil)
    {
      // didn't have any parents responding to the selector, so let's put in our
      // placeholder selector that we'll actually Swizzle out
      class_addMethod(klass, methodName, swizzleMethod, "v@:::");
    }
    else
    {
      // swizzle the super class instead
      klass = superClass;
    }
  }
  
  class_addMethod(klass, boomerangMethod, boomerangMethodSwizzle, "v@:::");
  
  if (class_respondsToSelector(klass, methodName))
  {
    swizzleInstanceMethod(klass,
                          methodName,
                          boomerangMethod);
  }
  else
  {
    NSLog(@"class doesn't have delegate!!");
  }
}

void swizzleInstanceMethod(Class c, SEL orig, SEL replace)
{
  Method origMethod = class_getInstanceMethod(c, orig);
  Method newMethod = class_getInstanceMethod(c, replace);
  
  if (origMethod != nil && newMethod != nil)
  {
    // try to add the class method first
    if (class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
    {
      class_replaceMethod(c, replace, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else
    {
      method_exchangeImplementations(origMethod, newMethod);
    }
  }
  else
  {
    NSLog(@"not swizzling!!");
    NSLog(@"orig: %i", origMethod == nil);
    NSLog(@"new: %i", newMethod == nil);
  }
}

void swizzleClassMethod(Class c, SEL orig, SEL replace)
{
  Method origMethod = class_getClassMethod(c, orig);
  Method newMethod = class_getClassMethod(c, replace);
  
  if (origMethod != nil && newMethod != nil)
  {
    //        if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
    //            class_replaceMethod(c, replace, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    //        else
    method_exchangeImplementations(origMethod, newMethod);
  }
  else
  {
    NSLog(@"not swizzling!!");
    NSLog(@"orig: %i", origMethod == nil);
    NSLog(@"new: %i", newMethod == nil);
  }
}

/**
 * Determines whether or not the URL should be intercepted
 *
 * @param url URL to check
 * @return True if the URL should be intercepted
 */
+(BOOL) shouldIntercept:(NSURL*)url
{
  MPConfig *config = [MPConfig sharedInstance];
  NSString *hostname = [url host];
  
  if ([hostname isEqualToString:config.beaconURL.host] || [hostname isEqualToString:config.configURL.host])
  {
    return NO;
  }
  
  return YES;
}

/**
 * Parses the result of a network call for a beacon
 *
 * @param beacon Beacon to put results into
 * @param data Data from network call
 * @param response Response from network call
 * @param error Error from network call
 */
+(void) parseResponse:(MPApiNetworkRequestBeacon *)beacon
                 data:(NSData *)data
             response:(NSURLResponse *)response
                error:(NSError *)error
{
  // Did the HTTP request succeed?
  if (error == nil)
  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    
    if ([httpResponse statusCode] < 400)
    {
      // The request succeeded.
      
      // Send a success beacon with the total # of response bytes.
      if (data != nil)
      {
        [beacon endRequestWithBytes:data.length];
      }
      else if (response.expectedContentLength != NSURLResponseUnknownLength)
      {
        [beacon endRequestWithBytes:response.expectedContentLength];
      }
      else
      {
        [beacon endRequestWithBytes:0];
      }
    }
    else
    {
      MPLogDebug(@"NSURLSession HTTP Error : %li", (long)[httpResponse statusCode]);
      // Look for this connection in our timers
      [beacon setNetworkError:[httpResponse statusCode] errorMessage:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]];
    }
  }
  else
  {
    // The request failed.
    
    // Send a failure beacon with the error code.
    MPLogDebug(@"NSURLSession NetworkErrorCode : %ld", (long)[error code]);
    [beacon setNetworkError:[error code] errorMessage:[[error userInfo] objectForKey:@"NSLocalizedDescription"]];
  }
}

@end