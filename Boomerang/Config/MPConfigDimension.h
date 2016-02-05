//
//  MPConfigDimension.h
//  Boomerang
//
//  Created by Giri Senji on 3/2/15.
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPConfigDimension : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readonly) NSString *dataType;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToDimension:(MPConfigDimension *)object;

@end
