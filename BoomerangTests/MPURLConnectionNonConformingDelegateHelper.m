//
//  MPURLConnectionNonConformingDelegateHelper.m
//  Boomerang
//
//  Created by Nicholas Jansma on 5/4/16.
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import "MPURLConnectionNonConformingDelegateHelper.h"

@implementation MPURLConnectionNonConformingDelegateHelper
{
  @private
  NSURLRequest *_request;
  NSCondition *_condition;
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate methods

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  MPLogDebug(@"Request failed. %@", error);
  
  _error = error;
  
  [self signal];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  MPLogDebug(@"CALLING DIDRECEIVERESPONSE");
  _response = response;
  _responseData = [NSMutableData alloc];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  MPLogDebug(@"CALLING DIDRECEIVEDATA");
  _finished = NO;
  [_responseData appendData:data];
}

-(void) connectionDidFinishLoading:(NSURLConnection *)connection
{
  MPLogDebug(@"%s", __FUNCTION__);
  
  [self signal];
}

-(void) connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  MPLogDebug(@"%s", __FUNCTION__);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
  MPLogDebug(@"%s", __FUNCTION__);
  return nil;
}

#pragma mark -

-(void) signal
{
  MPLogDebug(@"%s", __FUNCTION__);
  
  _finished = YES;
  
  [_condition lock];
  [_condition signal];
  [_condition unlock];
}

@end
