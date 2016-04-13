//
//  MPInterceptURLSessionDelegate.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <objc/runtime.h>
#import "MPInterceptURLSessionDelegate.h"
#import "NSURLSession+MPIntercept.h"
#import "MPInterceptUtils.h"

@implementation MPInterceptURLSessionDelegate

// Sync lock object
static id syncLockObject;

// Singleton
static MPInterceptURLSessionDelegate *interceptURLSessionDelegateInstance = NULL;

/**
 * Shared instance of the MPInterceptURLSessionDelegate
 * @return Shared instance
 */
+(MPInterceptURLSessionDelegate *) sharedInstance
{
  @synchronized(self)
  {
    if (interceptURLSessionDelegateInstance == NULL)
    {
      interceptURLSessionDelegateInstance = [[self alloc] init];
    }
  }
  
  return interceptURLSessionDelegateInstance;
}

/**
 * Delegate initialization
 */
-(id) init
{
  self = [super init];
  if (self)
  {    
    MPLogDebug(@"App finished launching: Swizzling NSURLSession");
    
    // See comment in NSURLSession+MPIntercept.m for details on how everything is swizzled
    
    //
    // dataTaskWithRequest: variants (also handles dataTaskWithHTTPGetRequest:
    // and dataTaskWithURL: variants)
    //
    swizzleInstanceMethod([NSURLSession class],
                          @selector(dataTaskWithRequest:),
                          @selector(boomerangDataTaskWithRequest:));
    
    swizzleInstanceMethod([NSURLSession class],
                          @selector(dataTaskWithRequest:completionHandler:),
                          @selector(boomerangDataTaskWithRequest:completionHandler:));
    
    //
    // uploadTaskWithRequest: variants
    //
    swizzleInstanceMethod([NSURLSession class],
                          @selector(uploadTaskWithRequest:fromFile:),
                          @selector(boomerangUploadTaskWithRequest:fromFile:));
    
    swizzleInstanceMethod([NSURLSession class],
                          @selector(uploadTaskWithRequest:fromFile:completionHandler:),
                          @selector(boomerangUploadTaskWithRequest:fromFile:completionHandler:));

    swizzleInstanceMethod([NSURLSession class],
                          @selector(uploadTaskWithRequest:fromData:),
                          @selector(boomerangUploadTaskWithRequest:fromData:));
    
    swizzleInstanceMethod([NSURLSession class],
                          @selector(uploadTaskWithRequest:fromData:completionHandler:),
                          @selector(boomerangUploadTaskWithRequest:fromData:completionHandler:));
    
    //
    // uploadTaskWithStreamedRequest:
    //
    swizzleInstanceMethod([NSURLSession class],
                          @selector(uploadTaskWithStreamedRequest:),
                          @selector(boomerangUploadTaskWithStreamedRequest:));
    
    //
    // downloadTaskWithRequest: variants (also handles downloadTaskWithURL)
    //
    swizzleInstanceMethod([NSURLSession class],
                          @selector(downloadTaskWithRequest:),
                          @selector(boomerangDownloadTaskWithRequest:));
    
    swizzleInstanceMethod([NSURLSession class],
                          @selector(downloadTaskWithRequest:completionHandler:),
                          @selector(boomerangDownloadTaskWithRequest:completionHandler:));

    //
    // downloadTaskWithResumeData: variants
    //
    swizzleInstanceMethod([NSURLSession class],
                          @selector(downloadTaskWithResumeData:),
                          @selector(boomerangDownloadTaskWithResumeData:));
    
    swizzleInstanceMethod([NSURLSession class],
                          @selector(downloadTaskWithResumeData:completionHandler:),
                          @selector(boomerangDownloadTaskWithResumeData:completionHandler:));
    
    // initialize our beacons array
    m_beacons = [[NSMutableDictionary alloc] init];
    m_beacons_lock = [[NSLock alloc] init];
    
    // Process all delegate classes
    int numClasses = objc_getClassList(NULL, 0);
    Class classes[numClasses];
    objc_getClassList(classes, numClasses);
    
    // Iterate through all the classes and process the ones that conform to NSURLSessionTaskDelegate protocol.
    for (int i=0; i<numClasses; i++)
    {
      Class klass = classes[i];
      NSString* classname = [NSString stringWithUTF8String:object_getClassName(klass)];
      
      if(class_conformsToProtocol(klass,@protocol(NSURLSessionTaskDelegate)))
      {
        MPLogDebug(@"Found %@ <NSURLSessionTaskDelegate>", classname);
        [self processDelegate:klass];
      }
    }
  }
  
  return self;
}

/**
 * Swizzles the delegates for the class
 * @param klass Class
 */
-(void)processDelegate:(Class)klass
{
  @synchronized(syncLockObject)
  {
    if(!class_respondsToSelector(klass, @selector(boomerangURLSession:task:didCompleteWithError:)))
    {
      // URLSession:task:didCompleteWithError:
      swizzleDelegate(klass,
                      @selector(URLSession:task:didCompleteWithError:),
                      @selector(boomerangURLSession:task:didCompleteWithError:),
                      (IMP) URLSession_task_didCompleteWithError,
                      (IMP) boomerangURLSession_task_didCompleteWithError);
    }
  }
}

/**
 * Placeholder for URLSession:task:didCompleteWithError: (doesn't run)
 */
void URLSession_task_didCompleteWithError(id self,
                                          SEL _cmd,
                                          NSURLSession* session,
                                          NSURLSessionTask* task,
                                          NSError* error)
{
}

/**
 * Swizzled interceptor for URLSession:task:didCompleteWithError:
 */
void boomerangURLSession_task_didCompleteWithError(id self,
                                                   SEL _cmd,
                                                   NSURLSession* session,
                                                   NSURLSessionTask* task,
                                                   NSError* error)
{
  @try
  {
    MPApiNetworkRequestBeacon *beacon = [[MPInterceptURLSessionDelegate sharedInstance] getBeaconForTask:task];
    
    if (beacon != nil)
    {
      // if we know about this beacon, call it complete
      [MPInterceptUtils parseResponse:beacon data:nil response:[task response] error:error];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangURLSession_task_didCompleteWithError() method. Exception %@, received: %@", [exception name], [exception reason]);
  }
  @finally
  {
    // call original delegate
    [self boomerangURLSession:session task:task didCompleteWithError:error];
  }
}

/**
 * Placeholder for boomerangURLSession:task:didCompleteWithError: (doesn't run)
 */
-(void) boomerangURLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
}

/**
 * Adds a beacon to the delegate's list
 * @param beacon Beacon to add
 * @param task NSURLSession task
 */
-(void)addBeacon:(MPApiNetworkRequestBeacon *)beacon forTask:(NSURLSessionTask *)task
{
  // The key is the address of the NSURLConnection
  NSString* key = [NSString stringWithFormat:@"%p", task];
  
  MPLogDebug(@"Adding beacon for task: %@", key);

  [m_beacons_lock lock];
  @try {
    [m_beacons setObject:beacon forKey:key];
  }
  @finally {
    [m_beacons_lock unlock];
  }
}

/**
 * Gets a beacon for the specified task
 * @param task NSURLSession task
 * @return Beacon
 */
-(MPApiNetworkRequestBeacon *)getBeaconForTask:(NSURLSessionTask *)task
{
  NSString* key = [NSString stringWithFormat:@"%p", task];
  
  [m_beacons_lock lock];
  @try {
    MPApiNetworkRequestBeacon* beacon = [m_beacons objectForKey:key];
    
    return beacon;
  }
  @finally {
    [m_beacons_lock unlock];
  }
}

@end
