//
//  MPNetworkCallBeacon.h
//  Boomerang
//
//  Created by Tana Jackson on 4/8/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPNetworkCallBeacon : MPBeacon

@property int sessionToken;

+(id) initWithURL:(NSURL*)url;

-(void) endRequestWithBytes:(NSUInteger)bytes;
-(void) setNetworkError:(NSInteger)error :(NSString *)errorMessage;

@end
