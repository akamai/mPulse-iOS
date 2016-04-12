//
//  NSURLSession+MPIntercept.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//
// For the following selectors, iOS internally translates all calls to dataTaskWithRequest
// with the specified URL.  This will eventually come back to our dataTaskWithRequest swizzle.
// If we were swizzling the following methods as well, the later dataTaskWithRequest would
// trigger another beacon being tracked, so we don't swizzle them:
//
// * dataTaskWithURL:
// * dataTaskWithURL:completionHandler:
// * dataTaskWithHTTPGetRequest:
// * dataTaskWithHTTPGetRequest:completionHandler
//
// Similarly, downloadTaskWithURL calls downloadTaskWithRequest so we just swizzle downloadTaskWithRequest.
//
// Here's the full list of NSURLSession functions and how we are, or aren't able to monitor them:
// dataTaskWithRequest:                               We send to dataTaskWithRequest:completionHandler:
// dataTaskWithRequest:completionHandler:             Handled
// dataTaskWithURL:                                   iOS calls dataTaskWithRequest:
// dataTaskWithURL:completionHandler:                 iOS calls dataTaskWithRequest:completionHandler:
// dataTaskWithHTTPGetRequest:                        iOS calls dataTaskWithRequest:
// dataTaskWithHTTPGetRequest:completionHandler       iOS calls dataTaskWithRequest:completionHandler:
// uploadTaskWithRequest:fromFile:                    We send to uploadTaskWithRequest:fromFile:completionHandler:
// uploadTaskWithRequest:fromFile:completionHandler:  Handled
// uploadTaskWithRequest:fromData:                    We send to uploadTaskWithRequest:fromData:completionHandler:
// uploadTaskWithRequest:fromData:completionHandler:  Handled
// uploadTaskWithStreamedRequest:                     Handled
// downloadTaskWithRequest:                           We send to downloadTaskWithRequest:completionHandler
// downloadTaskWithRequest:completionHandler:         Handled
// downloadTaskWithURL:                               iOS calls downloadTaskWithRequest:
// downloadTaskWithURL:completionHandler:             iOS calls downloadTaskWithRequest:completionHandler
// downloadTaskWithResumeData:                        We send to downloadTaskWithResumeData:completionHandler:
// downloadTaskWithResumeData:completionHandler:      Handled
//
// There are no tests for the following in MPHttpRequestTests because XCode 6 / iOS 9 removes the selectors
// completely, so using those tests causes compile errors.  These selectors still are "tested" in iOS <= 8
// because iOS internally passes the calls to dataTaskWithRequest:
// dataTaskWithHTTPGetRequest:
// dataTaskWithHTTPGetRequest:completionHandler
//

#import <Foundation/Foundation.h>

#import "NSURLSession+MPIntercept.h"
#import "MPInterceptURLSessionDelegate.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPConfig.h"
#import "MPInterceptUtils.h"

@implementation NSURLSession (MPIntercept)

//
// dataTaskWithRequest:
//
- (NSURLSessionDataTask *)boomerangDataTaskWithRequest:(NSURLRequest *)request
{
  // convert to a nil completionHandler
  return [self dataTaskWithRequest:request completionHandler:nil];
}

//
// dataTaskWithRequest:completionHandler:
//
- (NSURLSessionDataTask *)boomerangDataTaskWithRequest:(NSURLRequest *)request
                                     completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
  NSURLSessionDataTask *task = nil;
  @try
  {
    // ensure we want to track this URL first
    if (![MPInterceptUtils shouldIntercept:[request URL]])
    {
      // send to the un-swizzled method with whatever completion handler was given
      return [self boomerangDataTaskWithRequest:request completionHandler:completionHandler];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:[request URL]];
    
    if (self.delegate != nil && completionHandler == nil)
    {
      //
      // If the caller has specified a delegate, a completionHandler should not be specified (as
      // the delegate methods won't be called).  Rely on our swizzled delegate to detect when
      // the request is complete.
      //
      task = [self boomerangDataTaskWithRequest:request completionHandler:nil];

      // ensure we track this beacon for the delegate
      [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
    }
    else
    {
      //
      // If the caller has not specified a delegate, we can use an inline completionHandler block.
      //
      task = [self boomerangDataTaskWithRequest:request
                              completionHandler:^void(NSData* data, NSURLResponse *response, NSError *error)
      {
        @try
        {
          // the task is complete, parse the beacon
          [MPInterceptUtils parseResponse:beacon data:data response:response error:error];
        }
        @catch (NSException *exception)
        {
          MPLogError(@"Exception occured in boomerangDataTaskWithRequest:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
        }
        @finally
        {
          // call back the completionHandler if specified
          if (completionHandler != nil)
          {
            completionHandler(data, response, error);
          }
        }
      }];
    }
    
    return task;
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangDataTaskWithRequest:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangDataTaskWithRequest:request completionHandler:completionHandler];
    }
  }
}

