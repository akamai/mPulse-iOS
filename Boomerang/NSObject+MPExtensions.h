//
//  NSObject+MPExtensions.h
//  Boomerang
//
//  Created by Giri Senji on 4/28/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (MPExtensions)

- (void)mp_safePerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg;

@end

@interface NSObject (MPLogging)

-(NSString *) mp_autoDescribe:(id)instance classType:(Class)classType;
-(BOOL)mp_hasPropertyNamed:(NSString *)propName;
-(NSArray *) mp_getPropertyArray;
-(NSArray *) mp_getPropertyArray:(NSArray *)includeList;

@end
