//
//  MPURLConnection.h
//  Boomerang
//
//  Created by Albert Hong on 11/2/12.
//  Copyright (c) 2012 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPURLConnection : NSObject<NSURLConnectionDataDelegate>
{
@private
  NSURLRequest *_request;
  NSURLConnection *_connection;
  NSURLResponse *_response;
  NSError *_error;
  NSMutableData *_responseData;
  NSCondition *_condition;
  BOOL _finished;
  BOOL _timedOut;
}

-(NSData *) sendSynchronousRequest:(NSURLRequest *) request response:(__strong NSURLResponse **)response error:(__strong NSError **)error timeout:(NSTimeInterval)timeout;
-(void) send:(NSDate *)timeoutDate;

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
-(void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;

@end
