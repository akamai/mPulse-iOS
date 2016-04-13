//
//  MPInterceptURLConnectionDelegate.m
//  Boomerang
//
//  Created by Tana Jackson on 4/2/13.
//  Copyright (c) 2013-2015 SOASTA. All rights reserved.
//

#import <objc/runtime.h>
#import "MPURLConnection.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPInterceptUtils.h"

@implementation MPInterceptURLConnectionDelegate

static id syncLockObject;

// SINGLETON
static MPInterceptURLConnectionDelegate *interceptURLConnectionDelegateInstance = NULL;

+(MPInterceptURLConnectionDelegate *) sharedInstance
{
  @synchronized(self)
  {
    if (interceptURLConnectionDelegateInstance == NULL)
    {
      interceptURLConnectionDelegateInstance = [[self alloc] init];
    }
  }
  
  return interceptURLConnectionDelegateInstance;
}

-(id) init
{
  self = [super init];
  if (self)
  {
    MPLogDebug(@"App finished launching: Swizzling NSURLConnection.sendSynchronousRequest");
    swizzleClassMethod([NSURLConnection class],
                         @selector(sendSynchronousRequest:returningResponse:error:),
                         @selector(boomerangSendSynchronousRequest:returningResponse:error:));
      
    MPLogDebug(@"App finished launching: Swizzling NSURLConnection.sendAsynchronousRequest");
    swizzleClassMethod([NSURLConnection class],
                         @selector(sendAsynchronousRequest:queue:completionHandler:),
                         @selector(boomerangSendAsynchronousRequest:queue:completionHandler:));
      
    MPLogDebug(@"App finished launching: Swizzling NSURLConnection.initWithRequest");
    swizzleInstanceMethod([NSURLConnection class],
                            @selector(initWithRequest:delegate:),
                            @selector(boomerangInitWithRequest:delegate:));
      
    MPLogDebug(@"App finished launching: Swizzling NSURLConnection.initWithRequest");
    swizzleInstanceMethod([NSURLConnection class],
                            @selector(initWithRequest:delegate:startImmediately:),
                            @selector(boomerangInitWithRequest:delegate:startImmediately:));
    
    m_beacons = [[NSMutableDictionary alloc] init];
    
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    objc_getClassList(classes, numClasses);
    
    // Iterate through all the classes and process the ones that conform to NSURLConnectionDelegate protocol.
    for (int i=0; i<numClasses; i++)
    {
      Class klass = classes[i];
      NSString* classname = [NSString stringWithUTF8String:object_getClassName(klass)];
      if (![self shouldSwizzleClass:klass classname:classname])
      {
        continue; // Don't record our own traffic.
      }
      
      if(class_conformsToProtocol(klass,@protocol(NSURLConnectionDelegate)))
      {
        MPLogDebug(@"Found %@ <NSURLConnectionDelegate>", classname);
        [self processDelegate:klass];
      }
    }
  }
  return self;
}

-(BOOL) shouldSwizzleClass:(Class) klass classname:(NSString*) classname
{
  return !(klass == [MPURLConnection class] || [classname isEqualToString:@"TTURLConnection"]);
}

// The key is the address of the NSURLConnection
-(void)addBeacon:(MPApiNetworkRequestBeacon *)value forKey:(NSString *)key
{
  MPLogDebug(@"Adding beacon for key: %@", key);
  @synchronized(m_beacons)
  {
    [m_beacons setObject:value forKey:key];
  }
}

-(MPApiNetworkRequestBeacon *)getBeaconForKey:(NSString *)key
{
  @synchronized(m_beacons)
  {
    MPApiNetworkRequestBeacon* beacon = [m_beacons objectForKey:key];
    return beacon;
  }
}

// Process the Delegates that do not conform with NSURLConnectionDelegate Protocol
-(void)processNonConformingDelegate:(Class)klass
{
  // This process has to be synchronized as we are calling it as part of NSURLConnection's initWithRequest method.
  // If its not synchronized, we might miss some HTTP requests, where the request completes before the swizzling completes.
  @synchronized(syncLockObject)
  {
    if (!class_conformsToProtocol(klass, @protocol(NSURLConnectionDelegate)))
    {
      // Case 87289: Specific fix for AFNetworking framework.
      // If the app uses AFNetworking framework and subclasses any of the standard framework classes, they must call the overridden methods in super class.
      // Since we add methods as needed when we swizzle the classes, we must also call the superclass methods. But we cannot do that, since we don't have the
      // super class instance method.
      
      // Instead, we need to search for a parent conforming to NSURLConnectionDelegate protocol in AFNetworking framework. This is difficult
      // because during runtime none of the classes conform to the NSURLConnectionDelegate protocol but they all respond to connection:didReceiveResponse:
      // selector.
      
      // To resolve this situation, we must find "AFURLConnectionOperation" from the list of parents and then we can safely swizzle the required methods on this class.
      // AFNetworking framework can add more such parent classes in the future, and we'll have to add those classes here accordingly.
      Class superClass = class_getSuperclass(klass);
      while (superClass != nil && ![[NSString stringWithUTF8String:object_getClassName(superClass)] isEqualToString:@"AFURLConnectionOperation"])
      {
        superClass = class_getSuperclass(superClass);
      }
      
      if (superClass != nil)
      {
        MPLogDebug(@"Received %@ Class from AFNetworking framework. Will swizzle the top level parent \"AFURLConnectionOperation\" that conforms to NSURLConnectionDelegate.", [NSString stringWithUTF8String:object_getClassName(klass)]);
        
        klass = superClass;
      }
    }
    
    [self processDelegate:klass];
  }
}

