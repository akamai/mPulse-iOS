//
//  MPulse.h
//  MPulse
//
//  Copyright (c) 2012-2016 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef MPulseActionCollectionBehavior_h
#define MPulseActionCollectionBehavior_h

/*!
 @enum MPulseActionCollectionBehavior
 @discussion Describes when an action beacon is supposed to be stopped and sent if not aborted.
 @constant MPulseActionCollectionBehaviorWaitForStop Keeps the action running until stopAction() has been called.
 @constant MPulseActionCollectionBehaviorOnTimeOut Will observe events(such as requests) after start of action and stop after a timeout has been reached after the last
 resource has finished.
 */
typedef NS_ENUM(NSUInteger, MPulseActionCollectionBehavior) {
  MPulseActionCollectionBehaviourWaitForStop = 1,
  MPulseActionCollectionBehaviourOnTimeOut = 2
};

#endif /* MPulseActionCollectionBehavior_h */

#ifndef MPulseConfigNetworkFilterOption_h
#define MPulseConfigNetworkFilterOption_h

/*!
 @enum MPulseNetworkRequestFilterOption
 @discussion Filter Options define what style of filter the beacon collector should apply to network requests.
 @constant MPulseNetworkRequestFilterOptionMatch If a filter matched on a network beacon the beacon will be collected otherwise discarded
 @constant MPulseNetworkRequestFilterOptionNone Will always drop network request beacon
 @constant MPulseNetworkRequestFilterOptionAll Unless a filter matches on a beacon, will always send network request beacon
 */
typedef NS_ENUM(NSUInteger, MPulseNetworkRequestFilterOption) {
  MPulseNetworkRequestFilterOptionMatch = 1,
  MPulseNetworkRequestFilterOptionNone = 2,
  MPulseNetworkRequestFilterOptionAll = 3
};

#endif /* MPulseConfigNetworkFilterOption_h */

#ifndef MPulseMetricTimerOptions_h
#define MPulseMetricTimerOptions_h

/**
 * Options for what to do with the Metric or Timer when it occurs during an Action.
 */
typedef NS_ENUM(NSUInteger, MPulseDataDuringAction) {
  
  /**
   * Sends the Custom Timer or Custom Metric as a full beacon.
   */
  MPulseDataDuringActionSendDirectBeacon = 1,
  
  /**
   * Include the Custom Timer or Custom Metric data on the Action beacon.
   *
   * (default)
   */
  MPulseDataDuringActionIncludeOnActionBeacon = 2
};

/**
 * Options for what to do if included on the Action Beacon and the same Metric or Timer
 * Name has already been set.
 */
typedef NS_ENUM(NSUInteger, MPulseDataOnDuplicate) {
  
  /**
   * Overwrite the previous Custom Timer or Custom Metric value.
   */
  MPulseDataOnDuplicateOverwrite = 1,
  
  /**
   * Ignore this new Custom Timer or Custom Metric.
   */
  MPulseDataOnDuplicateIgnore = 2,
  
  /**
   * Add the value of this new Custom Timer or Custom Metric to the previous one.
   */
  MPulseDataOnDuplicateSum = 3,
  
  /**
   * Sends the value of this new Custom Timer or Custom Metric as a direct beacon instead.
   *
   * (default)
   */
  MPulseDataOnDuplicateSendDirectBeacon = 4
};

/**
 * Custom Metric and Custom Timer Options.
 */
@interface MPulseMetricTimerOptions : NSObject

/**
 * What to do with the Metric or Timer when it occurs during an Action.
 */
@property (readwrite) MPulseDataDuringAction duringAction;

/**
 * If INCLUDE_ON_ACTION_BEACON is set, what to do if the same Metric or Timer
 * Name has already been set.
 */
@property (readwrite) MPulseDataOnDuplicate onActionDuplicate;

@end

#endif /* MPulseMetricTimerOptions_h */


#ifndef MPFilterResult_h
#define MPFilterResult_h

/*!
 * @brief Result Object describing the result of a filter run
 *
 * This Class describes the result of a filter being run and matching and assigning a ViewGroup if set.
 * Use this class to return state from your Filters.
 *
 * Example:
 * @code
 * MPFilter *filter = ^MPFilterResult* (NSString url) {
 *   MPFilterResult *result = [[MPFilterResult alloc] init];
 *   [result setMatched:YES];
 *   [result setViewGroup:@"ExampleViewGroup"];
 *   return result;
 * }
 * @endcode
 */
