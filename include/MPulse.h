//
//  MPulse.h
//  MPulse
//
//  Copyright (c) 2012-2016 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPulse : NSObject

// mPulse Build Number - 2.3.1
extern NSString *const MPULSE_BUILD_VERSION_NUMBER;

/**
 * @brief Initializes mPulse with the specified API key.
 *
 * This must be the first call made to the MPulse class and we recommend calling it from
 * the application's UIApplicationDelegate's method:
 * @code
 * - (void)applicationDidFinishLaunching:(UIApplication *)application;
 * @endcode
 *
 * Example Usage:
 * @code
 * MPulse* mPulse = [MPulse initializeWithAPIKey:@"SDNF-ENLK-MXXC-TDNA"];
 * @endcode
 *
 * @param APIKey mPulse API key
 * @return mPulse instance
 */
+(MPulse *) initializeWithAPIKey:(NSString *)APIKey;

/**
 * @brief Gets the current mPulse instance.
 *
 * Users must call initializeWithAPIKey first in order to initialize the MPulse class instance.
 *
 * If not initialized first, sharedInstance will return nil;
 *
 * Example Usage:
 * @code
 * MPulse* mPulse = [MPulse sharedInstance];
 * @endcode
 *
 * @return MPulse class instance
 */+(MPulse *) sharedInstance;

/**
 * @brief Gets the current View Group.
 *
 * Example Usage:
 * @code
 * NSString *viewGroup = [[MPulse sharedInstance] getViewGroup];
 * @endcode
 *
 * @return The current View Group
 */
-(NSString *) getViewGroup;

/**
 * @brief Sets the current View Group.
 *
 * Once set, the View Group will be included on all future beacons.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] setViewGroup:@"ViewGroup1"];
 * @endcode
 *
 * @param viewGroup View Group to set
 */
-(void) setViewGroup:(NSString *)viewGroup;

/**
 * @brief Resets (clears) the current View Group.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] resetViewGroup];
 * @endcode
 */
-(void) resetViewGroup;

/**
 * @brief Enables the mPulse library.
 *
 * When enabled, the mPulse library will send beacons.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] enable];
 * @endcode
 */
-(void) enable;

/**
 * @brief Disables the mPulse library and stops sending beacons.
 *
 * Once disabled, the mPulse library will no longer send beacons.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] disable];
 * @endcode
 */
-(void) disable;

/**
 * @brief Starts a Custom Timer
 *
 * When called, this API will start the specified Custom Timer and will return a TimerID.
 *
 * The TimerID is later used to stop this timer.
 *
 * The current View Group, A/B Test and Custom Dimensions will be set
 * for this timer.
 *
 * Example Usage:
 * @code
 * NSString* timerID = [[MPulse sharedInstance] startTimer:@"CustomTimer"];
 * @endcode
 *
 * @param timerName Custom Timer name
 *
 * @return A TimerID string that will be used to stop the timer.
 */
-(NSString *) startTimer:(NSString *)timerName;

/**
 * @brief Cancels a Custom Timer
 *
 * Once cancelled, the timer is not sent to the server.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] cancelTimer:@"timerID"];
 * @endcode
 *
 * @param timerID The TimerID to cancel
 */
-(void) cancelTimer:(NSString *)timerID;

/**
 * @brief Stops a Custom Timer
 *
 * Stops a previously started Custom Timer specified by the timerID.
 *
 * Once stopped, a Custom Timer beacon will be sent to the server.
 *
 * The current View Group, A/B Test and Custom Dimensions will not be updated.
 *
 * Example Usage:
 * @code
 * NSString* timerID = [[MPulse sharedInstance] startTimer:@"CustomTimer"];
 * [[MPulse sharedInstance] stopTimer:timerID];
 * @endcode
 *
 * @param timerID TimerID
 */
-(void) stopTimer:(NSString *)timerID;

/**
 * @brief Stops a Custom Timer and updates its dimensions
 *
 * Stops a previously started Custom Timer specified by the timerID.
 *
 * Once stopped, a Custom Timer beacon will be sent to the server.
 *
 * If updateDimensions is true, he current View Group, A/B Test
 * and Custom Dimensions will be updated for this timer.
 *
 * Example Usage:
 * @code
 * NSString* timerID = [[MPulse sharedInstance] startTimer:@"CustomTimer"];
 * [[MPulse sharedInstance] stopTimer:timerID updateDimensions:true];
 * @endcode
 *
 * @param timerID TimerID
 * @param updateDimensions Whether or not to update dimensions
 */
-(void) stopTimer:(NSString *)timerID updateDimensions:(BOOL)updateDimensions;

/**
 * @brief Sends a Custom Timer with the specified name and value
 *
 * You can use this API to send a Custom Timer with the specified value, instead of
 * having the mPulse library track it for you using startTimer and endTimer.
 *
 * The value is a NSTimeInterval, so should be in seconds.milliseconds resolution.
 *
 * Once called, a Custom Timer beacon will be sent to the server.
 *
 * Example Usage:
 * @code
 * // send a 1.5 second timer
 * [[MPulse sharedInstance] sendTimer:@"CustomTimer" value:1.5];
 * @endcode
 *
 * @param timerName Custom Timer name
 * @param value Custom Timer value in seconds
 */

