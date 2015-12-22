//
//  MPInterceptUtils.h
//  Boomerang_NoTTD
//
//  Created by Nicholas Jansma on 8/21/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPApiNetworkRequestBeacon.h"

@interface MPInterceptUtils : NSObject

void swizzleDelegate(Class klass, SEL methodName, SEL boomerangMethod, IMP swizzleMethod, IMP boomerangMethodSwizzle);
void swizzleInstanceMethod(Class c, SEL orig, SEL replace);
void swizzleClassMethod(Class c, SEL orig, SEL replace);

/**
 * Determines whether or not the URL should be intercepted
 *
 * @param url URL to check
 * @return True if the URL should be intercepted
 */
+ (BOOL) shouldIntercept:(NSURL*) url;

/**
 * Parses the result of a network call for a beacon
 *
 * @param beacon Beacon to put results into
 * @param data Data from network call
 * @param response Response from network call
 * @param error Error from network call
 */
+ (void)parseResponse:(MPApiNetworkRequestBeacon *)beacon
                 data:(NSData *)data
             response:(NSURLResponse *)response
                error:(NSError *)error;

@end