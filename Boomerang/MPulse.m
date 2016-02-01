//
//  MPulse.m
//  MPulse
//
//  Copyright (c) 2012-2015 SOASTA. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIViewController.h>

#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPURLConnection.h"
#import "MPUtilities.h"
#import "MPUIApplicationDelegateHelper.h"

#import "NSURLConnection+MPIntercept.h"
#import "NSURLSession+MPIntercept.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPInterceptURLSessionDelegate.h"
#import "MPApiCustomMetricBeacon.h"
#import "MPAppLaunchBeacon.h"
#import "MPAppInactiveBeacon.h"
#import "MPConfig.h"
#import "MPSession.h"
#import "MPGeoLocation.h"
#import "MPApiCustomTimerBeacon.h"
#import "MPConfigDimension.h"
#import "MPLog.h"
#import "MPASLLogger.h"
#import "MPTTYLogger.h"

@implementation MPulse
{
  // Dictionary to store Custom Timer instances
  NSMutableDictionary* _customTimerDictionary;
  NSString *_pageGroup;
  NSString *_abTest;
  NSMutableArray *_customDimensions;
  NSString *_viewGroup;
}

static NSString* const DEFAULT_MPULSE_SERVER_URL = @"https://c.go-mpulse.net/api/config.json";

NSString* const MPULSE_BUILD_VERSION_NUMBER = @"1.0.0";
dispatch_queue_t mpulse_async_queue = nil;

/**
 * Static initalizer, executed as soon as the class is loaded
 */
+ (void) load
{
  NSLog(@"SOASTA mPulse Mobile Build : %@", MPULSE_BUILD_VERSION_NUMBER);
  [MPulse private_initDriver];
  NSLog(@"SOASTA MPulse initialized.");
}

// SINGLETON
static MPulse *mPulseInstance = nil;

+(MPulse *) sharedInstance
{
  @synchronized(self)
  {
    if (mPulseInstance == nil)
    {
      mPulseInstance = [[MPulse alloc] init]; // Create a Dummy Instance
    }
  }
  
  return mPulseInstance;
}

+(MPulse *) initializeWithAPIKey:(NSString*) APIKey
{
  // There is no try/catch block around sharedInstance() call because we do not wish to return a null
  // object in any case (which could lead to an NPE in future). Instead, we are okay throwing an exception
  // at this point, which the user will notice right away.
  [MPulse sharedInstance];
  
  @try
  {
    return [MPulse initializeWithAPIKey:APIKey andServerURL:[NSURL URLWithString:DEFAULT_MPULSE_SERVER_URL]];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to initialize mPulse Mobile with API Key. Exception %@, received: %@", [exception name], [exception reason]);
  }
  
  return mPulseInstance;
}

+(MPulse *) initializeWithAPIKey:(NSString*) APIKey andServerURL:(NSURL*) serverURL
{
  // There is no try/catch block around sharedInstance() call because we do not wish to return a null
  // object in any case (which could lead to an NPE in future). Instead, we are okay throwing an exception
  // at this point, which the user will notice right away.
  [MPulse sharedInstance];
  
  @try
  {
    MPConfig* config = [MPConfig sharedInstance];
    [config setMPulseServerURL:serverURL];
    
    [mPulseInstance setAPIKey:APIKey];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to initialize mPulse Mobile with API Key. Exception %@, received: %@", [exception name], [exception reason]);
  }
  
  return mPulseInstance;
}

-(id) init
{
  _customTimerDictionary = [[NSMutableDictionary alloc] init];
  _pageGroup = @""; // Initialize to an empty string instead of nil
  
  NSMutableArray *emptyDimensions = [[NSMutableArray alloc] initWithCapacity:10];
  for (int d = 0; d < 10; d++)
  {
    [emptyDimensions addObject:@""];
  }
  _customDimensions = emptyDimensions;
  
  return self;
}

