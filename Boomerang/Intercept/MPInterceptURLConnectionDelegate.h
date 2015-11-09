//
//  MPInterceptURLConnectionDelegate.h
//  Boomerang
//
//  Created by Tana Jackson on 4/2/13.
//  Copyright (c) 2013 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPNetworkCallBeacon.h"

@interface MPInterceptURLConnectionDelegate : NSObject
{
  NSMutableDictionary *m_beacons;
}

+(MPInterceptURLConnectionDelegate*) sharedInstance;
-(void)addBeacon:(MPNetworkCallBeacon *)value forKey:(NSString *)key;
-(MPNetworkCallBeacon *)getBeaconForKey:(NSString *)key;
-(void)processDelegate:(Class)klass;
-(void)processNonConformingDelegate:(Class)klass;

-(void) boomerangConnection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void) boomerangConnection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end
