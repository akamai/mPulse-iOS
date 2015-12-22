//
//  MPBeaconCollector.h
//  Boomerang
//
//  Created by Tana Jackson on 4/9/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPBeaconCollector : NSObject

//
// Methods
//

/**
 * Singleton access
 */
+(MPBeaconCollector *) sharedInstance;

/**
 * Adds a beacon to the collector
 * @param beacon Beacon
 */
-(void) addBeacon:(MPBeacon *)beacon;

/**
 * Sends the batch of beacons
 */
-(void) sendBatch;

/**
 * Clears the batch of beacons
 */
-(void) clearBatch;

/**
 * Gets all of the collected beacons
 */
-(NSMutableArray *) getBeacons;

//
// Properties
//

/**
 * Disables Batch sending.
 * This flag is only used by Unit Tests
 */
@property (readwrite) BOOL disableBatchSending;

@end
