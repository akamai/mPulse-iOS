//
//  MPConfigMetric.h
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPConfigMetric : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readonly) NSString *dataType;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToMetric:(MPConfigMetric *)object;

@end
