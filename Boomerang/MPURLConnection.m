//
//  MPURLConnection.m
//  Boomerang
//
//  Created by Albert Hong on 11/2/12.
//  Copyright (c) 2012 SOASTA. All rights reserved.
//

#import "MPURLConnection.h"

@implementation MPURLConnection

-(NSData *)sendSynchronousRequest:(NSURLRequest *) request response:(__strong NSURLResponse **)response error:(__strong NSError **)error timeout:(NSTimeInterval)timeout
{
  // This class (and method) are used to work around the lack of
  // decent timeout support in NSURLRequest and NSURLConnection.
  // Specifically, any timeout of less than 240 seconds is ignored.
  // See https://devforums.apple.com/thread/25282 for details.
  
  // Instead of relying on Cocoa, we issue the request in a background
  // thread, and then block until it completes (or until the timeout
  // is reached).
  
  // Spawning a new thread for each request may seem wasteful, but
  // this is in fact exactly what +[NSURLConnection sendSynchronousRequest]
  // does.
  
  // Another option might be to use Grand Central Dispatch, but I could
  // not get this to work correctly.  It does not seem to be compatible
  // with +[NSRunLoop runMode].
  _request = request;
  _finished = NO;
  _responseData = nil;
  _timedOut = NO;
  
  // Create the condition object that we will use to wait for the background
  // thread.
  _condition = [[NSCondition alloc] init];
  
  // Determine when we will time out.
  NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
  
  // Start the background thread.
  [NSThread detachNewThreadSelector:@selector(send:) toTarget:self withObject:timeoutDate];
  
  while (!_finished)
  {
    // Check the condition.
    [_condition lock];
    BOOL signalled = [_condition waitUntilDate:timeoutDate];
    [_condition unlock];
    
    // Did we get a signal?
    if (signalled)
    {
      // We got a signal.
      
      // Normally this means that the request completed.  But according to
      // the Apple documentation, we can also get "false positives", so we
      // check the "finished" flag as well.  See https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSCondition_class/Reference/Reference.html
      if (!_finished)
      {
        // This was a "false positive" signal.
        // Keep waiting.
        NSLog(@"Signaled before request is finished; will continue waiting.");
      }
    }
    else
    {
      // We did not get a signal.
      // This means that the wait timed out.
      
      NSLog(@"Request timed out.");
      
      [_connection cancel];
      _timedOut = YES;
      
      // Return the same error that +[NSURLConnection sendSynchronousRequest] does.
      _error = [NSError errorWithDomain:NSURLErrorDomain
                                   code:NSURLErrorTimedOut
                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                         @"The request timed out.", NSLocalizedDescriptionKey,
                                         [[_request URL] relativeString], NSURLErrorFailingURLStringErrorKey,
                                         nil]];
      
      break;
    }
  }
  
  if (response)
  {
    *response = _response;
  }
  
  if (error)
  {
    *error = _error;
  }
  
  return _responseData;
}

- (void)send:(NSDate *)timeoutDate
{
  @autoreleasepool
  {
    // Start the HTTP request.  This runs asynchronously.  We will get
    // notifications via the various delegate methods (see below).
    _connection = [NSURLConnection connectionWithRequest:_request delegate:self];
    
    // Loop until the request completes (or times out).
    while (!_finished && !_timedOut)
    {
      // Not finished yet.
      
      // Give the asynchronous HTTP request some time to work.
      
      // This will return if either:
      // (a) the HTTP request status changes in any way
      // (b) we time out.
      
      // If it happens because of (a), we still have to check
      // the _finished flag.  Status change does not mean complete :-).
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
    }
  }
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate methods

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  NSLog(@"Request failed. %@", error);
  
  _error = error;
  
  [self signal];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  _response = response;
  _responseData = [NSMutableData alloc];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [_responseData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
  //We are sure that we are working on HTTP and thats why we use this cast
  [self signal];
}

-(void) connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  return nil;
}

#pragma mark -

-(void) signal
{
  _finished = YES;
  
  [_condition lock];
  [_condition signal];
  [_condition unlock];
}

@end
