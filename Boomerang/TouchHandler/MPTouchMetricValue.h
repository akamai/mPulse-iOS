//
//  MPTouchMetricValue.h
//  Boomerang
//
//  Created by Giri Senji on 5/5/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPTouchMetricValue : NSObject
{
  NSString *name;
  NSInteger index;
  NSNumber *value;
  NSString *pageGroup;
}

@property NSString *name;
@property NSInteger index;
@property NSNumber *value;
@property NSString *pageGroup;

- (id) initWithName:(NSString *)aName index:(NSInteger)anIndex value:(NSNumber *)aValue;
- (id) initWithName:(NSString *)aName index:(NSInteger)anIndex value:(NSNumber *)aValue pageGroup:(NSString *)aPageGroup;

@end
