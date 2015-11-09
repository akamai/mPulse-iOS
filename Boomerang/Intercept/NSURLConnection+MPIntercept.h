//
//  NSURLConnection+MPIntercept.h
//  Boomerang
//
//  Created by Albert Hong on 11/29/12.
//  Copyright (c) 2012 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (MPIntercept)

+ (NSData *) boomerangSendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;
+ (void) boomerangSendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;
- (id) boomerangInitWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate;
- (id) boomerangInitWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate startImmediately:(BOOL)startImmediately;


@end
