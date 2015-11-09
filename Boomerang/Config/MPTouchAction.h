//
//  MPTouchAction.h
//  Boomerang
//
//  Created by Giri Senji on 5/27/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLocator.h"
#import "TTElement.h"

@interface MPTouchAction : NSObject

@property (readonly) NSString *name;
@property (readonly) TTLocator *locator;
@property (readwrite) TTElement *element;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToAction:(MPTouchAction *)object;

@end
