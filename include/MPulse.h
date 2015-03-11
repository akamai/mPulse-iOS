//
//  MPulse.h
//  MPulse
//
//  Copyright (c) 2012-2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPulse : NSObject

extern NSString* const BOOMERANG_VERSION;

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
 * @name    ViewGroup
 * @brief   Property used to get or set the value of ViewGroup.
 *
 * This API lets users get or set the value of ViewGroup which is sent with every beacon to the server.
 *
 * Example Usage:
 * @code
 *    NSString* viewGroup = [[MPulse sharedInstance] viewGroup];
 *    [[MPulse sharedInstance] setViewGroup:@"testViewGroup"];
 * @endcode
 */
@property(readwrite) NSString* viewGroup;

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
 * @brief   Starts Custom Timer and returns the Timer ID.
 *
 * This API lets users start a Custom Timer specified by timerName and returns
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
 * @brief   Cancels Custom Timer so that a timer beacon is not sent to the server.
 *
 * This API lets users cancel any previously started Custom Timer specified by the timerID.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] cancelTimer:@"timerID"];
 * @endcode
 */
-(void) cancelTimer:(NSString *) timerID;

/**
 * @name    Stop Timer
 * @brief   Stops Custom Timer and prepares the timer beacon to be sent to server.
 *
 * This API lets users stop a previously started Custom Timer specified by the timerID.
 * This also prepares the timer beacon to be sent to the server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] stopTimer:@"timerID"];
 * @endcode
 */
-(void) stopTimer:(NSString *) timerID;

/**
 * @name    Set Metric
 * @brief   Sets the value of a Custom Metric and prepares the metric beacon to be sent to server.
 *
 * This API lets users set the value of a Custom Metric specified by the metricName.
 * This also prepares the metric beacon to be sent to the server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] setMetric:@"CustomMetric" value:23];
 * @endcode
 */
-(void) setMetric:(NSString *)metricName value:(NSNumber *)value;

/**
 * @name    Set Dimension
 * @brief   Sets the value of a Custom Dimension and prepares the dimension beacon to be sent to server.
 *
 * This API lets users set the value of a Custom Dimension specified by the dimensionName.
 * This also prepares the dimension beacon to be sent to the server.
 *
 * Example Usage:
 * @code
 *    [[MPulse sharedInstance] setDimension:@"CustomDimension" value:@"100"];
 * @endcode
 */
-(void) setDimension:(NSString *)dimensionName value:(NSString *)value;

@end