-(void) sendTimer:(NSString *)timerName value:(NSTimeInterval)value;

/**
 * @brief Sends a Custom Metric
 *
 * Once called, a Custom Metric beacon will be sent to the server with the
 * specified value.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] sendMetric:@"CustomMetric" value:23];
 * @endcode
 *
 * @param metricName Custom Metric name
 * @param value Custom Metric value
 */
-(void) sendMetric:(NSString *)metricName value:(NSNumber *)value;

/**
 * @brief Sets a Custom Dimension
 *
 * Once set, the Custom Dimension will be included on all future beacons.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] setDimension:@"CustomDimension" value:@"abc"];
 * @endcode
 *
 * @param dimensionName Custom Dimension name
 * @param value Custom Dimension value
 */
-(void) setDimension:(NSString *)dimensionName value:(NSString *)value;

/**
 * @brief Resets (clears) specified Custom Dimension
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] resetDimension:@"CustomDimension"];
 * @endcode
 *
 * @param dimensionName Custom Dimension name
 */
-(void) resetDimension:(NSString *)dimensionName;

/**
 * @brief Resets (clears) all Custom Dimensions
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] resetAllDimensions];
 * @endcode
 */
-(void) resetAllDimensions;

/**
 * @brief Get the current A/B test
 *
 * Example Usage:
 * @code
 * NSString *abTest = [[MPulse sharedInstance] getABTest];
 * @endcode
 *
 * @return The current A/B test
 */
-(NSString *) getABTest;

/**
 * @brief Sets the A/B test
 *
 * Once set, the A/B test will be included on all future beacons.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] setABTest:@"A"];
 * @endcode
 *
 * @param abTest The A/B test
 */
-(void) setABTest:(NSString *)abTest;

/**
 * @brief Resets (clears) the A/B test
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] resetABTest];
 * @endcode
 */
-(void) resetABTest;

/**
 * @brief Disable monitoring of all network requests
 * 
 * Sets NetworkFilterOptions to NONE, clears all filters and sets only one filter for blacklisting network requests
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] disableNetworkMonitoring];
 * @endcode
 */
-(void) disableNetworkMonitoring;

/**
 * @brief Enable monitoring of network requests
 *
 * Sets NetworkFilterOptions to ALL, clears all filters and consumes PageGroup configuration to setup new filters
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] enableNetworkMonitoring];
 * @endcode
 */
-(void) enableNetworkMonitoring;

#ifndef MPFilter_h
/**
 * @brief Inline method type to filter on Network Request URLs
 * 
 * Provides easy inlined method definition facility for new URL filters. Use this to black or whitelist beacons you
 * wish to keep or ignore as part of your sent beacons.
 *
 * Example Usage:
 * @code
 * MPURLFilter filter = ^BOOL (NSString *url) {
 *
 *   if (url == @"http://www.example.com/")
 *   {
 *     NSLog(@"URL matched 'http://www.example.com/'");
 *    
 *     return YES;
 *   }
 * };
 * @endcode
 */
typedef BOOL (^MPURLFilter) (NSString *url);

#endif /* MPFilter_h */

/**
 * @brief Add new filter to user-defined blacklist
 *
 * User defined Blacklists are applied after PageGroup configuration based filters to your network requests. A filter defined
 * here will remove the applicable network requests from the group of beacons being sent to the mPulse Collectors.
 *
 * Filters defined here will not be cleared upon receiving a new Configuration from the server.
 *
 * We will only apply these filters if your current FilterOptions are set to ALL.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] addURLBlackListFilter:@"Example.com Filter" filter:^BOOL (NSString *url) {
 *  if (url == @"http://example.com")
 *  {
 *    return YES;
 *  }
 *
 *  return NO;
 * }];
 * @endcode
 */
-(void) addURLBlackListFilter:(NSString *)name filter:(MPURLFilter)filter;

/**
 * @brief Add new filter to user-defined whitelist
 *
 * User defined Whitelists are applied after PageGroup configuration based filters to your network requests. A filter defined here
 * will keep the applicable NetworkRequestBecon and send it back to mPulse Collectors.
 *
 * Filters defined here will not be cleared upon receiving a new Configuration from the server.
 *
 * These filters will only be applied if your current FilterOptions is set to MATCH
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] addURLBlackListFilter:@"Example.com Filter" filter:^BOOL (NSString *url) {
 *  if (url == @"http://example.com")
 *  {
 *    return YES;
 *  }
 *
 *  return NO;
 * }];
 * @endcode
 */
-(void) addURLWhiteListFilter:(NSString *)name filter:(MPURLFilter)filter;

/**
 * @brief Clear all filters from whitelist
 *
 * All filters from whitelist are cleared and you are free to define new entries to the whitelist
 * 
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] clearWhiteListFilters];
 * @endcode
 */
-(void) clearWhiteListFilters;

/**
 * @brief Clear all filters from blacklist
 *
 * All filters from blacklist are cleared and you are free to define new entries to the blacklist
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] clearBlackListFilters];
 * @endcode
 */
-(void) clearBlackListFilters;

@end
