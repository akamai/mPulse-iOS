//
//  MPTouchConfig.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPTouchPageGroup.h"
#import "MPTouchMetric.h"
#import "MPTouchTimer.h"
#import "MPTouchDimension.h"
#import "TTLocatorCollection.h"

@interface MPTouchConfig : NSObject

@property (readwrite) NSArray *pageGroups;
@property (readwrite) NSArray *metrics;
@property (readwrite) NSArray *timers;
@property (readwrite) NSArray *dimensions;

-(id) initWithJson:(NSDictionary *)jsonData;
-(void) deepCopy:(MPTouchConfig *)config;

// Iterates through all the locators present in PageGroups, Metrics and Timers and insert
// them into TTLocatorCollection. This TTLocatorCollection instance is returned.
-(TTLocatorCollection*) getAllLocators;

// Iterates through all the locators present in PageGroups, Metrics and Timers and updates the corresponding element
// if found in the provided TTLocatorCollection object. If a matching element is not found, existing element is cleared.
- (void) updateStoredElements:(TTLocatorCollection*) locatorCollection;

@end
