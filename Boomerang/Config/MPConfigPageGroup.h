//
//  MPConfigPageGroup.h
//  Boomerang
//
//  Created by Giri Senji on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPConfigPageGroup : NSObject

@property (readonly) NSString *name;
@property (readonly) NSInteger index;
@property (readonly) NSString *type;
@property (readonly) NSString *label;
@property (readwrite) NSString *pageGroupValue;

- (id) initWithDictionary:(NSMutableDictionary *)dict;
- (BOOL) isEqualToPageGroup:(MPConfigPageGroup *)object;

@end
