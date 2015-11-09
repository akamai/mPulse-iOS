//
//  MPShutdownEvent.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPShutdownEvent : NSObject {
  BOOL isSystemShuttingDown;
}

@property (nonatomic, readwrite) BOOL isSystemShuttingDown;

+ (id)sharedManager;
- (void) setSystemShutdownStatus:(BOOL) isShuttingDown;
- (void) doSetSystemShutdownStatus:(NSString *) isShuttingDown;

@end
