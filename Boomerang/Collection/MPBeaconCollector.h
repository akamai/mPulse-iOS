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

// Singleton access
+(MPBeaconCollector*) sharedInstance;
@property (readonly) NSMutableDictionary* records;
//This flag is only used by Unit Tests
@property (readwrite) BOOL disableBatchSending;

-(void) addBeacon:(MPBeacon*)beacon;
-(void) sendBatch;
-(void) clearBatch;

@end
