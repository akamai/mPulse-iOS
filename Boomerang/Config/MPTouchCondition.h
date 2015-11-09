//
//  MPTouchCondition.h
//  Boomerang
//
//  Created by Giri Senji on 5/27/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "TTElement.h"

@interface MPTouchCondition : NSObject

@property (readonly) NSString *accessor;
@property (readonly) TTLocator *locator;
@property (readonly) NSString *propertyName;
@property (readonly) NSString *value;
@property (readwrite) TTElement *element;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToCondition:(MPTouchCondition *)object;

@end
