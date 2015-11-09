//
//  MPTouchMetric.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"
#import "MPTouchExtract.h"

@interface MPTouchMetric : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readonly) NSString *dataType;
@property (readonly) MPTouchAction *action;
@property (readonly) MPTouchCondition *condition;
@property (readonly) MPTouchExtract *extract;
@property (readonly) NSString *pageGroup;
@property (readwrite) BOOL beaconSent;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToMetric:(MPTouchMetric *)object;
- (NSArray*) getAllLocators;
- (void) updateElements:(TTLocatorCollection*) locatorCollection;

@end
