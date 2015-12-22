//
//  MPBeacon.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

//
// Constants
//
typedef NS_ENUM(NSUInteger, MPBeaconTypeEnum) {
  PAGE_LOAD = 0,            // Web page load
  MANUAL = 1,               // JavaScript-triggered
  SPA = 2,                  // Single Page App Soft
  SPA_HARD = 3,             // Single Page App Hard
  XHR = 4,                  // XHR
  CLICK = 5,                // Click
  API = 6,                  // API (generic)
  API_NETWORK_REQUEST = 7,  // Network request
  API_CUSTOM_METRIC = 8,    // Custom Metric
  API_CUSTOM_TIMER = 9,     // Custom Timer
  APP_LAUNCH = 10,          // App launch
  APP_INACTIVE = 11,        // App inactive
  APP_CRASH = 12,           // App crash
  BATCH = 13,               // Batch
};

@interface MPBeacon : NSObject

//
// Methods
//

/**
 * Initializes the beacon
 */
-(id) init;

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType;

/**
 * Serializes the beacon for the Protobuf record
 * @param recordPtr Record
 */
-(void) serialize:(void *)recordPtr;

/**
 * Clears page dimensions such as A/B test, Page Group and Custom Dimensions
 */
-(void) clearPageDimensions;

//
// Properties
//
/*
 * Whether or not we were added to the collector yet
 */
@property BOOL addedToCollector;

//
// Properties on the Protobuf beacon
//
/**
 * The beacon's timestamp of creation
 */
@property (readonly) NSDate *timestamp;

/**
 * Page group
 */
@property NSString *pageGroup;

/**
 * A/B test
 */
@property NSString *abTest;

/**
 * An array of custom dimensions
 */
@property NSArray *customDimensions;

@end