-(void)processDelegate:(Class)klass
{
  // This process has to be synchronized as we are calling it as part of NSURLConnection's initWithRequest method.
  // If its not synchronized, we might miss some HTTP requests, where the request completes before the swizzling completes.
  @synchronized(syncLockObject)
  {
    NSString* classname = [NSString stringWithUTF8String:object_getClassName(klass)];
    if (![self shouldSwizzleClass:klass classname:classname])
    {
      return;
    }
    
    // We swizzle the connection:didReceiveResponse: method with boomerangConnection:didReceiveResponse: method.
    // Thus, if our class already responds to boomerangConnection:didReceiveResponse: selector, then swizzling has already been done.
    if(!class_respondsToSelector(klass, @selector(boomerangConnection:didReceiveResponse:)))
    {
      // connection:didReceiveResponse:
      swizzleDelegate(klass, @selector(connection:didReceiveResponse:),@selector(boomerangConnection:didReceiveResponse:), (IMP) connection_didReceiveResponse,(IMP) boomerangConnection_didReceiveResponse);
      
      // connection:didFailWithError:
      swizzleDelegate(klass, @selector(connection:didFailWithError:),@selector(boomerangConnection:didFailWithError:), (IMP) connection_didFailWithError, (IMP) boomerangConnection_didFailWithError);
    }
  }
}

void boomerangConnection_didFailWithError(id self, SEL _cmd, NSURLConnection *connection, NSError *error)
{
  @try
  {
    MPApiNetworkRequestBeacon *beacon = [[MPInterceptURLConnectionDelegate sharedInstance] getBeaconForKey:[NSString stringWithFormat:@"%p", connection]];
    // The request failed.
    if (beacon != nil)
    {
        // Send a failure beacon with the error code.
        MPLogDebug(@"boomerangConnection_didFailWithError NetworkErrorCode is %ld",(long)[error code]);
        [beacon setNetworkError:[error code] errorMessage:[[error userInfo] objectForKey:@"NSLocalizedDescription"]];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangConnection_didFailWithError() method. Exception %@, received: %@", [exception name], [exception reason]);
  }
  @finally
  {
    [self boomerangConnection:connection didFailWithError:error];
  }
}

void boomerangConnection_didReceiveResponse(id self, SEL _cmd, NSURLConnection *connection, NSURLResponse *response)
{
  @try
  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse != nil)
    {
      if (([httpResponse statusCode] < 400))
      {
        //SUCCESS!
        MPApiNetworkRequestBeacon *beacon = [[MPInterceptURLConnectionDelegate sharedInstance] getBeaconForKey:[NSString stringWithFormat:@"%p", connection]];
        if (beacon != nil)
        {
          // This sends the beacon
          [beacon endRequestWithBytes:httpResponse.expectedContentLength];
        }
      }
      else
      {
        MPLogDebug(@"HTTP Error : %li", (long)[httpResponse statusCode]);
        // Look for this connection in our timers
        MPApiNetworkRequestBeacon *beacon = [[MPInterceptURLConnectionDelegate sharedInstance] getBeaconForKey:[NSString stringWithFormat:@"%p", connection]];
        if (beacon != nil)
        {
          [beacon setNetworkError:[httpResponse statusCode] errorMessage:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]];
        }
      }
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangConnection_didReceiveResponse() method. Exception %@, received: %@", [exception name], [exception reason]);
  }
  @finally
  {
    [self boomerangConnection:connection didReceiveResponse:response];
  }
}

void connection_didReceiveResponse(id self, SEL _cmd, NSURLConnection *connection, NSURLResponse *response)
{
}

void connection_didFailWithError(id self, SEL _cmd, NSURLConnection *connection, NSURLResponse *response)
{
}

-(void) boomerangConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  //NSLog(@"!!! THIS SHOULD NEVER BE CALLED !!!");
}

-(void) boomerangConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  //NSLog(@"!!! THIS SHOULD NEVER BE CALLED !!!");  
}

-(void) boomerangConnectionDidFinishLoading:(NSURLConnection *)connection
{
  //NSLog(@"!!! THIS SHOULD NEVER BE CALLED !!!");
}

@end
