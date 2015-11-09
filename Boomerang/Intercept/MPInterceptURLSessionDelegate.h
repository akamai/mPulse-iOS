//
//  MPInterceptURLSessionDelegate.h
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPNetworkCallBeacon.h"

@interface MPInterceptURLSessionDelegate : NSObject
{
  // beacons we're keeping track of for NSURLSessionTaskDelegate
  NSMutableDictionary *m_beacons;
}

/**
 * Shared instance of the MPInterceptURLSessionDelegate
 * @return Shared instance
 */
+(MPInterceptURLSessionDelegate*) sharedInstance;

/**
 * Adds a beacon to the delegate's list
 * @param beacon Beacon to add
 * @param task NSURLSession task
 */
-(void)addBeacon:(MPNetworkCallBeacon *)beacon forTask:(NSURLSessionTask *)task;

@end