@interface MPFilterResult : NSObject

/**
  If a filter matched for the NetworkRequestBeacon passed into the filter, set this to YES.
 */
@property (readwrite) BOOL matched;

/**
  Name of the filter, used for debugging purposes internally
 */
@property (readwrite) NSString *filterName;

/**
  If set and filter matched, will change the filtered beacons viewgroup to the value set.
 */
@property (readwrite) NSString *viewGroup;

@end

#endif /* MPFilterResult_h */

#ifndef MPulseSettings_h
#define MPulseSettings_h

/*!
 Settings define the behavior and dimensions of an action being started.
 */
@interface MPulseSettings : NSObject

/**
  Enable network monitoring during the action runtime (ALL)
 */
-(void) enableNetworkMonitoring;

/**
  Enable filtered network monitoring during action runtime (MATCH)
 */
-(void) enableFilteredNetworkMonitoring;

/**
  Disable network monitoring during action runtime (NONE)
 */
-(void) disableNetworkMonitoring;

/**
  Configure the action collection behavior to use a activity-based timeout strategy for action collection
 */
-(void) timeoutToStop;

/**
  Configure the action collection behavior to wait for an explicit call to `[[MPulse sharedInstance] stopAction];`
 */
-(void) waitForStop;

/**
  Set the value for a custom dimension you wish to update when using this settings instance
 */
-(void) setCustomDimension:(NSString *)dimensionName toValue:(NSString *)value;

/**
  Returns `YES` if MPulseSettings-instance is configured to wait for an explicit stopAction method-call
 */
-(BOOL) shouldWaitForStop;

/**
  Returns `YES` if MPulseSettings-instance is configured to use activity-based strategy for ending actions
 */
-(BOOL) shouldTimeoutToStop;


/**
  Duration mPulse should wait after the last meaningful event before stopping an action
 */
@property (readwrite) NSNumber *actionTimeout;

/**
  Action Collection Behavior configuration flag, use convenience functions `shouldWaitForStop` and `shouldTimeoutToStop`
 */
@property (readwrite) MPulseActionCollectionBehavior *actionCollectionBehavior;

/**
  Describes the NetworkRequestFilter configuration for the duration of the Action.
  @see MPulseNetworkRequestFilterOption for a description of the values
 */
@property (readwrite) MPulseNetworkRequestFilterOption *filterOptions;

/**
  Used internaly to hold the FilterOption from before the start of the
  action and is used to reset the filters once an action has ended.
  @see MPulseNetworkRequestFilterOption for a description of the values
 */
@property (readonly)  MPulseNetworkRequestFilterOption *oldOption;

/**
  Name of the action
 */
@property (readwrite) NSString *actionName;

/**
  ViewGroup for an action
 */
@property (readwrite) NSString *viewGroup;

/**
  CustomDimensions to set on the action beacon
 */
@property (readwrite) NSMutableDictionary *customDimensions;

/**
  ABTest value to set on action beacon
 */
@property (readwrite) NSString *abTest;

/**
  Maximum resources per Action
 */
@property (readwrite) int maxActionResources;

@end
#endif /* MPulseSettings_h */


@interface MPulse : NSObject

// mPulse Build Number - 2.6.1
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
 * @brief Initializes mPulse with the specified API key. With a given configuration/
 *
 * This must be the first call made to the MPulse class and we recommend calling it from
 * the application's UIApplicationDelegate's method:
 * @code
 * - (void)applicationDidFinishLaunching:(UIApplication *)application;
 * @endcode
 *
 * Example Usage:
 * @code
 * MPulseSettings *settings = [[MPulseSettings alloc] init];
 * [settings setActionName:@"actionName"];
 * [settings setAbTest:@"abTest"];
 * [settings setViewGroup:@"viewGroup"];
 * [settings enableFilteredNetworkMonitoring];
 * [settings setCustomDimension:@"Dimension0" toValue:@"dim0"];
 * MPulse* mPulse = [MPulse initializeWithAPIKey:@"SDNF-ENLK-MXXC-TDNA"];
 * @endcode
 *
 * @param APIKey mPulse API key
 * @param settings mPulse Settings
 * @return mPulse instance
 */
+(MPulse *) initializeWithAPIKey:(NSString *)APIKey withSettings:(MPulseSettings *)settings;

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
 * @brief Sets maximum number of resources per Action
 *
 * Once set, the next Action will record only the passed in maximum number of resource entries.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] setMaxActionResources:10];
 * @endcode
 */
