//
//  MPShutdownEvent.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPShutdownEvent.h"

static MPShutdownEvent *sharedShutdownStatus = nil;

@implementation MPShutdownEvent

@synthesize isSystemShuttingDown;

#pragma mark Singleton Methods
+ (id)sharedManager {
  @synchronized(self) {
    if (sharedShutdownStatus == nil)
      sharedShutdownStatus = [[self alloc] init];
  }
  return sharedShutdownStatus;
}

- (id)init {
  if (self = [super init]) {
    isSystemShuttingDown = NO;
  }
  return self;
}

- (void) setSystemShutdownStatus: (BOOL) isShuttingDown {
  
  if (isShuttingDown)
  {
    [self performSelector:@selector(doSetSystemShutdownStatus:)
               withObject:@"true"];
  }
  else
  {
    [self doSetSystemShutdownStatus:@"false"];
  }
  
}

- (void) doSetSystemShutdownStatus:(NSString *) isShuttingDown {
  @synchronized(self) {
    if ([isShuttingDown isEqualToString:@"true"])
    {
      isSystemShuttingDown = YES;
    }
    else
    {
      isSystemShuttingDown = NO;
    }
  }
}

@end
