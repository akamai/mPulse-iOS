//
//  MPConfigPageParams.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPConfigPageGroup.h"
#import "MPConfigMetric.h"
#import "MPConfigTimer.h"
#import "MPConfigDimension.h"

@interface MPConfigPageParams : NSObject

@property (readwrite) NSArray *pageGroups;
@property (readwrite) NSArray *metrics;
@property (readwrite) NSArray *timers;
@property (readwrite) NSArray *dimensions;

-(id) initWithJson:(NSDictionary *)jsonData;
-(void) deepCopy:(MPConfigPageParams *)config;

@end