//
// uploadTaskWithRequest:fromFile:
//
- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromFile:(NSURL *)fileURL
{
  // convert to a nil completionHandler
  return [self uploadTaskWithRequest:request fromFile:fileURL completionHandler:nil];
}

//
// uploadTaskWithRequest:fromFile:completionHandler:
//
- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromFile:(NSURL *)fileURL
                                         completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
  NSURLSessionUploadTask *task = nil;
  @try
  {
    // ensure we want to track this URL first
    if (![MPInterceptUtils shouldIntercept:[request URL]])
    {
      return [self boomerangUploadTaskWithRequest:request
                                         fromFile:fileURL
                                completionHandler:completionHandler];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:[request URL]];

    if (self.delegate != nil && completionHandler == nil)
    {
      //
      // If the caller has specified a delegate, a completionHandler should not be specified (as
      // the delegate methods won't be called).  Rely on our swizzled delegate to detect when
      // the request is complete.
      //
      task = [self boomerangUploadTaskWithRequest:request fromFile:fileURL completionHandler:nil];

      // ensure we track this beacon for the delegate
      [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
    }
    else
    {
      //
      // If the caller has not specified a delegate, we can use an inline completionHandler block.
      //
      task = [self boomerangUploadTaskWithRequest:request
                                         fromFile:fileURL
                                completionHandler:^void(NSData* data, NSURLResponse *response, NSError *error)
      {
        @try
        {
          // the task is complete, parse the beacon
          [MPInterceptUtils parseResponse:beacon data:data response:response error:error];
        }
        @catch (NSException *exception)
        {
        MPLogError(@"Exception occured in boomerangUploadTaskWithRequest:fromFile:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
        }
        @finally
        {
          // call back the completionHandler if specified
          if (completionHandler != nil)
          {
            completionHandler(data, response, error);
          }
        }
      }];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangUploadTaskWithRequest:fromFile:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangUploadTaskWithRequest:request
                                         fromFile:fileURL
                                completionHandler:completionHandler];
    }
  }

  return task;
}

//
// uploadTaskWithRequest:fromData:
//
- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromData:(NSData *)data
{
  // convert to a nil completionHandler
  return [self uploadTaskWithRequest:request fromData:data completionHandler:nil];
}

