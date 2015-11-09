//
//  MPTouchHandlerThread.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "MPConfig.h"

@interface MPTouchHandlerThread : NSObject

+(MPTouchHandlerThread*) sharedInstance;

@property (readonly) MPTouchConfig *touchConfig;
@property (readonly, atomic) BOOL *hasConfigChanged;

@end
