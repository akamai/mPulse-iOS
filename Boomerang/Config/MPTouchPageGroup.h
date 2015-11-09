//
//  MPTouchPageGroup.h
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "TTLocatorCollection.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"
#import "MPTouchExtract.h"

@interface MPTouchPageGroup : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readonly) MPTouchAction *action;
@property (readonly) MPTouchCondition *condition;
@property (readonly) MPTouchExtract *extract;
@property (readwrite) NSString *pageGroupValue;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToPageGroup:(MPTouchPageGroup *)object;
- (NSArray*) getAllLocators;
- (void) updateElements:(TTLocatorCollection*) locatorCollection;

@end