//
// uploadTaskWithRequest:fromData:completionHandler:
//
- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromData:(NSData *)data
                                         completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler
{
  NSURLSessionUploadTask *task = nil;
  @try
  {
    // ensure we want to track this URL first
    if (![MPInterceptUtils shouldIntercept:[request URL]])
    {
      return [self boomerangUploadTaskWithRequest:request
                                         fromData:data
                                completionHandler:completionHandler];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:[request URL]];

    if (self.delegate != nil && completionHandler == nil)
    {
      //
      // If the caller has specified a delegate, a completionHandler should not be specified (as
      // the delegate methods won't be called).  Rely on our swizzled delegate to detect when
      // the request is complete.
      //
      task = [self boomerangUploadTaskWithRequest:request fromData:data completionHandler:completionHandler];

      // ensure we track this beacon for the delegate
      [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
    }
    else
    {
      //
      // If the caller has not specified a delegate, we can use an inline completionHandler block.
      //
      task = [self boomerangUploadTaskWithRequest:request
                                         fromData:data
                                completionHandler:^void(NSData* data, NSURLResponse *response, NSError *error)
      {
        @try
        {
          // the task is complete, parse the beacon
          [MPInterceptUtils parseResponse:beacon data:data response:response error:error];
        }
        @catch (NSException *exception)
        {
          MPLogError(@"Exception occured in boomerangUploadTaskWithRequest:fromData:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
        }
        @finally
        {
          // call back the completionHandler if specified
          if (completionHandler != nil)
          {
            completionHandler(data, response, error);
          }
        }
      }];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangUploadTaskWithRequest:fromData:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangUploadTaskWithRequest:request
                                         fromData:data
                                completionHandler:completionHandler];
    }
  }

  return task;
}

//
// uploadTaskWithStreamedRequest:
//
- (NSURLSessionUploadTask *)boomerangUploadTaskWithStreamedRequest:(NSURLRequest *)request
{
  NSURLSessionUploadTask *task = nil;
  @try
  {
    // ensure we want to track this URL first
    if (![MPInterceptUtils shouldIntercept:[request URL]])
    {
      return [self boomerangUploadTaskWithStreamedRequest:request];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:[request URL]];
    
    task = [self boomerangUploadTaskWithStreamedRequest:request];
    
    [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangUploadTaskWithStreamedRequest: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangUploadTaskWithStreamedRequest:request];
    }
  }

  return task;
}

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithRequest:(NSURLRequest *)request
{
  // convert to a nil completionHandler
  return [self downloadTaskWithRequest:request completionHandler:nil];
}

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithRequest:(NSURLRequest *)request
                                             completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
  NSURLSessionDownloadTask *task = nil;
  @try
  {
    // ensure we want to track this URL first
    if (![MPInterceptUtils shouldIntercept:[request URL]])
    {
      return [self boomerangDownloadTaskWithRequest:request completionHandler:completionHandler];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:[request URL]];

    if (self.delegate != nil && completionHandler == nil)
    {
      //
      // If the caller has specified a delegate, a completionHandler should not be specified (as
      // the delegate methods won't be called).  Rely on our swizzled delegate to detect when
      // the request is complete.
      //
      task = [self boomerangDownloadTaskWithRequest:request completionHandler:completionHandler];

      // ensure we track this beacon for the delegate
      [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
    }
    else
    {
      //
      // If the caller has not specified a delegate, we can use an inline completionHandler block.
      //
      task = [self boomerangDownloadTaskWithRequest:request
                                  completionHandler:^void(NSURL *location, NSURLResponse *response, NSError *error)
      {
        @try
        {
          // the task is complete, parse the beacon
          [MPInterceptUtils parseResponse:beacon data:nil response:response error:error];
        }
        @catch (NSException *exception)
        {
          MPLogError(@"Exception occured in boomerangDownloadTaskWithRequest:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
        }
        @finally
        {
          // call back the completionHandler if specified
          if (completionHandler != nil)
          {
            completionHandler(location, response, error);
          }
        }
      }];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangDownloadTaskWithRequest:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangDownloadTaskWithRequest:request completionHandler:completionHandler];
    }
  }

  return task;
}

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithResumeData:(NSData *)resumeData
{
  // convert to a nil completionHandler
  return [self downloadTaskWithResumeData:resumeData completionHandler:nil];
}

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithResumeData:(NSData *)resumeData
                                                completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler
{
  NSURLSessionDownloadTask *task;
  @try
  {
    NSURL* url = [self getUrlFromResumeData:resumeData];
    
    // ensure we want to track this URL first
    if (url == nil || ![MPInterceptUtils shouldIntercept:url])
    {
      return [self boomerangDownloadTaskWithResumeData:resumeData completionHandler:completionHandler];
    }
    
    // create a beacon to track
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:url];
    
    if (self.delegate != nil && completionHandler == nil)
    {
      //
      // If the caller has specified a delegate, a completionHandler should not be specified (as
      // the delegate methods won't be called).  Rely on our swizzled delegate to detect when
      // the request is complete.
      //
      task = [self boomerangDownloadTaskWithResumeData:resumeData completionHandler:completionHandler];

      // ensure we track this beacon for the delegate
      [[MPInterceptURLSessionDelegate sharedInstance] addBeacon:beacon forTask:task];
    }
    else
    {
      //
      // If the caller has not specified a delegate, we can use an inline completionHandler block.
      //
      task = [self boomerangDownloadTaskWithResumeData:resumeData
                                     completionHandler:^void(NSURL *location, NSURLResponse *response, NSError *error)
      {
        @try
        {
          // the task is complete, parse the beacon
          [MPInterceptUtils parseResponse:beacon data:nil response:response error:error];
        }
        @catch (NSException *exception)
        {
          MPLogError(@"Exception occured in boomerangDownloadTaskWithResumeData:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
        }
        @finally
        {
          // call back the completionHandler if specified
          if (completionHandler != nil)
          {
            completionHandler(location, response, error);
          }
        }
      }];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangDownloadTaskWithResumeData:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    if (task == nil)
    {
      return [self boomerangDownloadTaskWithResumeData:resumeData completionHandler:completionHandler];
    }
  }

  return task;
}

/**
 * Gets the URL from a resumeData object.
 *
 * Idea take from:
 * http://stackoverflow.com/questions/21895853/how-can-i-check-that-an-nsdata-blob-is-valid-as-resumedata-for-an-nsurlsessiondo
 *
 * @param data resumeData object
 * @return URL, or nil if the URL can't be determined
 */
- (NSURL *)getUrlFromResumeData:(NSData *)data
{
  if (!data || [data length] < 1)
  {
    return nil;
  }
  
  NSError *error;
  NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data
                                                                             options:NSPropertyListImmutable
                                                                              format:NULL
                                                                               error:&error];
  if (!resumeDictionary || error)
  {
    return nil;
  }
  
  NSString *url = [resumeDictionary objectForKey:@"NSURLSessionDownloadURL"];
  if (!url || [url length] < 1)
  {
    return nil;
  }
  
  return [NSURL URLWithString:url];
}

@end
