//
//  MPInterceptURLConnectionDelegate.h
//  Boomerang
//
//  Created by Tana Jackson on 4/2/13.
//  Copyright (c) 2013 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPApiNetworkRequestBeacon.h"

@interface MPInterceptURLConnectionDelegate : NSObject
{
  NSMutableDictionary *m_beacons;
  NSLock *m_beacons_lock;
}

+(MPInterceptURLConnectionDelegate*) sharedInstance;
-(void)addBeacon:(MPApiNetworkRequestBeacon *)value forKey:(NSString *)key;
-(MPApiNetworkRequestBeacon *)getBeaconForKey:(NSString *)key;
-(void)processDelegate:(Class)klass;
-(void)processNonConformingDelegate:(Class)klass;

-(void) boomerangConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void) boomerangConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end
