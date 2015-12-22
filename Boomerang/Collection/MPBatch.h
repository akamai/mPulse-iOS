//
//  MPBatch.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPBatch : NSObject

/**
 * Initializes the batch with the specified beacons
 * @param beacons Beacons
 */
+(id) initWithBeacons:(NSArray *)beacons;

/**
 * Serialize the batch to Protobuf
 */
-(NSData *) serialize;

@end
