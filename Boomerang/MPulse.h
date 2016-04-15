//
//  MPulse.h
//  MPulse
//
//  Copyright (c) 2012-2016 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPulse : NSObject

// mPulse Build Number
extern NSString* const MPULSE_BUILD_VERSION_NUMBER;

/**
 * @name    InitializeWithAPIKey
 * @brief   Intializer for MPulse Instance which requires mPulse API Key.
 *
 * This API lets users initialize and obtain an MPulse class instance using mPulse API Key.
 * It must be the first call made to MPulse class and we recommend calling it from 
 * UIApplicationDelegate's method -
 * - (void)applicationDidFinishLaunching:(UIApplication *)application;
 *
 * Example Usage:
 * @code
 *    MPulse* mPulse = [MPulse initializeWithAPIKey:@"SDNF-ENLK-MXXC-TDNA"];
 * @endcode
 */
+(MPulse *) initializeWithAPIKey:(NSString*) APIKey;

/**
 * @name    SharedInstance
 * @brief   Method to obtain MPulse instance.
 *
 * This API provides an initialized MPulse instance to users.
 * Users must call sharedInstanceWithApiKey first in order to initialize the MPulse instance.
 * If not called, sharedInstance will return nil;
 *
 * Example Usage:
 * @code
 *    MPulse* mPulse = [MPulse sharedInstanceWithApiKey:@"SDNF-ENLK-MXXC-TDNA"];
 * @endcode
 */+(MPulse *) sharedInstance;

/**
 * @name    Get ViewGroup
 * @brief   Returns the current value of ViewGroup.
 *
 * This API lets users retreive the value of currently set view group value.
 *
 * Example Usage:
 * @code
 *    NSString *viewGroup = [[MPulse sharedInstance] getViewGroup];
 * @endcode
 */
-(NSString *) getViewGroup;

/**
 * @name    Set ViewGroup
 * @brief   Sets the value of ViewGroup.
 *
 * This API lets users set the value of ViewGroup which will be a part of all future beacons sent to server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] setViewGroup:@"ViewGroup1"];
 * @endcode
 */
-(void) setViewGroup:(NSString *)viewGroup;


/**
 * @name    Reset ViewGroup
 * @brief   Resets the currently set ViewGroup value.
 *
 * This API lets users reset the current set ViewGroup value.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] resetViewGroup];
 * @endcode
 */
-(void) resetViewGroup;

/**
 * @name    Enable MPulse
 * @brief   Enables MPulse and starts beacon processing.
 *
 * This API lets users enable MPulse when beacon processing is required.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] enable];
 * @endcode
 */
-(void) enable;

/**
 * @name    Disable MPulse
 * @brief   Disables MPulse and stops beacon processing.
 *
 * This API lets users disable MPulse when beacon processing is not required.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] disable];
 * @endcode
 */
-(void) disable;

/**
 * @name    Start Timer
 * @brief   Starts Timer and returns the Timer ID.
 *
 * This API lets users start a Timer specified by timerName and returns
 * the timerID which can be used to stop this Timer.
 *
 * Example Usage:
 * @code
 *    NSString* timerID = [[MPulse sharedInstance] startTimer:@"CustomTimer"];
 * @endcode
 */
-(NSString *) startTimer:(NSString *)timerName;

/**
 * @name    Cancel Timer
 * @brief   Cancels Timer so that a timer beacon is not sent to the server.
 *
 * This API lets users cancel any previously started Timer specified by the timerID.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] cancelTimer:@"timerID"];
 * @endcode
 */
-(void) cancelTimer:(NSString *) timerID;

/**
 * @name    Stop Timer
 * @brief   Stops Timer and prepares the timer beacon to be sent to server.
 *
 * This API lets users stop a previously started Timer specified by the timerID.
 * This also prepares the timer beacon to be sent to the server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] stopTimer:@"timerID"];
 * @endcode
 */
-(void) stopTimer:(NSString *) timerID;

/**
 * @name    Send Timer
 * @brief   Sends the value of a Timer to server.
 *
 * This API lets users send the value of a Timer specified by the timerName.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] sendTimer:@"CustomTimer" value:200];
 * @endcode
 */

-(void) sendTimer:(NSString *)timerName value:(NSTimeInterval)value;

/**
 * @name    Send Metric
 * @brief   Sends the value of a Metric to server.
 *
 * This API lets users send the value of a Metric specified by the metricName.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] sendMetric:@"CustomMetric" value:23];
 * @endcode
 */
-(void) sendMetric:(NSString *)metricName value:(NSNumber *)value;

/**
 * @name    Set Dimension
 * @brief   Sets the value of a Dimension.
 *
 * This API lets users set the value of a Dimension specified by the dimensionName.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] setDimension:@"CustomDimension" value:@"100"];
 * @endcode
 */
-(void) setDimension:(NSString *)dimensionName value:(NSString *)value;

/**
 * @name    Reset Dimension
 * @brief   Resets the value of a Dimension.
 *
 * This API lets users reset the value of a Dimension specified by the dimensionName.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] resetDimension:@"CustomDimension"];
 * @endcode
 */
-(void) resetDimension:(NSString *)dimensionName;

/**
 * @name    Get A/B test
 * @brief   Returns the current value of A/B test.
 *
 * This API lets users retreive the value of currently set A/B test value.
 *
 * Example Usage:
 * @code
 *    NSString *abTest = [[MPulse sharedInstance] getABTest];
 * @endcode
 */
-(NSString *) getABTest;

/**
 * @name    Set A/B test
 * @brief   Sets the value of A/B test.
 *
 * This API lets users set the value of A/B test which will be a part of all future beacons sent to server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] setABTest:@"A"];
 * @endcode
 */
-(void) setABTest:(NSString *)abTest;

/**
 * @name    Reset A/B test
 * @brief   Resets the currently set A/B test value.
 *
 * This API lets users reset the current set A/B test value.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] resetABTest];
 * @endcode
 */
-(void) resetABTest;
@end
