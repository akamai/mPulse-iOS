//
//  MPTouchExtract.h
//  Boomerang
//
//  Created by Giri Senji on 6/5/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "TTElement.h"

@interface MPTouchExtract : NSObject

@property (readonly) NSString *accessor;
@property (readonly) TTLocator *locator;
@property (readwrite) TTElement *element;
@property (readonly) NSString *fixedValue;
@property (readonly) NSString *propertyName;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToExtract:(MPTouchExtract *)object;

@end
