//
//  MPBeaconURLProcessor.h
//  Boomerang
//
//  Created by Matthew Solnit on 5/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPBeaconURLProcessor : NSObject

+(NSString*) extractURL:(MPBeacon*) beacon urlPatterns:(NSArray*)urlPatterns;

+(NSString*) extractURLPath:(NSURL*)url urlPatterns:(NSArray*)urlPatterns;

@end