-(void) setMaxActionResources:(int)maxActionResources;

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
 * @param options Tell mPulse how to track the timer
 *
 * @return A TimerID string that will be used to stop the timer.
 */
-(NSString *) startTimer:(NSString *)timerName withOptions:(MPulseMetricTimerOptions *)options;


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
 * @param option Custom Metric and Timer Options
 */

-(void) sendTimer:(NSString *)timerName value:(NSTimeInterval)value withOptions:(MPulseMetricTimerOptions *)options;

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
 *
 */
-(void) sendMetric:(NSString *)metricName value:(NSNumber *)value withOptions:(MPulseMetricTimerOptions *)options;


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
 * Sets NetworkFilterOptions to ALL, clears all filters and consumes View Group configuration to setup new filters
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] enableNetworkMonitoring];
 * @endcode
 */
-(void) enableNetworkMonitoring;

/**
 * @brief Enable monitoring of only matching requests
 *
 * Sets NetworkFilterOptions to MATCH, clears all filters and consumes View Group configuration to setup new filters
 * 
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] enableFilteredNetworkMonitoring];
 * @endcode
 */
-(void) enableFilteredNetworkMonitoring;

#ifndef MPURLFilter_h
#define MPURLFilter_h
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
 *   if ([url isEqualToString:@"http://www.example.com/"])
 *   {
 *     NSLog(@"URL matched 'http://www.example.com/'");
 *    
 *     return YES;
 *   }
 * };
 * @endcode
 */
typedef MPFilterResult* (^MPURLFilter) (NSString *url);

#endif /* MPURLFilter_h */

/**
 * @brief Add new filter to user-defined blacklist
 *
 * User defined Blacklists are applied after View Group configuration based filters to your network requests. A filter defined
 * here will remove the applicable network requests from the group of beacons being sent to the mPulse Collectors.
 *
 * Filters defined here will not be cleared upon receiving a new Configuration from the server.
 *
 * We will only apply these filters if your current FilterOptions are set to ALL.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] addURLBlackListFilter:@"Example.com Filter" filter:^MPFilterResult (NSString *url) {
 *  MPFilterResult *result = [MPFilterResult alloc] init];
 *  if ([url isEqualToString:@"http://example.com"])
 *  {
 *    [result setMatched:YES];
 *
 *    // Optionally set the ViewGroup of the result
 *    [result setViewgroup:@"ExampleViewGroup"]
 *  }
 *
 *  return result;
 * }];
 * @endcode
 */
-(void) addURLBlackListFilter:(NSString *)name filter:(MPURLFilter)filter;

/**
 * @brief Add new filter to user-defined whitelist
 *
 * User defined Whitelists are applied after View Group configuration based filters to your network requests. A filter defined here
 * will keep the applicable NetworkRequestBecon and send it back to mPulse Collectors.
 *
 * Filters defined here will not be cleared upon receiving a new Configuration from the server.
 *
 * These filters will only be applied if your current FilterOptions is set to MATCH
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] addURLBlackListFilter:@"Example.com Filter" filter:^MPFilterResult* (NSString *url) {
 *  MPFilterResult *result = [MPFilterResult alloc] init];
 *  if ([url isEqualToString:@"http://example.com"])
 *  {
 *    [result setMatched:YES];
 *
 *    // Optionally set the ViewGroup of the result
 *    [result setViewgroup:@"ExampleViewGroup"];
 *  }
 *
 *  return result;
 * }];
 * @endcode
 */
-(void) addURLWhiteListFilter:(NSString *)name filter:(MPURLFilter)filter;

/**
 * @brief Add a new filter to user-defined viewGroup filter list, this list will apply a viewGroup to the network request beacon
 *
 * A programmaticly defined viewGroup is applied to beacon if the MPFilterResult from the MPFURLFilter passed in returned a
 * valid NSString that is neither empty or nil.
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] addViewGroupURLFilter:@"ViewGroupFilter" filter:^MPFilterResult* (NSString *url) {
 *   MPFilterResult *result = [MPFilterResult alloc] init];
 *   if ([url isEqualToString:@"http://example.com")
 *   {
 *     [result setViewGroup:@""];
 *   }
 *
 *   return result;
 * }];
 * @endcode
 */
-(void) addURLViewGroupFilter:(NSString *)name filter:(MPURLFilter)filter;

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

