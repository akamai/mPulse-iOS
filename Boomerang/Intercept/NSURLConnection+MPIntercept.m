//
//  NSURLConnection+MPIntercept.m
//  Boomerang
//
//  Created by Albert Hong on 11/29/12.
//  Copyright (c) 2012-2015 SOASTA. All rights reserved.
//

#import "NSURLConnection+MPIntercept.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPApiNetworkRequestBeacon.h"
#import "MPConfig.h"
#import "MPInterceptUtils.h"

@implementation NSURLConnection (MPIntercept)

+ (NSData *)boomerangSendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
  NSData *result;
  
  // The caller can technically pass in a null pointer for the error param, indicating that they
  // aren't interested in whether an error occurred.
  // We, on the other hand, *always* want to know, because it affecs what kind of beacon we send.
  // Because we can't rely on the caller's NSError** being valid, we create our own local variable.
  //
  // Caller can also pass in a null pointer for the response param.
  // Thus, we cannot rely on caller's NSURLResponse** being valid, we must create our own local variable.
  //
  NSError* localError;
  NSURLResponse* localResponse;
  
  @try
  {
    
    NSURL *url = [request URL];
    
    if (![MPInterceptUtils shouldIntercept:url])
    {
      return [self boomerangSendSynchronousRequest: request returningResponse:response error:error];
    }
    
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:url];
    result = [self boomerangSendSynchronousRequest: request returningResponse:&localResponse error:&localError];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)localResponse;
    
    // Did the HTTP request succeed?
    if (localError == nil)
    {
      if([httpResponse statusCode] < 400)
      {
        // The request succeeded.
        
        // Send a success beacon with the total # of response bytes.
        [beacon endRequestWithBytes:result.length];
      }
      else
      {
        MPLogDebug(@"boomerangSendSynchronousRequest HTTP Error : %li", (long)[httpResponse statusCode]);
        // Look for this connection in our timers
        [beacon setNetworkError:[httpResponse statusCode] errorMessage:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]];
      }
    }
    else
    {
      // The request failed.
      
      // Send a failure beacon with the error code.
      MPLogDebug(@"boomerangSendSynchronousRequest NetworkErrorCode : %ld",(long)[localError code]);
      [beacon setNetworkError:[localError code] errorMessage:[[localError userInfo] objectForKey:@"NSLocalizedDescription"]];
    }
    
    // Did the caller provide a valid "out pointer" for errors?
    if (error)
    {
      // The caller provided a valid pointer.
      *error = localError;
    }
    
    // Did the caller provide a valid "out pointer" for response?
    if (response)
    {
      // The caller provided a valid pointer.
      *response = localResponse;
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangSendSynchronousRequest:returningResponse:error: method. Exception %@, received: %@", [exception name], [exception reason]);
    
    // If result is not nil, exception happened after we made the "boomerangSendSynchronousRequest" method call.
    // In that case, simply assign the error/response values and return the result.
    if (result != nil)
    {
      // Did the caller provide a valid "out pointer" for errors?
      if (error)
      {
        // The caller provided a valid pointer.
        *error = localError;
      }
      
      // Did the caller provide a valid "out pointer" for response?
      if (response)
      {
        // The caller provided a valid pointer.
        *response = localResponse;
      }
      
      return result;
    }
    else
    {
      // Result was nil, so we hadn't gotten a chance to execute "boomerangSendSynchronousRequest" method call. Execute and return.
      return [self boomerangSendSynchronousRequest: request returningResponse:response error:error];
    }
  }

  return result;
}

+ (void) boomerangSendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
  @try
  {
    NSURL* url = [request URL];
    
    if (![MPInterceptUtils shouldIntercept:url])
    {
      return [self boomerangSendAsynchronousRequest:request queue:queue completionHandler:handler];
    }
    
    MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:url];
    
    // Create a new handler, adding our code
    [self boomerangSendAsynchronousRequest: request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
       @try
       {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         NSURL *url = [request URL];
         
         if (error == nil)
         {
           if ([httpResponse statusCode] < 400)
           {
             NSString *urlString = [[url absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
             MPLogDebug(@"boomerangSendAsynchronousRequest: urlString: %@", urlString);
             [beacon endRequestWithBytes:data.length];
           }
           else
           {
             MPLogDebug(@"boomerangSendAsynchronousRequest HTTP Error : %li", (long)[httpResponse statusCode]);
             [beacon setNetworkError:[httpResponse statusCode] errorMessage:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]];
           }
         }
         else
         {
           MPLogDebug(@"boomerangSendAsynchronousRequest failed! error code => %ld, error msg => %@", (long)[error code], [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
           [beacon setNetworkError:[error code] errorMessage:[[error userInfo] objectForKey:@"NSLocalizedDescription"]];
         }
       }
       @catch (NSException *exception)
       {
         MPLogError(@"Exception occured in boomerangSendAsynchronousRequest:queue:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
       }
       @finally
       {
         if (handler != nil)
         {
           // Must execute client's handler
           handler(response, data, error);
         }
       }
     }];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangSendAsynchronousRequest:queue:completionHandler: method. Exception %@, received: %@", [exception name], [exception reason]);
    return [self boomerangSendAsynchronousRequest:request queue:queue completionHandler:handler];
  }
  
  // TODO: sendAsynch request seems to call sendSynch request under the covers... we need to cancel that boomerang.
}

- (id)boomerangInitWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate
{
  @try
  {
    NSURL *url = [request URL];
    
    if ([MPInterceptUtils shouldIntercept:url])
    {
      // We should try and swizzle all input delegates. Sometimes they don't respond to NSURLConnectionDelegate
      // and thus we miss swizzling them during init.
      [[MPInterceptURLConnectionDelegate sharedInstance] processNonConformingDelegate:[delegate class]];
      
      MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:url];
      [[MPInterceptURLConnectionDelegate sharedInstance] addBeacon:beacon forKey:[NSString stringWithFormat:@"%p", self]];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangInitWithRequest:delegate: method. Exception %@, received: %@", [exception name], [exception reason]);
  }
  @finally
  {
    return [self boomerangInitWithRequest:request delegate:delegate];
  }
}

- (id)boomerangInitWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate  startImmediately:(BOOL)startImmediately
{
  @try
  {
    NSURL *url = [request URL];
    
    if ([MPInterceptUtils shouldIntercept:url])
    {
      // We should try and swizzle all input delegates. Sometimes they don't respond to NSURLConnectionDelegate
      // and thus we miss swizzling them during init.
      [[MPInterceptURLConnectionDelegate sharedInstance] processNonConformingDelegate:[delegate class]];
      
      MPApiNetworkRequestBeacon *beacon = [MPApiNetworkRequestBeacon initWithURL:url];
      [[MPInterceptURLConnectionDelegate sharedInstance] addBeacon:beacon forKey:[NSString stringWithFormat:@"%p", self]];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in boomerangInitWithRequest:delegate: method. Exception %@, received: %@", [exception name], [exception reason]);
  }
  @finally
  {
    return [self boomerangInitWithRequest:request delegate:delegate startImmediately:startImmediately];
  }
}

@end
