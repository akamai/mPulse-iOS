//
//  MPSession.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/24/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPSession.h"
#import "MPConfig.h"
#import "MPAppFinishedLaunchingBeacon.h"
#import "MPNetworkCallBeacon.h"
#import "MPNetworkErrorBeaconGenerator.h"

@implementation MPSession

static MPSession *sessionInstance = NULL; // Singleton

// Singleton access
+(MPSession *) sharedInstance
{
  static dispatch_once_t _singletonPredicate;
  dispatch_once(&_singletonPredicate, ^{
    sessionInstance = [[super allocWithZone:nil] init];
    
    // MPConfig will notify us when configuration has been refreshed. We can start the session at that point.
    [[NSNotificationCenter defaultCenter] addObserver:sessionInstance selector:@selector(receiveBoomerangConfigRefreshedNotification:) name:BOOMERANG_CONFIG_REFRESHED object:nil];
  });
  
  return sessionInstance;
}

-(void) initWithSessionID:(NSString*) ID
{
  _ID = ID;
  _startTime = [NSDate date];
  _started = YES;

  MPLogDebug(@"Session %@ started at %@", _ID, _startTime);
}

-(void) receiveBoomerangConfigRefreshedNotification:(NSNotification *)notification
{
  // If the session has expired, reset network request duration and count.
  if (!_started || [self expired])
  {
    MPLogDebug(@"Session has expired. Resetting network request counts.");

    [self reset];
  }

  if (!_started)
  {
    NSString *sessionID = [[notification userInfo] objectForKey:SESSION_ID_KEY];
    if (sessionID)
    {
      [self initWithSessionID:sessionID];
      MPLogInfo(@"Boomerang session has started.");
      
      // App has finished launching, send the first beacon
      [MPAppFinishedLaunchingBeacon sendBeacon];
      
      // Start generating Network Error beacons
      [MPNetworkErrorBeaconGenerator startGenerator];
    }
  }
}

-(void) addBeacon:(MPBeacon*) beacon
{
  // Set last beacon timestamp
  _lastBeaconTime = beacon.timestamp;
  
  if ([beacon isKindOfClass:[MPNetworkCallBeacon class]])
  {
    // Convert to milliseconds.
    int durationMS = [beacon requestDuration] * 1000;
    
    _totalNetworkRequestCount += 1;
    _totalNetworkRequestDuration += durationMS;

    MPLogDebug(@"Session request count incremented to %d, total request time incremented to %d", _totalNetworkRequestCount, _totalNetworkRequestDuration);
  }
}

-(BOOL) expired
{
  NSTimeInterval sessionExpirationTime = [[MPConfig sharedInstance] sessionExpirationTime];
  return fabs([_lastBeaconTime timeIntervalSinceNow]) > sessionExpirationTime;
}

-(void) reset
{
  _totalNetworkRequestCount = 0;
  _totalNetworkRequestDuration = 0;
  _started = NO;
  
  MPLogDebug(@"Session %@ reset", _ID);
}

@end