/**
 * @brief Clear all View Group filters
 *
 * Example Usage:
 * @code
 * [[MPulse sharedInstance] clearViewGroupFilters];
 * @endcode
 */
-(void) clearViewGroupFilters;

/**
 * @brief Start an Action with default settings
 *
 * This action will have no custom dimensions changed, the default action collection behavior
 * and use the pre-configured dimensions.
 *
 * Example:
 * @code
 * // At some point:
 * [[MPulse sharedInstance] startAction];
 * // Later ...
 * [[MPulse sharedInstance] stopAction];
 * @endcode
 */
-(void) startAction;

/**
 * @brief Start an Action and use passed in settings
 *
 * All configuration items set in the settings instance will be configured for the runtime of the
 * action and will define the dimensions of the action.
 *
 * Example:
 * @code
 * MPulseSettings *settings = [[MPulseSettings alloc] init];
 * // Tell MPulse to enable filtered Network Monitoring during the action run-time
 * [settings enableFilteredNetworkMonitoring];
 * // Setup a filter:
 * MPFilter filter = MPFilterResult* ^(NSString* url) {
 *   MPFilterResult *result = [[MPFilterResult alloc] init];
 *   if (url != nil && [url containsString:@"abc"])
 *   {
 *      [result setMatched:YES];
 *   }
 *   return result;
 * };
 * NSMutableDictionary *filters = [[NSMutableDictionary alloc] init];
 *
 * // Pass collection of filters to settings
 * [filters setObject:filter forKey:@"MyFilter"];
 * [settings setWhitelistFilters:filters];
 *
 * // Configure a customDimension for the Action Beacon:
 * [settings setCustomDimension:@"dimensionname" value:@"value"];
 *
 * // Start the action
 * [[MPulse sharedInstance] startActionWithSettings:settings];
 * @endcode
 * @param settings The MPulseSettings instance configuring the action
 */
-(void) startActionWithSettings:(MPulseSettings *)settings;

/**
 * @brief Start an action with default settings but a unique ActionName.
 *
 * This will use the preconfigured action collection behavior, action timeout
 * and dimensions but will set a unique action name.
 *
 * Example:
 * @code
 * // Start an action with unique name:
 * [[MPulse sharedInstance] startActionWithName:@"MyActionName"];
 * [[MPulse sharedInstance] stopAction];
 * // Action beacon will be sent with unique name...
 * @endcode
 * @param name The name of the action
 */
-(void) startActionWithName:(NSString *)name;

/**
 * @brief stops an action explicitly.
 *
 * This will stop an action and send the action beacon with the observed
 * finished and unfinished requests occuring at that moment.
 * Note that this will not flag the beacon as aborted.
 *
 * Example:
 * @code
 * // At some point called [[MPulse sharedInstance] startAction]... now stopping:
 * [[MPulse sharedInstance] stopAction];
 * @endcode
 */
-(void) stopAction;

/**
 * @brief Update MPulse configuration and dimensions using a settings instance
 *
 * Pass the settings instance with a pre-defined configuration in to update
 * the mPulse instance default values.
 *
 * Example:
 * @code
 * MPulseSettings *settings = [[MPulseSettings alloc] init];
 * // Tell MPulse to enable filtered Network Monitoring during the action run-time
 * [settings disableNetworkMonitoring];
 * [settings setCustomDimension:@"dimensionname" value:@"value"];
 * [[MPulse sharedInstance] updateSettings:settings];
 * @endcode
 */
-(void) updateSettings:(MPulseSettings *)settings;

/**
 * @brief Set the default Action Timeout in ms for Actions
 *
 * Action timeouts control how long an mPulse will wait while
 * no request is inflight before it may stop an action automatically if configured
 * to timeout after requests.
 *
 * @code
 * [[MPulse sharedInstance] setActionTimeout:1000];
 * @endcode
 */
-(void) setActionTimeout:(int) timeoutMs;

/**
 * @brief Set the maximum number of resources allowed to be recorded per beacon in an Action
 *
 * Increasing this value may result in additional memory consumption.
 * The maximum value for this configuration is a value of 1000.
 *
 * Example:
 * @code
 * [[MPulse sharedInstance] setActionMaxResources:400];
 * @endcode
 */
-(void) setActionMaxResources:(int) maxResources;

/**
 * Enable debug logging.
 *
 * @param debug Whether or not to enable debug logging.
 */
+(void) setDebug:(bool)debug;

@end
