//
//  MPTouchDimension.h
//  Boomerang_NoTTD
//
//  Created by Giri Senji on 3/2/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"
#import "MPTouchExtract.h"

@interface MPTouchDimension : NSObject

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
- (BOOL) isEqualToDimension:(MPTouchDimension *)object;
- (NSArray*) getAllLocators;
- (void) updateElements:(TTLocatorCollection*) locatorCollection;

@end
