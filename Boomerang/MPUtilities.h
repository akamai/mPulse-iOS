//
//  MPUtilities.h
//  Boomerang
//
//  Created by Giri Senji on 3/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPUtilities : NSObject

extern NSString* const BOOMERANG_INSTALL_BEACON_SENT;
extern NSString* const BOOMERANG_DATA_PLIST;

+(BOOL)class:(Class)klass containsDeclaredClassMethod:(SEL)methodSelector;
+(BOOL)class:(Class)klass containsDeclaredMethod:(SEL)methodSelector;
+(BOOL)class:(Class)klass containsDeclaredMethod:(SEL)methodSelector checkSuperclasses:(BOOL)checkSuperclasses;
+(BOOL)class:(Class)klass isConformsToProtocol:(Protocol*)protocol;
+(NSString *) getBoomerangDataFile;
+(void) base36:(int)value andInjectInto:(NSMutableString *) resultString;

// Returns a UUID
+(NSString *) getUUID;

@end
