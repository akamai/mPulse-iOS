//
//  MPTouchTimer.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "TTLocatorCollection.h"
#import "MPTimerBeacon.h"
#import "MPTouchAction.h"
#import "MPTouchCondition.h"

@interface MPTouchTimer : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readonly) MPTouchAction *startAction;
@property (readonly) MPTouchCondition *startCondition;
@property (readonly) MPTouchAction *endAction;
@property (readonly) MPTouchCondition *endCondition;
@property (readonly) NSString *pageGroup;
@property (readwrite) MPTimerBeacon *beacon;

-(id) initWithDictionary:(NSMutableDictionary *)dict;
-(BOOL) isEqualToTimer:(MPTouchTimer *)object;
-(BOOL) isStartAction;
-(BOOL) isStartCondition;
-(BOOL) isEndAction;
-(BOOL) isEndCondition;
-(NSArray*) getAllLocators;
-(void) updateElements:(TTLocatorCollection*) locatorCollection;

@end