+ (void) private_initDriver
{
  // Dispatch once is important so we do not intialize twice
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mpulse_async_queue = dispatch_queue_create("com.soasta.mpulse.MPulse", DISPATCH_QUEUE_SERIAL);
    
    // Initialize the Singleton
    [MPulse sharedInstance];
    
    // Initialize logger
    [MPLog addLogger:[MPASLLogger sharedInstance]];
    [MPLog addLogger:[MPTTYLogger sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(notifyApplicationFinishedLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(notifyApplicationDidLoseFocus:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(notifyApplicationDidLoseFocus:) name:UIApplicationWillTerminateNotification object:nil];
  });
}

+ (void)notifyApplicationFinishedLaunching:(NSNotification *)notification
{
  @try
  {
    if (mPulseInstance == nil)
    {
      MPLogInfo(@"MPulse hasn't been initialized by user yet.");
      return;
    }
    
    MPLogDebug(@"App finished launching: Initializing MPulse");

    // Perform this work on a separate thread because we must not block the app by doing network requests.
    dispatch_async(mpulse_async_queue, ^{
      @try
      {
        // Intialization of MPInterceptURLConnectionDelegate
        [MPInterceptURLConnectionDelegate sharedInstance];
        
        // Intialization of MPInterceptURLConnectionDelegate
        [MPInterceptURLSessionDelegate sharedInstance];
        
        
        // Receive all notifications and respond appropriately - Handles app going into background/terminated/returning to foreground.
        [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance] selector:@selector(receiveAnyNotification:) name:nil object:nil];
      }
      @catch (NSException *exception)
      {
        MPLogError(@"Exception occured in notifyApplicationFinishedLaunching: method. Exception %@, received: %@", [exception name], [exception reason]);
      }
    });
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in notifyApplicationFinishedLaunching: method. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

+ (void)notifyApplicationDidLoseFocus:(NSNotification *)notification
{
  @try
  {
    if (mPulseInstance != nil)
    {
      [mPulseInstance cancelAllTimers];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in notifyApplicationDidLoseFocus: method. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

- (void)receiveAnyNotification:(NSNotification *)notification
{
  @try
  {
    // The notifications start after UIApplicationDidFinishLaunchingNotification, so
    // we do not get that notification here.
    
    NSString *notificationName = [notification name];
    // Notifications for app going into Background or being Terminated
    if ([notificationName isEqualToString:@"UIApplicationDidEnterBackgroundNotification"] || [notificationName isEqualToString:@"UIApplicationWillTerminateNotification"])
    {
      [MPAppInactiveBeacon sendBeacon];
      return;
    }
    
    // Notification for app returning to Foreground
    if ([notificationName isEqualToString:@"UIApplicationWillEnterForegroundNotification"])
    {
      [MPAppLaunchBeacon sendBeacon];
      return;
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Exception occured in receiveAnyNotification: method. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(BOOL) isInstanceInitialized
{
  return [[MPSession sharedInstance] started];
}

-(NSString *) getViewGroup
{
  return _viewGroup;
}

-(void) setViewGroup:(NSString *)viewGroup
{
  _viewGroup = viewGroup;
}

-(void) resetViewGroup
{
  _viewGroup = @"";
}

-(NSString *) getABTest
{
  return _abTest;
}

-(void) setABTest:(NSString *)abTest
{
  _abTest = abTest;
}

-(void) resetABTest
{
  _abTest = @"";
}

-(void) sendMetric:(NSString *)metricName value:(NSNumber *)value
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    [[MPApiCustomMetricBeacon alloc] initWithMetricName:metricName andValue:value];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to send metric. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(NSString *) startTimer:(NSString *)timerName
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return @""; // mPulse Instance is not ready for work.
    }
    
    MPApiCustomTimerBeacon *beacon = [[MPApiCustomTimerBeacon alloc] initAndStart:timerName];
    
    NSString *timerKey = [NSString stringWithFormat:@"%@-%@", timerName, [MPUtilities getUUID]];
    NSLog(@"TimerKey - %@", timerKey);
    [_customTimerDictionary setObject:beacon forKey:timerKey];
    
    return timerKey;
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to start Timer. Exception %@, received: %@", [exception name], [exception reason]);
  }
  
  return @"";
}

-(void) cancelTimer:(NSString *) timerID
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    // Since we are cancelling the timer, no need to send the beacon. Simply remove it from the dictionary.
    [_customTimerDictionary removeObjectForKey:timerID];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to cancel Timer. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

- (void) cancelAllTimers
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    // Since we are cancelling all timers, remove all timer beacons from the dictionary.
    [_customTimerDictionary removeAllObjects];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to cancel all Timers. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(void) stopTimer:(NSString *) timerID
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    MPApiCustomTimerBeacon *beacon = [_customTimerDictionary objectForKey:timerID];
    if (beacon != nil)
    {
      [beacon endTimer]; // End timer and send the beacon
      [_customTimerDictionary removeObjectForKey:timerID]; // Remove the beacon from dictionary
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to stop Timer. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(void) sendTimer:(NSString *)timerName value:(NSTimeInterval)value
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    [[MPApiCustomTimerBeacon alloc] initWithName:timerName andValue:value];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to send Timer. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(NSMutableArray *)customDimensions
{
  return _customDimensions;
}

-(void) setDimension:(NSString *)dimensionName value:(NSString *)value
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    MPConfigDimension *dimension = [self getDimensionFromConfig:dimensionName];
    if (dimension != nil)
    {
      [_customDimensions replaceObjectAtIndex:dimension.index withObject:value];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to set Dimension. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(void) resetDimension:(NSString *)dimensionName
{
  @try
  {
    if (![self isInstanceInitialized])
    {
      return; // mPulse Instance is not ready for work.
    }
    
    MPConfigDimension *dimension = [self getDimensionFromConfig:dimensionName];
    if (dimension != nil)
    {
      [_customDimensions replaceObjectAtIndex:dimension.index withObject:@""];
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to reset Dimension. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(MPConfigDimension*) getDimensionFromConfig:(NSString *)dimensionName
{
  MPConfig* config = [MPConfig sharedInstance];
  
  for (MPConfigDimension *dimension in [[config pageParamsConfig] dimensions])
  {
    if ([dimensionName isEqualToString:dimension.name] && dimension.index < 10)
    {
      return dimension;
    }
  }
  
  return nil;
}

-(void) enable
{
  @try
  {
    [[MPConfig sharedInstance] setUserEnabledBeacons:YES];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to enable mPulse Mobile. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(void) disable
{
  @try
  {
    [[MPConfig sharedInstance] setUserEnabledBeacons:NO];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to disable mPulse Mobile. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(NSString*) APIKey
{
  @try
  {
    return [[MPConfig sharedInstance] APIKey];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to get API Key. Exception %@, received: %@", [exception name], [exception reason]);
    return nil;
  }
}

-(void) setAPIKey:(NSString *)apiKey
{
  @try
  {
    @synchronized(self)
    {
      [MPSession sharedInstance]; // Initialize MPSession if called for the first time.
      
      MPConfig* config = [MPConfig sharedInstance];
      [config setAPIKey:apiKey];
      
      // Perform this work on a separate thread because we must not block the app by doing network requests.
      dispatch_async(mpulse_async_queue, ^{
        @try
        {
          // Rebuild Config URL so MPConfig could fetch configuration from the new Server.
          [config buildConfigRequestURL];
          [config refresh]; // Refresh config
        }
        @catch (NSException *exception)
        {
          MPLogError(@"Unable to force Config Refresh. Exception %@, received: %@", [exception name], [exception reason]);
        }
      });
    }
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to set API Key. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(NSURL*) serverURL
{
  @try
  {
    return [[MPConfig sharedInstance] mPulseServerURL];
  }
  @catch (NSException *exception)
  {
    MPLogError(@"Unable to get Server URL. Exception %@, received: %@", [exception name], [exception reason]);
  }
}

-(BOOL) generateNetworkErrors
{
  return [[MPConfig sharedInstance] generateNetworkErrors];
}

-(void) setGenerateNetworkErrors:(BOOL)generateNetworkErrors
{
  [[MPConfig sharedInstance] setGenerateNetworkErrors:generateNetworkErrors];
}

-(BOOL) isHUDEnabled
{
  return [[MPConfig sharedInstance] isHUDEnabled];
}

-(void) setIsHUDEnabled:(BOOL)isHUDEnabled
{
  [[MPConfig sharedInstance] setIsHUDEnabled:isHUDEnabled];
}

-(NSString*) HUDColor
{
  return [[MPConfig sharedInstance] HUDColor];
}

-(void) setHUDColor:(NSString *)HUDColor
{
  return [[MPConfig sharedInstance] setHUDColor:HUDColor];
}

-(NSTimeInterval) HUDDisplayDuration
{
  return [[MPConfig sharedInstance] HUDDisplayDuration];
}

-(void) setHUDDisplayDuration:(NSTimeInterval)HUDDisplayDuration
{
  [[MPConfig sharedInstance] setHUDDisplayDuration:HUDDisplayDuration];
}

@end

@implementation UIView (MPulse)

static char mPulseId_key;

-(void) setMPulseId:(NSString *)mPulseId
{
  objc_setAssociatedObject(self, &mPulseId_key, mPulseId, OBJC_ASSOCIATION_RETAIN);
}

-(NSString*) mPulseId
{
  return objc_getAssociatedObject(self, &mPulseId_key);
}

@end

